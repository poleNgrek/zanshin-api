import { get_api_base_url } from "@zanshin/utils";

export type AdminRealtimeEvent = {
  event: string;
  payload: Record<string, unknown>;
};

type AdminRealtimeOptions = {
  on_event: (event: AdminRealtimeEvent) => void;
  on_error?: (error: string) => void;
};

const PHX_VSN = "2.0.0";
const HEARTBEAT_MS = 30_000;

export function connect_admin_realtime(options: AdminRealtimeOptions): () => void {
  const baseUrl = get_api_base_url();
  const websocketUrl = to_websocket_url(baseUrl);
  const socket = new WebSocket(websocketUrl);

  let ref = 1;
  let heartbeatTimer: number | undefined;

  function next_ref(): string {
    const value = String(ref);
    ref += 1;
    return value;
  }

  function send(topic: string, event: string, payload: Record<string, unknown>, joinRef: string | null = null) {
    socket.send(JSON.stringify([joinRef, next_ref(), topic, event, payload]));
  }

  socket.addEventListener("open", () => {
    send("admin:all", "phx_join", {});

    heartbeatTimer = window.setInterval(() => {
      if (socket.readyState === WebSocket.OPEN) {
        send("phoenix", "heartbeat", {}, null);
      }
    }, HEARTBEAT_MS);
  });

  socket.addEventListener("message", (raw) => {
    try {
      const parsed = JSON.parse(String(raw.data));
      if (!Array.isArray(parsed) || parsed.length < 5) {
        return;
      }

      const topic = parsed[2];
      const event = parsed[3];
      const payload = parsed[4];

      if (topic !== "admin:all") {
        return;
      }

      if (typeof event !== "string" || event.startsWith("phx_")) {
        return;
      }

      if (!is_record(payload)) {
        return;
      }

      options.on_event({ event, payload });
    } catch {
      options.on_error?.("admin_realtime_message_parse_error");
    }
  });

  socket.addEventListener("error", () => {
    options.on_error?.("admin_realtime_connection_error");
  });

  socket.addEventListener("close", () => {
    options.on_error?.("admin_realtime_connection_closed");
  });

  return () => {
    if (heartbeatTimer) {
      window.clearInterval(heartbeatTimer);
    }

    socket.close();
  };
}

function to_websocket_url(apiBaseUrl: string): string {
  const base = new URL(apiBaseUrl);
  const protocol = base.protocol === "https:" ? "wss:" : "ws:";
  return `${protocol}//${base.host}/socket/websocket?vsn=${PHX_VSN}`;
}

function is_record(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}
