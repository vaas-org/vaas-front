port module Main exposing (main)

import Browser
import Decoder exposing (decodeWebSocketMessage)
import Json.Decode as D
import Json.Encode as E
import Model exposing (ConnectionStatus(..), EventStatus(..), Flags, IssueState(..), Model, Msg(..), WebSocketMessage(..), dummyIssue)
import Page.App exposing (view)
import Task


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : Flags -> ( Model, Cmd Msg )
init _ =
    ( { activeIssue = dummyIssue
      , selectedAlternative = Nothing
      , sendVoteStatus = NotSent
      , websocketConnection = NotConnectedYet
      , username = ""
      , client = { id = "", username = Nothing }
      }
    , send SendWebsocketConnect
    )



-- Update & other model state management


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        SendWebsocketConnect ->
            ( model, sendWebsocketConnect () )

        SendWebsocketDisconnect ->
            ( model, sendWebsocketDisconnect () )

        ReceiveWebsocketConnectionState state ->
            ( { model | websocketConnection = decodeWebsocketConnectionState state }
            , if decodeWebsocketConnectionState state == Connected then
                send NoOp

              else
                Cmd.none
            )

        ReceiveIssue issue ->
            ( { model | activeIssue = issue }, Cmd.none )

        SelectAlternative clickedAlternative ->
            let
                selected =
                    if model.sendVoteStatus /= NotSent then
                        model.selectedAlternative

                    else
                        case model.selectedAlternative of
                            Just alt ->
                                -- Unselect alternative if clicking same as already selected
                                if clickedAlternative == alt then
                                    Nothing

                                else
                                    Just clickedAlternative

                            Nothing ->
                                Just clickedAlternative
            in
            ( { model | selectedAlternative = selected }, Cmd.none )

        SetVoteStatus status ->
            ( { model | sendVoteStatus = status }, Cmd.none )

        SendVote alt ->
            let
                decodedAlt =
                    E.object [ ( "alternative_id", E.string alt.id ), ( "user_id", E.string model.username ) ]
            in
            ( { model | sendVoteStatus = Sent }, Cmd.batch [ sendVote decodedAlt, send (SetVoteStatus Success) ] )

        ReceiveVote vote ->
            let
                modelIssue =
                    model.activeIssue

                -- updatedIssue =
                --     if issue.id == model.activeIssue.id then
                --     else
                --         model.activeIssue
                updatedIssue =
                    { modelIssue | votes = vote :: modelIssue.votes }
            in
            ( { model | activeIssue = updatedIssue }, Cmd.none )

        SetUsername username ->
            ( { model | username = username }, Cmd.none )

        SetClient client ->
            ( { model | client = client }, Cmd.none )

        SendLogin username ->
            ( model, sendLogin (E.object [ ( "user_id", E.string model.client.id ), ( "username", E.string username ) ]) )



-- util function which accepts a Msg as argument and converts it to a Cmd Msg.
-- This is used when a Msg should trigger another Msg in update


send : Msg -> Cmd Msg
send msg =
    Task.succeed msg |> Task.perform identity


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ receiveWebsocketStatus ReceiveWebsocketConnectionState
        , receiveWebSocketMessage webSocketMessageToMsg
        ]



-- Probably not a great name


webSocketMessageToMsg : E.Value -> Msg
webSocketMessageToMsg value =
    case D.decodeValue decodeWebSocketMessage value of
        Ok message ->
            case message of
                IssueMessage issue ->
                    ReceiveIssue issue

                VoteMessage vote ->
                    ReceiveVote vote

                ClientMessage client ->
                    SetClient client

        Err _ ->
            -- TODO Handle error somehow
            NoOp


port sendLogin : E.Value -> Cmd msg


port sendVote : E.Value -> Cmd msg


port sendWebsocketConnect : () -> Cmd msg


port sendWebsocketDisconnect : () -> Cmd msg


port receiveWebsocketStatus : (E.Value -> msg) -> Sub msg


port receiveWebSocketMessage : (E.Value -> msg) -> Sub msg


decodeWebsocketConnectionState : E.Value -> ConnectionStatus
decodeWebsocketConnectionState state =
    case D.decodeValue D.string state of
        Ok s ->
            case s of
                "connected" ->
                    Connected

                "connecting" ->
                    Connecting

                "disconnecting" ->
                    Disconnecting

                "disconnected" ->
                    Disconnected

                "notyetconnected" ->
                    NotConnectedYet

                a ->
                    Errored ("invalid connection state: " ++ a)

        Err e ->
            Errored ("failed to decode as string: " ++ D.errorToString e)
