module Decoder exposing (decodeAlternative, decodeReceivedIssue, decodeVote, decodeWebSocketMessage)

import Json.Decode as D
import Model exposing (Alternative, Issue, IssueState(..), Vote(..), WebSocketMessage(..))


decodePublicVote : D.Decoder Vote
decodePublicVote =
    D.map2 (\id alternativeId -> PublicVote { id = id, alternativeId = alternativeId })
        (D.field "id" D.string)
        (D.field "alternativeId" D.string)


decodeAnonVote : D.Decoder Vote
decodeAnonVote =
    D.map (\id -> AnonVote { id = id })
        (D.field "id" D.string)


decodeVote : D.Decoder Vote
decodeVote =
    D.oneOf [ decodePublicVote, decodeAnonVote ]


decodeAlternative : D.Decoder Alternative
decodeAlternative =
    D.map2 Alternative
        (D.field "id" D.string)
        (D.field "title" D.string)


decodeIssueState : String -> D.Decoder IssueState
decodeIssueState s =
    case s of
        "notstarted" ->
            D.succeed NotStarted

        "inprogress" ->
            D.succeed InProgress

        "finished" ->
            D.succeed Finished

        _ ->
            D.fail ("error decoding '" ++ s ++ "' as IssueState")


decodeReceivedIssue : D.Decoder Issue
decodeReceivedIssue =
    D.map8 Issue
        (D.field "id" D.string)
        (D.field "title" D.string)
        (D.field "description" D.string)
        (D.field "state" D.string |> D.andThen decodeIssueState)
        (D.field "alternatives" (D.list decodeAlternative))
        (D.field "votes" (D.list decodeVote))
        (D.field "max_voters" D.int)
        (D.field "show_distribution" D.bool)


decodeWebSocketMessage : D.Decoder WebSocketMessage
decodeWebSocketMessage =
    D.field "type" D.string
        |> D.andThen decodeMessageType


decodeMessageType : String -> D.Decoder WebSocketMessage
decodeMessageType messageType =
    case messageType of
        "issue" ->
            decodeReceivedIssue |> D.map IssueMessage

        "vote" ->
            decodeVote |> D.map VoteMessage

        _ ->
            D.fail <| "Trying to decode unknown message type: " ++ messageType
