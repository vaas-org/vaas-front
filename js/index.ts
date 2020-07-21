import { Elm } from "../src/Main.elm";
import { connect, disconnect, send } from "./websocket";

const app = Elm.Main.init({
  flags: {
    sessionId: sessionStorage.getItem("sessionid"),
  },
});

app.ports.sendVote.subscribe((vote: PublicVote | AnonVote) => {
  console.log("sendVote from elm: ", vote);
  send({ ...vote, type: "vote" });
});

app.ports.sendLogin.subscribe((login: Login) => {
  console.log("sendLogin from elm: ", login);
  send({ ...login, type: "login" });
});

app.ports.sendWebsocketConnect.subscribe(() => {
  app.ports.receiveWebsocketStatus.send("connecting");
  connectToWebsocket(
    () => app.ports.receiveWebsocketStatus.send("connected"),
    () => app.ports.receiveWebsocketStatus.send("disconnected")
  );
});

app.ports.sendWebsocketDisconnect.subscribe(() => {
  app.ports.receiveWebsocketStatus.send("disconnecting");
  disconnect(() => app.ports.receiveWebsocketStatus.send("disconnected"));
});

app.ports.sendEvent.subscribe((obj: Object) => send(obj));

app.ports.storeSessionId.subscribe((sessionId: string) =>
  sessionStorage.setItem("sessionid", sessionId)
);

app.ports.removeSessionId.subscribe(() =>
  sessionStorage.removeItem("sessionid")
);

interface Login {
  userId: string;
  username: string;
}

interface Alternative {
  id: string;
  title: string;
}

interface AnonVote {
  id: string;
  user_id: string; // yolo hack
}
interface PublicVote {
  id: string;
  alternativeId: string;
  user_id: string; // yolo hack
}

interface Issue {
  id: string;
  title: string;
  description: string;
  state: "notstarted" | "inprogress" | "finished";
  alternatives: Alternative[];
  votes: (AnonVote | PublicVote)[];
  maxVoters: number;
  showDistribution: boolean;
}

function sendMessageToElm(issue: unknown) {
  app.ports.receiveWebSocketMessage.send(issue);
}

// MEGA HACK
let issue: Issue | null;

function connectToWebsocket(onConnect: () => void, onDisconnect: () => void) {
  connect(
    (data: { data: string }) => {
      // Try to parse the data as JSON
      const message = JSON.parse(data.data);
      console.group(`received message of type '${message.type}'`);
      console.log("raw data", data);
      console.table(message);
      console.groupEnd();
      if (message.type === 'issue') {
        // BEGIN MEGA HACK
        issue = message;
        startDummyVotes();
        // END MEGA HACK
      }
      sendMessageToElm(message);
    },
    () => {
      onConnect();
    },
    onDisconnect
  );
}

function startDummyVotes() {
  let sendVoteCounter = 0;
  const sendVoteInterval = setInterval(() => {
    const alternative_index = Math.floor((Math.random() * issue.alternatives.length));
    const alternative = issue.alternatives[alternative_index];
    console.log('hack', alternative_index, alternative);
    const v = {
      user_id: uuidv4(),
      alternative_id: alternative.id,
      type: "vote",
    };
    console.debug("Sending vote", v);
    send(v);

    sendVoteCounter++;
    if (sendVoteCounter >= 9) {
      clearInterval(sendVoteInterval);
    }
  }, 3000);
}
function uuidv4() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}
