module Page.App exposing (view)

import Html exposing (Html, button, div, h1, header, span, text)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import Model exposing (Client, ConnectionStatus(..), Model, Msg(..), Page(..))
import Page.Admin
import Page.Common exposing (connectionBullet)
import Page.Error
import Page.Loading
import Page.Portal
import Page.Vote exposing (issueContainer)


menuitems : Bool -> Maybe Client -> Html Msg
menuitems isAdmin client =
    let
        items =
            [ { icon = "🔧", cmd = RenderPage Config, show = True }
            , { icon = "👨\u{200D}🚒", cmd = RenderPage Admin, show = isAdmin }
            , { icon = "🚨", cmd = SendWebsocketConnect, show = client /= Nothing }
            ]
    in
    div [ style "display" "inline-block" ]
        (items
            |> List.filter (\item -> item.show)
            |> List.map
                (\item ->
                    button
                        [ style "display" "inline-block", onClick item.cmd ]
                        [ text item.icon ]
                )
        )


body : Model -> Html Msg
body model =
    div
        [ style "grid-column" "2"
        , style "margin-top" "3rem"
        ]
        [ case model.page of
            App ->
                issueContainer model

            Admin ->
                Page.Admin.view model

            Config ->
                div [] [ text "config" ]
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
        , style "background-color" "#f5f5f5"
        , style "height" "100%"
        , style "min-height" "100vh"
        , style "grid-template-rows" "4rem auto 4rem"
        , style "grid-template-columns" "1fr min(80%, 1200px) 1fr"
        ]
        [ banner isAdmin model.client
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


banner : Bool -> Maybe Client -> Html Msg
banner isAdmin client =
    header
        [ style "grid-column" "span 3"
        , style "margin" "0"
        , style "background-color" "rgb(138, 58, 255)"
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
                , style "color" "#f5f5f5"
                ]
                [ span [ onClick (RenderPage App) ] [ text "VaaS" ]
                , menuitems isAdmin client
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
            [ connectionBullet connection client
            ]
        ]
