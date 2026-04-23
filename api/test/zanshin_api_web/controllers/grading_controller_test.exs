defmodule ZanshinApiWeb.GradingControllerTest do
  use ZanshinApiWeb.ConnCase, async: true

  import ZanshinApi.AuthHelpers
  import ZanshinApi.CompetitionsFixtures

  test "grading API supports session, panel, result, vote, and note flow", %{conn: conn} do
    tournament = tournament_fixture()
    competitor = competitor_fixture()

    conn =
      conn
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> post("/api/v1/gradings/sessions", %{
        "tournament_id" => tournament.id,
        "name" => "Autumn Shinsa",
        "written_required" => false
      })

    assert %{"data" => %{"id" => session_id}} = json_response(conn, 201)

    conn =
      build_conn()
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> post("/api/v1/gradings/examiners", %{
        "display_name" => "Examiner A",
        "grade" => "7dan",
        "title" => "kyoshi"
      })

    assert %{"data" => %{"id" => examiner_id}} = json_response(conn, 201)

    conn =
      build_conn()
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> post("/api/v1/gradings/sessions/#{session_id}/panel_assignments", %{
        "examiner_id" => examiner_id,
        "role" => "head"
      })

    assert %{"data" => %{"role" => "head"}} = json_response(conn, 201)

    conn =
      build_conn()
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> post("/api/v1/gradings/sessions/#{session_id}/results", %{
        "competitor_id" => competitor.id,
        "target_grade" => "5dan",
        "declared_stance" => "chudan",
        "jitsugi_result" => "pass",
        "kata_result" => "pass"
      })

    assert %{"data" => %{"id" => result_id, "final_result" => "pass"}} = json_response(conn, 201)

    conn =
      build_conn()
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> post("/api/v1/gradings/results/#{result_id}/votes", %{
        "examiner_id" => examiner_id,
        "part" => "jitsugi",
        "decision" => "pass",
        "note" => "Solid pressure and seme."
      })

    assert %{"data" => %{"decision" => "pass"}} = json_response(conn, 201)

    conn =
      build_conn()
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> post("/api/v1/gradings/results/#{result_id}/notes", %{
        "examiner_id" => examiner_id,
        "part" => "kata",
        "note" => "Maai and metsuke were consistent."
      })

    assert %{"data" => %{"part" => "kata"}} = json_response(conn, 201)

    conn =
      build_conn()
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> post("/api/v1/gradings/results/#{result_id}/compute", %{})

    assert %{"data" => %{"final_result" => "pass"}} = json_response(conn, 200)

    conn =
      build_conn()
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> post("/api/v1/gradings/results/#{result_id}/finalize", %{})

    assert %{"data" => %{"locked_at" => locked_at}} = json_response(conn, 200)
    assert is_binary(locked_at)

    conn =
      build_conn()
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> post("/api/v1/gradings/results/#{result_id}/notes", %{
        "examiner_id" => examiner_id,
        "part" => "kata",
        "note" => "Late note should fail due lock."
      })

    assert %{"error" => "grading_result_locked"} = json_response(conn, 422)
  end

  test "grading vote rejects examiner not assigned to result session", %{conn: conn} do
    tournament = tournament_fixture()
    competitor = competitor_fixture()

    conn =
      conn
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> post("/api/v1/gradings/sessions", %{
        "tournament_id" => tournament.id,
        "name" => "Session One"
      })

    assert %{"data" => %{"id" => session_id}} = json_response(conn, 201)

    conn =
      build_conn()
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> post("/api/v1/gradings/sessions", %{
        "tournament_id" => tournament.id,
        "name" => "Session Two"
      })

    assert %{"data" => %{"id" => other_session_id}} = json_response(conn, 201)

    conn =
      build_conn()
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> post("/api/v1/gradings/examiners", %{
        "display_name" => "Detached Examiner",
        "grade" => "6dan"
      })

    assert %{"data" => %{"id" => examiner_id}} = json_response(conn, 201)

    _assignment_conn =
      build_conn()
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> post("/api/v1/gradings/sessions/#{other_session_id}/panel_assignments", %{
        "examiner_id" => examiner_id,
        "role" => "member"
      })

    conn =
      build_conn()
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> post("/api/v1/gradings/sessions/#{session_id}/results", %{
        "competitor_id" => competitor.id,
        "target_grade" => "4dan"
      })

    assert %{"data" => %{"id" => result_id}} = json_response(conn, 201)

    conn =
      build_conn()
      |> put_req_header("authorization", bearer_token_for("admin"))
      |> post("/api/v1/gradings/results/#{result_id}/votes", %{
        "examiner_id" => examiner_id,
        "part" => "jitsugi",
        "decision" => "pass"
      })

    assert %{"error" => "examiner_not_assigned_to_session"} = json_response(conn, 422)
  end
end
