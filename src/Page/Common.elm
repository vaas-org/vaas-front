module Page.Common exposing (connectionBullet, progressBar)

import Html exposing (Html, div, label, progress, span, text)
import Html.Attributes exposing (style, title, value)
import Model exposing (ConnectionStatus(..))


progressBar : String -> Float -> Float -> Html msg
progressBar title current maxValue =
    let
        pct =
            if maxValue == 0.0 then
                0.0

            else
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


connectionBullet : ConnectionStatus -> Html msg
connectionBullet status =
    let
        color =
            case status of
                Connected ->
                    "#42a200"

                NotConnectedYet ->
                    "red"

                Disconnected ->
                    "red"

                Connecting ->
                    "orange"

                _ ->
                    "hotpink"
    in
    span
        [ style "background-color" color
        , style "height" "8px"
        , style "width" "8px"
        , style "border-radius" "4px"
        , style "display" "inline-block"
        , title (connectionStatusStr status)
        ]
        []


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

        Reconnect _ ->
            "Reconnecting"

        Errored e ->
            "Connection error: " ++ e
