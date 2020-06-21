module Page.App exposing (view)

import Html exposing (Html, button, div, h1, header, input, label, span, text)
import Html.Attributes exposing (for, style, value)
import Html.Events exposing (onClick, onInput)
import Model exposing (Client, ConnectionStatus(..), Model, Msg(..))
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
        , if model.websocketConnection == Model.Connected then
            case model.client of
                Just client ->
                    case client.username of
                        -- @ToDo: This checks if the user is authenticated
                        -- as in 'should receive some data back'
                        -- This can be a guest account just fine
                        Just _ ->
                            body model

                        Nothing ->
                            Page.Portal.view model.username

                Nothing ->
                    -- loading page mby
                    Page.Portal.view model.username

          else
            -- we should technically show an error here
            Page.Portal.view model.username
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


footer : ConnectionStatus -> Maybe Client -> Html msg
footer connection client =
    div
        [ style "grid-column" "2"
        , style "margin" "auto auto .25rem"
        ]
        [ span []
            [ case connection of
                Connected ->
                    case client of
                        Just c ->
                            case c.username of
                                Just username ->
                                    text ("Connected as " ++ username ++ "(" ++ c.sessionId ++ ")")

                                Nothing ->
                                    text ("Connected (" ++ c.sessionId ++ ")")

                        Nothing ->
                            text "Connected"

                _ ->
                    text (connectionStatusStr connection)
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
