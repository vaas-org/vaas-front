import { Elm } from "./src/Main.elm";
import { connect, disconnect, send } from "./websocket";

const app = Elm.Main.init({
    node: document.getElementById("app"),
    flags: {},
});

app.ports.sendVote.subscribe((vote: PublicVote | AnonVote) => {
    console.log("sendVote from elm: ", vote)
    sendVoteToElm({ ...vote, id: "whoami" })
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

interface Alternative {
    id: string;
    title: string;
}

interface AnonVote {
    id: string;
}
interface PublicVote {
    id: string;
    alternativeId: string;
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

function sendIssueToElm(issue: Issue) {
    app.ports.receiveIssue.send(issue);
}

function sendVoteToElm(vote: PublicVote | AnonVote) {
    app.ports.receiveVote.send(vote);
}

function connectToWebsocket() {
    connect((data: { data: string }) => {
        console.log("recvd", data)

        // Try to parse the data as JSON
        const message = JSON.parse(data.data)
        sendIssueToElm(message);
    })
}

let sendVoteCounter = 0;
const sendVoteInterval = setInterval(() => {
    const v = {
        id: btoa(`${Math.random() * 10000}`),
        alternativeId: `${Math.max(1, Math.round((Math.random() * 10) / 3))}`,
    };
    console.log("Sending vote", v);
    sendVoteToElm(v);

    sendVoteCounter++;
    if (sendVoteCounter >= 9) {
        clearInterval(sendVoteInterval);
    }
}, 3000);
