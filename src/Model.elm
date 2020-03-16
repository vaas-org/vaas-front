module Model exposing (Alternative, Issue, IssueState(..), Meeting, UUID, User, Vote(..))


type alias UUID =
    String


type Vote
    = AnonVote
        { id : String
        }
    | PublicVote
        { id : String
        , alternativeId : String
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
    }


type alias Meeting =
    { id : UUID
    , title : String
    , start : String
    , issues : List Issue
    }
