import { Elm } from "./src/Main.elm";
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
    console.info("WS connect request")
    app.ports.receiveWebsocketStatus.send("connecting");
    setTimeout(() => {
        console.log("simulating some connection delay")
        connectToWebsocket();
        app.ports.receiveWebsocketStatus.send("connected");
    }, 1000);
});

app.ports.sendWebsocketDisconnect.subscribe(() => {
    console.info("WS disconnect request")
    app.ports.receiveWebsocketStatus.send("disconnecting");
    disconnect();
    app.ports.receiveWebsocketStatus.send("disconnected");
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

function connectToWebsocket() {
    connect((data: { data: string }) => {
        console.log("recvd", data)

        // Try to parse the data as JSON
        const message = JSON.parse(data.data)
        sendMessageToElm(message);
    })

    let sendVoteCounter = 0;
    const sendVoteInterval = setInterval(() => {
        const v = {
            user_id: btoa(`${Math.random() * 10000}`),
            alternative_id: `${Math.max(1, Math.round((Math.random() * 10) / 3))}`,
            type: "vote"
        };
        console.log("Sending vote", v);
        send(v);

        sendVoteCounter++;
        if (sendVoteCounter >= 9) {
            clearInterval(sendVoteInterval);
        }
    }, 3000);
}

