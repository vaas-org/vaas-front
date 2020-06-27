module Page.App exposing (view)

import Html exposing (Html, button, div, h1, header, span, text)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import Model exposing (Client, ConnectionStatus(..), Model, Msg(..))
import Page.Common exposing (connectionBullet)
import Page.Error
import Page.Loading
import Page.Portal
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
        [ banner
        , case model.websocketConnection of
            Connected ->
                case model.client of
                    Just _ ->
                        body model

                    Nothing ->
                        Page.Portal.view model.username

            Reconnect _ ->
                Page.Loading.view

            Connecting ->
                case model.client of
                    Just _ ->
                        Page.Loading.view

                    Nothing ->
                        Page.Portal.view model.username

            NotConnectedYet ->
                Page.Portal.view model.username

            Disconnected ->
                Page.Error.view

            Errored _ ->
                Page.Error.view

            Disconnecting ->
                Page.Loading.view

        -- we should technically show an error here
        -- Page.Loading.view
        , footer model.websocketConnection model.client
        ]


banner : Html msg
banner =
    header
        [ style "grid-column" "span 3"
        , style "margin" "0 1.5rem"
        ]
        [ div [ style "display" "flex", style "align-items" "center", style "justify-content" "space-between" ]
            [ h1 [] [ text "VaaS" ]
            ]
        ]


footer : ConnectionStatus -> Maybe Client -> Html Msg
footer connection client =
    div
        [ style "grid-column" "2"
        , style "margin" "auto auto .25rem"
        ]
        [ span []
            [ connectionBullet connection
            , case client of
                Just c ->
                    case c.username of
                        Just username ->
                            text (username ++ "(" ++ c.sessionId ++ ")")

                        Nothing ->
                            text ("(" ++ c.sessionId ++ ")")

                Nothing ->
                    text ""
            ]
        , case client of
            Just _ ->
                button [ onClick SendWebsocketDisconnect ] [ text "Logout 🚨" ]

            Nothing ->
                div [] []
        ]
