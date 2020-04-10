module Model exposing (Alternative, Client, Issue, IssueState(..), Meeting, UUID, User, Vote(..), WebSocketMessage(..))


type alias UUID =
    String


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
    { id : UUID
    , username : String
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
