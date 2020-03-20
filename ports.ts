import { Elm } from "./src/Main.elm";

const app = Elm.Main.init({
    node: document.getElementById("app"),
    flags: {},
});

app.ports.sendVote.subscribe((vote: PublicVote | AnonVote) => {
    console.log("sendVote from elm: ", vote)
    sendVoteToElm({ ...vote, id: "whoami" })
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

setTimeout(() => {
    const i = {
        id: "0fc3a2d",
        title: "Some title",
        description: "Fancy, long description with a lot of information but maybe not too much.",
        // wtf typescript are you drunk
        state: "notstarted" as "notstarted" | "inprogress" | "finished",
        alternatives: [
            { id: "1", title: "Alternative One" },
            { id: "2", title: "Alternative Two" },
            { id: "3", title: "Alternative Three" },
        ],
        votes: [
        ],
        maxVoters: 10,
        showDistribution: true,
    };
    console.log("Sending issue");
    sendIssueToElm(i);
}, 500)

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
