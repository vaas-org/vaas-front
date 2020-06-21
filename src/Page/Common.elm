module Page.Common exposing (progressBar)

import Html exposing (Html, div, label, progress, span, text)
import Html.Attributes exposing (style, value)


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
