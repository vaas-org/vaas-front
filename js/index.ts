import { Elm } from "../src/Main.elm";
import { connect, disconnect, send } from "./websocket";

const app = Elm.Main.init({
    node: document.getElementById("app"),
    flags: {},
});

app.ports.sendVote.subscribe((vote: PublicVote | AnonVote) => {
    console.log("sendVote from elm: ", vote)
    send({ ...vote, user_id: vote.user_id, type: "vote" });
});

app.ports.sendLogin.subscribe((login: Login) => {
    console.log("sendLogin from elm: ", login)
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
    disconnect();
});

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
};

function sendMessageToElm(issue: unknown) {
    app.ports.receiveWebSocketMessage.send(issue);
}

function connectToWebsocket(onConnect: () => void, onDisconnect: () => void) {
  connect(
    (data: { data: string }) => {
      // Try to parse the data as JSON
      const message = JSON.parse(data.data);
      console.group(`received message of type '${message.type}'`);
      console.log("raw data", data);
      console.table(message);
      console.groupEnd();
      sendMessageToElm(message);
    },
    () => {
      onConnect();
      startDummyVotes();
    },
    onDisconnect
  );
}

function startDummyVotes() {
    let sendVoteCounter = 0;
    const sendVoteInterval = setInterval(() => {
        const v = {
            user_id: btoa(`${Math.random() * 10000}`),
            alternative_id: `${Math.max(1, Math.round((Math.random() * 10) / 3))}`,
            type: "vote"
        };
        console.debug("Sending vote", v);
        send(v);

        sendVoteCounter++;
        if (sendVoteCounter >= 9) {
            clearInterval(sendVoteInterval);
        }
    }, 3000);
}
