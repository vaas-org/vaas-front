module Page.App exposing (view)

import Html exposing (Html, button, div, h1, header, input, label, span, text)
import Html.Attributes exposing (for, style, value)
import Html.Events exposing (onClick, onInput)
import Model exposing (Client, ConnectionStatus(..), Model, Msg(..))
import Page.Vote exposing (issueContainer)


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
        , footer model.client
        ]


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


footer : Client -> Html msg
footer client =
    div
        [ style "grid-column" "2"
        , style "margin" "auto auto .25rem"
        ]
        [ span []
            [ case client.username of
                Just username ->
                    text ("Connected as " ++ username ++ "(" ++ client.id ++ ")")

                Nothing ->
                    text ("Connected as (" ++ client.id ++ ")")
            ]
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
