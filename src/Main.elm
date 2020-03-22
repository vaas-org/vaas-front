port module Main exposing (main)

import Browser
import Decoder exposing (decodeVote, decodeWebSocketMessage)
import Html exposing (Html, button, div, form, h1, h2, h3, header, input, label, li, p, progress, span, text, ul)
import Html.Attributes exposing (for, max, name, style, type_, value)
import Html.Events exposing (onClick, onInput)
import Json.Decode as D
import Json.Encode as E
import Model exposing (Alternative, Issue, IssueState(..), UUID, Vote, WebSocketMessage(..))
import Task


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


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
    | Errored String


type alias Model =
    { activeIssue : Issue
    , selectedAlternative : Maybe Alternative
    , sendVoteStatus : EventStatus
    , websocketConnection : ConnectionStatus
    , username : String
    }


type Msg
    = NoOp
    | ReceiveIssue Issue
    | SelectAlternative Alternative
    | SendVote Alternative
    | SetVoteStatus EventStatus
    | ReceiveVote Vote -- Consider if we should expect issueId here too?
    | SendWebsocketConnect
    | SendWebsocketDisconnect
    | ReceiveWebsocketConnectionState E.Value
    | SetUsername String
    | SendLogin String


type alias Flags =
    {}


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


init : Flags -> ( Model, Cmd Msg )
init _ =
    ( { activeIssue = dummyIssue
      , selectedAlternative = Nothing
      , sendVoteStatus = NotSent
      , websocketConnection = NotConnectedYet
      , username = ""
      }
    , send SendWebsocketConnect
    )


view : Model -> Html Msg
view model =
    div
        [ style "display" "grid"
        , style "height" "100vh"
        , style "margin" "0 auto"
        , style "grid-template-rows" "4rem auto 4rem"
        , style "max-width" "1200px"
        , style "margin" "0 auto"

        -- @ToDo: if wide screen add some more padding
        , style "grid-template-columns" "1fr 80% 1fr"
        ]
        [ banner model.websocketConnection model.username
        , body model
        , footer
        ]


connectionStatusStr : ConnectionStatus -> String
connectionStatusStr status =
    case status of
        NotConnectedYet ->
            "Not yet connected"

        Connected ->
            "Connected"

        Connecting ->
            "Connecting"

        Disconnecting ->
            "Disconnecting"

        Disconnected ->
            "Disconnected"

        Errored e ->
            "Connection error: " ++ e


banner : ConnectionStatus -> String -> Html Msg
banner stat username =
    header
        [ style "grid-column" "span 3"
        , style "margin" "0 1.5rem"
        ]
        [ div [ style "display" "flex", style "align-items" "center", style "justify-content" "space-between" ]
            [ h1 [] [ text ("VaaS" ++ " - " ++ connectionStatusStr stat) ]
            , div []
                [ label [ for "username" ] [ text "Username: " ]
                , input [ style "height" "16px", onInput SetUsername, value username ] []
                , button [ onClick (SendLogin username) ] [ text "📞" ]
                ]
            ]
        ]


footer : Html msg
footer =
    div
        [ style "grid-column" "2"
        , style "margin" "auto auto .25rem"
        ]
        [ span [] [ text "footer" ]
        ]


body : Model -> Html Msg
body model =
    div
        [ style "grid-column" "2"
        , style "margin-top" "3rem"
        ]
        [ if model.activeIssue.id /= "" then
            issueContainer model

          else
            div [] [ text "no active issue" ]
        ]


issueContainer : Model -> Html Msg
issueContainer model =
    div
        [ style "display" "flex"
        , style "justify-content" "space-between"
        , style "flex-wrap" "wrap"
        ]
        [ issueView model.activeIssue model.selectedAlternative (model.sendVoteStatus /= NotSent)
        , issueProgress model.activeIssue.maxVoters model.activeIssue
        , voteListContainer model.activeIssue.votes
        ]


