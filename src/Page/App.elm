module Page.App exposing (view)

import Browser
import Html exposing (Attribute, Html, a, button, div, h1, header, span, text)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import Model exposing (Client, ConnectionStatus(..), Model, Msg(..))
import Page.Admin
import Page.Common exposing (connectionBullet)
import Page.Error
import Page.Loading
import Page.Portal
import Page.Vote exposing (issueContainer)
import Route exposing (Route)


type MenuItem
    = Link { icon : String, route : Route, show : Bool }
    | Button { icon : String, cmd : Msg, show : Bool }


menuitems : Bool -> Maybe Client -> Html Msg
menuitems isAdmin client =
    let
        items =
            [ Link { icon = "🔧", route = Route.Config, show = True }
            , Link { icon = "👨\u{200D}🚒", route = Route.Admin, show = isAdmin }
            , Button { icon = "🚨", cmd = SendWebsocketDisconnect, show = client /= Nothing }
            ]
    in
    div [ style "display" "inline-block" ]
        (items
            |> List.filter
                (\item ->
                    case item of
                        Link l ->
                            l.show

                        Button b ->
                            b.show
                )
            |> List.map
                (\item ->
                    case item of
                        Link l ->
                            a
                                [ style "display" "inline-block", Route.href l.route ]
                                [ text l.icon ]

                        Button b ->
                            button [ style "display" "inline-block", onClick b.cmd ] [ text b.icon ]
                )
        )


body : Model -> Html Msg
body model =
    div
        [ style "grid-column" "2"
        , style "margin-top" "3rem"
        ]
        [ case model.route of
            Nothing ->
                div [] [ text "Not found" ]

            Just (Route.Meeting meetingId) ->
                page model

            Just Route.Admin ->
                Page.Admin.view model

            Just Route.Config ->
                div [] [ text "config" ]

            Just Route.Login ->
                Page.Portal.view model.client model.username

            Just Route.Landing ->
                div []
                    [ div [] [ text "Landing page yo" ]
                    , a [ Route.href (Route.Meeting "1") ] [ text "United Nations meeting about corona" ]
                    ]
        ]


view : Model -> Browser.Document Msg
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
    { title = "VaaS"
    , body =
        [ div
            [ style "display" "grid"
            , style "background-color" "#f5f5f5"
            , style "height" "100%"
            , style "min-height" "100vh"
            , style "grid-template-rows" "4rem auto 4rem"
            , style "grid-template-columns" "1fr min(80%, 1200px) 1fr"
            ]
            [ banner isAdmin model.client
            , body model
            ]
        ]
    }


page : Model -> Html Msg
page model =
    case model.websocketConnection of
        Connected ->
            case model.client of
                Just _ ->
                    issueContainer model

                Nothing ->
                    -- Page.Portal.view model.username
                    -- send to login
                    -- and send back ?
                    div [] [ a [ Route.href Route.Login ] [ text "Go to login" ] ]

        Reconnect _ ->
            Page.Loading.view

        Connecting ->
            case model.client of
                Just _ ->
                    Page.Loading.view

                Nothing ->
                    Page.Portal.view model.client model.username

        NotConnectedYet ->
            case model.client of
                Just _ ->
                    Page.Loading.view

                Nothing ->
                    Page.Portal.view model.client model.username

        Disconnected ->
            Page.Error.view Nothing

        Errored error ->
            Page.Error.view (Just error)

        Disconnecting ->
            Page.Loading.view


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
                [ a [ Route.href Route.Landing ] [ text "VaaS" ]
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
