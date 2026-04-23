defmodule ZanshinApi.TestSupport.Cabbage.Feature do
  @moduledoc false
  import Cabbage.Feature.Helpers

  alias Cabbage.Feature.{Loader, MissingStepError}

  @feature_options [:file, :template]
  defmacro __using__(options) do
    has_assigned_feature = !match?(nil, options[:file])

    Module.register_attribute(__CALLER__.module, :steps, accumulate: true)
    Module.register_attribute(__CALLER__.module, :tags, accumulate: true)

    quote do
      unquote(prepare_executable_feature(has_assigned_feature, options))

      @before_compile {unquote(__MODULE__), :expose_metadata}
      import unquote(__MODULE__)
      require Logger

      unquote(load_features(has_assigned_feature, options))
    end
  end

  defp prepare_executable_feature(false, _options), do: nil

  defp prepare_executable_feature(true, options) do
    {_options, template_options} = Keyword.split(options, @feature_options)

    quote do
      @before_compile unquote(__MODULE__)
      use unquote(options[:template] || ExUnit.Case), unquote(template_options)
    end
  end

  defp load_features(false, _options), do: nil

  defp load_features(true, options) do
    quote do
      @feature Loader.load_from_file(unquote(options[:file]))
      @scenarios @feature.scenarios
    end
  end

  defmacro expose_metadata(env) do
    steps = Module.get_attribute(env.module, :steps) || []
    tags = Module.get_attribute(env.module, :tags) || []

    quote generated: true do
      def raw_steps() do
        unquote(Macro.escape(steps))
      end

      def raw_tags() do
        unquote(Macro.escape(tags))
      end
    end
  end

  defmacro __before_compile__(env) do
    scenarios = Module.get_attribute(env.module, :scenarios) || []
    steps = Module.get_attribute(env.module, :steps) || []
    tags = Module.get_attribute(env.module, :tags) || []

    scenarios
    |> Enum.map(fn scenario ->
      scenario =
        Map.put(
          scenario,
          :tags,
          Cabbage.global_tags() ++
            List.wrap(Module.get_attribute(env.module, :moduletag)) ++ scenario.tags
        )

      quote bind_quoted: [
              scenario: Macro.escape(scenario),
              tags: Macro.escape(tags),
              steps: Macro.escape(steps)
            ],
            line: scenario.line do
        describe scenario.name do
          setup context do
            for tag <- unquote(scenario.tags) do
              case tag do
                {tag, _value} ->
                  Cabbage.Feature.Helpers.run_tag(
                    unquote(Macro.escape(tags)),
                    tag,
                    __MODULE__,
                    unquote(scenario.name)
                  )

                tag ->
                  Cabbage.Feature.Helpers.run_tag(
                    unquote(Macro.escape(tags)),
                    tag,
                    __MODULE__,
                    unquote(scenario.name)
                  )
              end
            end

            {:ok,
             Map.merge(
               Cabbage.Feature.Helpers.fetch_state(unquote(scenario.name), __MODULE__),
               context || %{}
             )}
          end

          tags = Cabbage.Feature.Helpers.map_tags(scenario.tags) || []

          name =
            ExUnit.Case.register_test(
              __MODULE__,
              __ENV__.file,
              scenario.line,
              :scenario,
              scenario.name,
              tags
            )

          def unquote(name)(exunit_state) do
            Cabbage.Feature.Helpers.start_state(unquote(scenario.name), __MODULE__, exunit_state)

            unquote(Enum.map(scenario.steps, &compile_step(&1, steps, scenario.name)))
          end
        end
      end
    end)
  end

  def compile_step(step, steps, scenario_name) when is_list(steps) do
    step_type = step.keyword

    step
    |> find_implementation_of_step(steps)
    |> compile(step, step_type, scenario_name)
  end

  defp compile(
         {:{}, _, [regex, vars, state_pattern, block, metadata]},
         step,
         step_type,
         scenario_name
       ) do
    {regex, _} = Code.eval_quoted(regex)

    named_vars =
      extract_named_vars(regex, step.text)
      |> Map.merge(%{table: step.table_data, doc_string: step.doc_string})

    quote generated: true do
      with {_type, unquote(vars)} <- {:variables, unquote(Macro.escape(named_vars))},
           {_type, state = unquote(state_pattern)} <-
             {:state, Cabbage.Feature.Helpers.fetch_state(unquote(scenario_name), __MODULE__)} do
        new_state =
          case unquote(block) do
            {:ok, new_state} -> Map.merge(state, new_state)
            _ -> state
          end

        Cabbage.Feature.Helpers.update_state(unquote(scenario_name), __MODULE__, fn _ ->
          new_state
        end)

        Logger.info([
          "\t\t",
          IO.ANSI.cyan(),
          unquote(step_type),
          " ",
          IO.ANSI.green(),
          unquote(step.text)
        ])
      else
        {type, state} ->
          metadata = unquote(Macro.escape(metadata))

          reraise """
                  ** (MatchError) Failure to match #{type} of #{inspect(Cabbage.Feature.Helpers.remove_hidden_state(state))}
                  Pattern: #{unquote(Macro.to_string(state_pattern))}
                  """,
                  Cabbage.Feature.Helpers.stacktrace(__MODULE__, metadata)
      end
    end
  end

  defp compile(_, step, step_type, _scenario_name) do
    extra_vars = %{table: step.table_data, doc_string: step.doc_string}

    raise MissingStepError, step_text: step.text, step_type: step_type, extra_vars: extra_vars
  end

  defp find_implementation_of_step(step, steps) do
    Enum.find(steps, fn {:{}, _, [r, _, _, _, _]} ->
      step.text =~ r |> Code.eval_quoted() |> elem(0)
    end)
  end

  defp extract_named_vars(regex, step_text) do
    regex
    |> Regex.named_captures(step_text)
    |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    |> Enum.into(%{})
  end

  defmacro import_feature(module) do
    quote do
      import_steps(unquote(module))
      import_tags(unquote(module))
    end
  end

  defmacro import_steps(module) do
    quote do
      if Code.ensure_compiled(unquote(module)) do
        for step <- unquote(module).raw_steps() do
          Module.put_attribute(__MODULE__, :steps, step)
        end
      end
    end
  end

  defmacro import_tags(module) do
    quote do
      if Code.ensure_compiled(unquote(module)) do
        for {name, block} <- unquote(module).raw_tags() do
          Cabbage.Feature.Helpers.add_tag(__MODULE__, name, block)
        end
      end
    end
  end

  defmacro defgiven(regex, vars, state, do: block) do
    add_step(__CALLER__.module, regex, vars, state, block, metadata(__CALLER__, :defgiven))
  end

  defmacro defwhen(regex, vars, state, do: block) do
    add_step(__CALLER__.module, regex, vars, state, block, metadata(__CALLER__, :defwhen))
  end

  defmacro defthen(regex, vars, state, do: block) do
    add_step(__CALLER__.module, regex, vars, state, block, metadata(__CALLER__, :defthen))
  end

  defmacro tag(tag, do: block) do
    add_tag(__CALLER__.module, Macro.to_string(tag) |> String.replace(~r/\s*/, ""), block)
  end
end
