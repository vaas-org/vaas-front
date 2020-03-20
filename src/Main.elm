port module Main exposing (main)

import Browser
import Decoder exposing (decodeReceivedIssue)
import Html exposing (Html, div, form, h1, h2, h3, header, input, label, li, p, progress, span, text, ul)
import Html.Attributes exposing (max, name, style, type_, value)
import Json.Decode as D
import Json.Encode as E
import Model exposing (Alternative, Issue, IssueState(..), Vote)
import Task


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { activeIssue : Issue
    }


type Msg
    = NoOp
    | ReceiveIssue E.Value


type alias Flags =
    {}


alternativeOne : Alternative
alternativeOne =
    { id = "0"
    , title = "Alternative Zero"
    }


alternativeTwo : Alternative
alternativeTwo =
    { id = "1"
    , title = "Alternative One"
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
    }


init : Flags -> ( Model, Cmd Msg )
init _ =
    ( { activeIssue = dummyIssue }, Cmd.none )


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
        [ banner
        , body model
        , footer
        ]


banner : Html msg
banner =
    header
        [ style "grid-column" "span 3"
        , style "margin" "0 1.5rem"
        ]
        [ h1 [] [ text "VaaS" ]
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
        [ issueView model.activeIssue
        , issueProgress model.activeIssue.maxVoters model.activeIssue
        , voteListContainer model.activeIssue.votes
        ]


issueView : Issue -> Html Msg
issueView issue =
    let
        issueState =
            case issue.state of
                NotStarted ->
                    "Not Started"

                InProgress ->
                    "In Progress"

                Finished ->
                    "Finished"
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
        , form [] (List.map (\a -> alternative a) issue.alternatives)
        ]


alternative : Alternative -> Html Msg
alternative alt =
    div
        [ style "margin" "0.5rem 0"
        , style "border-radius" "6px"
        , style "background-color" "rgb(50, 130, 215)"
        ]
        [ label
            [ Html.Attributes.for alt.title
            , style "padding" "0.75rem"
            , style "display" "block"
            , style "width" "100%"
            , style "color" "#fefefe"
            ]
            [ text alt.title ]
        , input
            [ type_ "radio"
            , name "alternative"
            , Html.Attributes.id alt.title
            , style "display" "none"
            ]
            []
        ]


issueProgress : Int -> Issue -> Html msg
issueProgress voters issue =
    div
        [ style "flex" "1 1 12rem"
        , style "border" "1px solid #ddd"
        , style "border-radius" "4px"
        , style "margin-bottom" "1rem"
        , style "padding" "0 1rem 1rem"
        ]
        [ div []
            [ h3 [] [ text "Status" ]
            , progressBar (Basics.toFloat (List.length issue.votes)) (Basics.toFloat voters)
            ]
        ]


progressBar : Float -> Float -> Html msg
progressBar current maxValue =
    let
        pct =
            (current / maxValue) * 100

        pctTxt =
            String.fromFloat pct ++ "%"
    in
    div [ style "display" "flex", style "justify-content" "space-between" ]
        [ progress
            [ style "height" "1rem"
            , style "flex" "1"
            , Html.Attributes.max (String.fromFloat maxValue)
            , value (String.fromFloat current)
            ]
            [ text pctTxt ]
        , span [ style "margin-left" "1rem" ] [ text pctTxt ]
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

        ReceiveIssue i ->
            let
                issue =
                    case D.decodeValue decodeReceivedIssue i of
                        Ok okIssue ->
                            okIssue

                        Err e ->
                            { id = "0"
                            , title = "Error decoding issue"
                            , description = D.errorToString e
                            , state = NotStarted
                            , alternatives = []
                            , votes = []
                            , maxVoters = 0
                            }
            in
            ( { model | activeIssue = issue }, Cmd.none )



-- util function which accepts a Msg as argument and converts it to a Cmd Msg.
-- This is used when a Msg should trigger another Msg in update


send : Msg -> Cmd Msg
send msg =
    Task.succeed msg |> Task.perform identity


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ receiveIssue ReceiveIssue
        ]


port sendVote : E.Value -> Cmd msg


port receiveIssue : (E.Value -> msg) -> Sub msg
