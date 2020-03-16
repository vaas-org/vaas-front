module Main exposing (main)

import Browser
import Html exposing (Html, div, form, h1, h2, h3, header, input, label, p, progress, span, text)
import Html.Attributes exposing (max, name, style, type_, value)
import Model exposing (Alternative, Issue, IssueState(..))
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
    { id = "1"
    , title = "An Issue"
    , description = "long issue description"
    , state = NotStarted
    , votes = []
    , alternatives = [ alternativeOne, alternativeTwo ]
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
        [ issueContainer model
        ]


issueContainer : Model -> Html Msg
issueContainer model =
    div
        [ style "display" "flex"
        , style "justify-content" "space-between"
        , style "flex-wrap" "wrap"
        ]
        [ issueView model.activeIssue

        -- Hard coded to 10 users for testing purposes
        , issueProgress 10 model.activeIssue
        ]


issueView : Issue -> Html Msg
issueView issue =
    div
        [ style "border" "1px solid #ddd"
        , style "border-radius" "4px"
        , style "margin-bottom" "1rem"
        , style "padding" "0 1rem 1rem"
        , style "flex" "1 1 30rem"
        ]
        [ div []
            [ h2 [] [ text issue.title ]
            , p [] [ text issue.description ]
            ]
        , form [] (List.map (\a -> alternative a) issue.alternatives)
        ]


alternative : Alternative -> Html Msg
alternative alt =
    div
        [ style "border" "1px solid #eee"
        , style "border-radius" "4px"
        , style "padding" "2px"
        ]
        [ label [] [ text alt.title ]
        , input [ type_ "radio", name "alternative" ] []
        ]


issueProgress : Int -> Issue -> Html msg
issueProgress voters issue =
    div
        [ style "flex" "1 1 8rem"
        , style "border" "1px solid #ddd"
        , style "border-radius" "4px"
        , style "margin-bottom" "1rem"
        , style "padding" "0 1rem 1rem"
        ]
        [ div []
            [ h3 [] [ text "Status" ]

            -- Add 2 votes for testing purposes
            , progressBar (Basics.toFloat (List.length issue.votes) + 2) (Basics.toFloat voters)
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



-- Update & other model state management


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )



-- util function which accepts a Msg as argument and converts it to a Cmd Msg.
-- This is used when a Msg should trigger another Msg in update


send : Msg -> Cmd Msg
send msg =
    Task.succeed msg |> Task.perform identity


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
