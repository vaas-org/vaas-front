port module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Decoder exposing (decodeWebSocketMessage)
import Json.Decode as D
import Json.Encode as E
import Model exposing (ConnectionStatus(..), EventStatus(..), Flags, IssueState(..), Model, Msg(..), Theme(..), WebSocketMessage(..), dummyIssue)
import Page.App exposing (view)
import Route
import Task
import Url exposing (Url)


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }


init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    ( { activeIssue = dummyIssue
      , newIssue = Nothing
      , selectedAlternative = Nothing
      , sendVoteStatus = NotSent
      , websocketConnection = NotConnectedYet
      , username = ""
      , client =
            case flags.sessionId of
                Just sessionId ->
                    Just { sessionId = sessionId, username = Nothing }

                Nothing ->
                    Nothing
      , route = Route.fromUrl url
      , key = key
      , config = Light
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

        SendWebsocketReconnect sessionId ->
            ( model, sendEvent (E.object [ ( "type", E.string "reconnect" ), ( "session_id", E.string sessionId ) ]) )

        SendWebsocketDisconnect ->
            ( model, Cmd.batch [ removeSessionId (), sendWebsocketDisconnect () ] )

        ReceiveWebsocketConnectionState state ->
            let
                connectAction =
                    model.websocketConnection

                decodedState =
                    decodeWebsocketConnectionState state

                client =
                    if decodedState == Disconnected && connectAction == Disconnecting then
                        Nothing

                    else
                        model.client

                newModel =
                    { model | websocketConnection = decodedState, client = client }
            in
            ( newModel
            , if decodeWebsocketConnectionState state == Connected then
                case connectAction of
                    Reconnect sessionId ->
                        send (SendWebsocketReconnect sessionId)

                    Connecting ->
                        case Maybe.map (\c -> c.sessionId) client of
                            Just sessionId ->
                                send (SendWebsocketReconnect sessionId)

                            Nothing ->
                                send NoOp

                    _ ->
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
                    E.object [ ( "alternative_id", E.string alt.id ), ( "issue_id", E.string model.activeIssue.id ) ]
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
            ( { model | client = Just client }, storeSessionId (E.string client.sessionId) )

        SendLogin username ->
            case model.client of
                Just client ->
                    ( model, sendLogin (E.object [ ( "user_id", E.string client.sessionId ), ( "username", E.string username ) ]) )

                Nothing ->
                    -- Connect first, and then send a new message about the login. I guess?
                    ( model, sendLogin (E.object [ ( "username", E.string username ) ]) )

        CreateIssue issue ->
            ( model
            , sendEvent
                (E.object
                    [ ( "type", E.string "issue_create" )
                    , ( "issue"
                      , E.object
                            [ ( "title", E.string issue.title )
                            , ( "description", E.string issue.description )
                            , ( "alternatives"
                              , E.list
                                    (\a ->
                                        E.object
                                            [ ( "title", E.string a.title )
                                            ]
                                    )
                                    issue.alternatives
                              )
                            , ( "show_distribution", E.bool True )
                            ]
                      )
                    ]
                )
            )

        UpdateIssue issue ->
            ( { model | newIssue = Just issue }, Cmd.none )

        UrlChanged url ->
            ( { model | route = Route.fromUrl url }, Cmd.none )

        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        SetConfig config ->
            ( { model | config = config }, Cmd.none )



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


port sendEvent : E.Value -> Cmd msg


port sendWebsocketDisconnect : () -> Cmd msg


port receiveWebsocketStatus : (E.Value -> msg) -> Sub msg


port receiveWebSocketMessage : (E.Value -> msg) -> Sub msg


port storeSessionId : E.Value -> Cmd msg


port removeSessionId : () -> Cmd msg


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
