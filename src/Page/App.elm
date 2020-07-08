module Page.App exposing (view)

import Html exposing (Html, button, div, h1, header, span, text)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import Model exposing (Client, ConnectionStatus(..), Model, Msg(..))
import Page.Admin
import Page.Common exposing (connectionBullet)
import Page.Error
import Page.Loading
import Page.Portal
import Page.Vote exposing (issueContainer)


adminToggle : Html Msg
adminToggle =
    div [ style "display" "inline-block" ]
        [ button [ style "display" "inline-block", onClick ToggleAdminView ] [ text "🔧" ]
        ]


body : Model -> Html Msg
body model =
    div
        [ style "grid-column" "2"
        , style "margin-top" "3rem"
        ]
        [ if model.showAdminPage then
            Page.Admin.view model

          else if model.activeIssue.id /= "" then
            issueContainer model

          else
            div [] [ text "no active issue" ]
        ]


view : Model -> Html Msg
view model =
    let
        isAdmin =
            case model.client of
                Just client ->
                    case client.username of
                        Just username ->
                            username == "admin"

                        Nothing ->
                            False

                Nothing ->
                    False
    in
    div
        [ style "display" "grid"
        , style "height" "100vh"
        , style "grid-template-rows" "4rem auto 4rem"
        , style "grid-template-columns" "1fr min(80%, 1200px) 1fr"
        ]
        [ banner isAdmin
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
                case model.client of
                    Just _ ->
                        Page.Loading.view

                    Nothing ->
                        Page.Portal.view model.username

            Disconnected ->
                Page.Error.view Nothing

            Errored error ->
                Page.Error.view (Just error)

            Disconnecting ->
                Page.Loading.view

        -- we should technically show an error here
        -- Page.Loading.view
        , footer model.websocketConnection model.client
        ]


banner : Bool -> Html Msg
banner showAdminToggle =
    header
        [ style "grid-column" "span 3"
        , style "margin" "0"
        , style "border-bottom-left-radius" "10px"
        , style "border-bottom-right-radius" "10px"
        ]
        [ div
            [ style "display" "flex"
            , style "align-items" "center"
            , style "justify-content" "space-between"
            , style "height" "100%"
            ]
            [ h1
                [ style "margin-left" "1rem"
                ]
                [ span [] [ text "VaaS" ]
                , if showAdminToggle then
                    adminToggle

                  else
                    span [] []
                ]
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
