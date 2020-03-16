import { Elm } from "./src/Main.elm";

const app = Elm.Main.init({
    node: document.getElementById("app"),
    flags: {},
});

if (app && app.ports && app.ports.sendvote)
    app.ports.sendVote.subscribe(vote => console.log("sendvote: ", vote));
else
    console.log("error subbing")

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
};

function sendIssueToElm(issue: Issue) {
    app.ports.receiveIssue.send(issue);
}

setInterval(() => {
    const i = {
        id: "0fc3a2d",
        title: "Some title",
        description: "Fancy, long description with a lot of information but maybe not too much.",
        // wtf typescript are you drunk
        state: "notstarted" as "notstarted" | "inprogress" | "finished",
        alternatives: [
            { id: "1", title: "Alternative One" },
            { id: "2", title: "Alternative Two" },
        ],
        votes: [
            { id: "1", alternativeId: "1" },
            { id: "2", alternativeId: "1" },
            { id: "3", alternativeId: "2" },
            // Not really the case that we have an anon vote mixed with public but hey
            { id: "4" },
        ],
        maxVoters: 10,
    };
    console.log("Sending issue");
    sendIssueToElm(i);
}, 3000)