issueView : Issue -> Maybe Alternative -> Bool -> Html Msg
issueView issue maybeSelectedAlternative disableSubmit =
    let
        issueState =
            case issue.state of
                NotStarted ->
                    "Not Started"

                InProgress ->
                    "In Progress"

                Finished ->
                    "Finished"

        selectedAlternative =
            case maybeSelectedAlternative of
                Just a ->
                    a

                Nothing ->
                    { id = "", title = "" }

        submitDisabledState =
            disableSubmit || maybeSelectedAlternative == Nothing
    in
    div
        [ style "border" "1px solid #ddd"
        , style "border-radius" "4px"
        , style "margin-bottom" "1rem"
        , style "padding" "0 1rem 1rem"
        , style "flex" "1 1 35rem"
        ]
        [ div []
            [ h2 [] [ text (issue.title ++ "(" ++ issueState ++ ")") ]
            , p [] [ text issue.description ]
            ]
        , form
            [ style "display" "flex"
            , style "flex-direction"
                "column"
            , Html.Events.onSubmit NoOp
            ]
            [ div [] (List.map (\a -> alternative a (selectedAlternative.id == a.id)) issue.alternatives)
            , Html.button
                [ style "width" "10rem"
                , style "margin-left" "auto"
                , style "padding" "0.75rem"
                , if submitDisabledState then
                    style "background-color" "#ccc"

                  else
                    style "background-color" "rgb(50, 130, 215)"
                , if submitDisabledState then
                    style "border" "1px solid #ccc"

                  else
                    style "border" "1px solid rgb(50, 130, 215)"
                , style "border-radius" "6px"
                , style "color" "#fefefe"
                , onClick (SendVote selectedAlternative)
                , Html.Attributes.disabled submitDisabledState
                ]
                [ text "Submit" ]
            ]
        ]


alternative : Alternative -> Bool -> Html Msg
alternative alt selected =
    div
        [ style "margin" "0.5rem 0"
        , style "border-radius" "6px"
        , if selected then
            style "border" "3px solid rgb(40, 90, 150)"

          else
            style "border" "3px solid rgb(50, 130, 215)"
        , style "background-color" "rgb(50, 130, 215)"
        ]
        [ label
            [ Html.Attributes.for alt.title
            , style "padding" "0.75rem"
            , style "display" "block"
            , style "width" "100%"
            , style "color" "#fefefe"
            , if selected then
                style "text-decoration" "underline"

              else
                style "text-decoration" "none"
            ]
            [ text alt.title ]
        , input
            [ type_ "radio"
            , name "alternative"
            , Html.Attributes.id alt.title
            , style "display" "none"
            , onClick (SelectAlternative alt)
            ]
            []
        ]


getVotesForAlternative : UUID -> List UUID -> Int
getVotesForAlternative alternativeId votes =
    List.length (List.filter (\vId -> vId == alternativeId) votes)


issueProgress : Int -> Issue -> Html msg
issueProgress voters issue =
    let
        votes =
            if issue.showDistribution then
                List.map
                    (\v ->
                        case v of
                            Model.PublicVote vv ->
                                vv.alternativeId

                            -- This should never be the case, since we already checked if we should show
                            -- the vote distribution. Therefore the backend should only have sent us PublicVotes.
                            Model.AnonVote _ ->
                                ""
                    )
                    issue.votes

            else
                []
    in
    div
        [ style "flex" "1 1 12rem"
        , style "border" "1px solid #ddd"
        , style "border-radius" "4px"
        , style "margin-bottom" "1rem"
        , style "padding" "0 1rem 1rem"
        ]
        [ div []
            [ h3 [] [ text "Status" ]
            , progressBar "Total" (Basics.toFloat (List.length issue.votes)) (Basics.toFloat voters)
            , if issue.showDistribution then
                div [] (List.map (\a -> progressBar a.title (Basics.toFloat (getVotesForAlternative a.id votes)) (Basics.toFloat (List.length votes))) issue.alternatives)

              else
                div [] []
            ]
        ]


progressBar : String -> Float -> Float -> Html msg
progressBar title current maxValue =
    let
        pct =
            (current / maxValue) * 100

        pctTxt =
            String.fromInt (Basics.round pct) ++ "%"
    in
    div []
        [ label []
            [ text title ]
        , div
            [ style "display" "flex", style "justify-content" "space-between" ]
            [ progress
                [ style "height" "1rem"
                , style "flex" "1"
                , Html.Attributes.max (String.fromFloat maxValue)
                , value (String.fromFloat current)
                ]
                [ text pctTxt ]
            , span [ style "margin-left" "1rem" ] [ text pctTxt ]
            ]
        ]


voteListContainer : List Vote -> Html msg
voteListContainer votes =
    div
        [ style "flex" "0 1 12rem"
        , style "border" "1px solid #ddd"
        , style "border-radius" "4px"
        , style "margin-bottom" "1rem"
        , style "padding" "0 1rem 1rem"
        , style "justify-self" "flex-end"
        ]
        [ h3 [] [ text "Votes" ]
        , voteList votes
        ]


voteList : List Vote -> Html msg
voteList votes =
    ul []
        (List.map
            (\v ->
                case v of
                    Model.AnonVote a ->
                        li [] [ text ("(" ++ a.id ++ ") Voted") ]

                    Model.PublicVote p ->
                        li [] [ text ("(" ++ p.id ++ ") Voted for " ++ p.alternativeId) ]
            )
            votes
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

        SendLogin username ->
            ( model, sendLogin (E.string username) )



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
