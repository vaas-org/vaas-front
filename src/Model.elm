module Model exposing (Alternative, Issue, IssueState(..), Meeting, User, Vote(..))


type alias UUID =
    String


type Vote
    = PublicVote
        { id : UUID
        }
    | AnonVote
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
    }


type alias Meeting =
    { id : UUID
    , title : String
    , start : String
    , issues : List Issue
    }
