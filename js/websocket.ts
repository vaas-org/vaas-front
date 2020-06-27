const websocketServer = "http://localhost:8080";

function log(msg: string) {
  console.info("WS: " + msg);
}

let conn: WebSocket | null = null;
export function connect(
  onMessage: (this: WebSocket, ev: MessageEvent) => void,
  onConnect: () => void,
  onDisconnect: () => void
) {
  // Clean up existing connection if any
  if (conn !== null) {
    conn.onclose = null;
    conn.close();
    conn = null;
  }
  var wsUri =
    ((websocketServer.substr(0, 6) == "https:" && "wss://") || "ws://") +
    websocketServer.split("://")[1] +
    "/ws/";

  console.log("URI", wsUri);

  conn = new WebSocket(wsUri);

  log("Connecting...");
  conn.onopen = function () {
    log("Connected.");
    onConnect();
  };

  conn.onmessage = onMessage;
  conn.onclose = function () {
    log("Disconnected.");
    conn = null;
    onDisconnect();
  };
}
export function disconnect(onClosed: () => void) {
  if (conn != null) {
    log("Disconnecting...");
    conn.onclose = null;
    conn.close();
    conn = null;
    onClosed();
  }
}

export function send(obj: unknown) {
  conn.send(JSON.stringify(obj));
}

// Stop onClose actions from being called during a close
window.onbeforeunload = () => {
  conn.onclose = null;
  conn.close();
};
