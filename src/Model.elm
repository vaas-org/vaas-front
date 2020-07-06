module Model exposing (Alternative, Client, ConnectionStatus(..), EventStatus(..), Flags, Issue, IssueField(..), IssueState(..), Meeting, Model, Msg(..), UUID, User, Vote(..), WebSocketMessage(..), dummyIssue)

import Json.Encode as E


type alias UUID =
    String


type alias SessionId =
    UUID


type Vote
    = AnonVote
        { id : UUID
        }
    | PublicVote
        { id : UUID
        , alternativeId : UUID
        }


type alias User =
    { id : UUID
    , displayName : String
    }


type alias Alternative =
    { id : UUID
    , title : String
    }


type IssueState
    = NotStarted
    | InProgress
    | Finished


type alias Issue =
    { id : UUID
    , title : String
    , description : String
    , state : IssueState
    , alternatives : List Alternative
    , votes : List Vote
    , maxVoters : Int
    , showDistribution : Bool
    }


type alias Client =
    { sessionId : UUID
    , username : Maybe String
    }


type alias Meeting =
    { id : UUID
    , title : String
    , start : String
    , issues : List Issue
    }


type WebSocketMessage
    = IssueMessage Issue
    | VoteMessage Vote
    | ClientMessage Client


type EventStatus
    = NotSent
    | Sent
    | Success
    | Failed String


type ConnectionStatus
    = NotConnectedYet
    | Connecting
    | Connected
    | Disconnecting
    | Disconnected
    | Reconnect SessionId
    | Errored String


type alias Model =
    { activeIssue : Issue
    , newIssue : Maybe Issue
    , selectedAlternative : Maybe Alternative
    , sendVoteStatus : EventStatus
    , websocketConnection : ConnectionStatus
    , username : String
    , client : Maybe Client
    , showAdminPage : Bool
    }


type IssueField
    = Title
    | Description
    | AddAlternative
    | RemoveAlternative
    | UpdateAlternative String


type Msg
    = NoOp
    | ReceiveIssue Issue
    | SelectAlternative Alternative
    | SendVote Alternative
    | SetVoteStatus EventStatus
    | ReceiveVote Vote -- Consider if we should expect issueId here too?
    | SendWebsocketConnect
    | SendWebsocketReconnect SessionId
    | SendWebsocketDisconnect
    | ReceiveWebsocketConnectionState E.Value
    | SetUsername String
    | SetClient Client
    | SendLogin String
    | ToggleAdminView
    | UpdateIssue Issue


type alias Flags =
    { sessionId : Maybe SessionId
    }


dummyIssue : Issue
dummyIssue =
    { id = ""
    , title = ""
    , description = ""
    , state = NotStarted
    , votes = []
    , alternatives = []
    , maxVoters = 0
    , showDistribution = False
    }
