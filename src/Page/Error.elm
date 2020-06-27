module Page.Error exposing (view)

import Html exposing (Html, button, div, text)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import Model exposing (Msg(..))


view : Maybe String -> Html Msg
view error =
    div [ style "grid-column-start" "2" ]
        [ div [] [ button [ onClick SendWebsocketConnect ] [ text "Reconnect" ] ]
        , case error of
            Just msg ->
                div [] [ text msg ]

            Nothing ->
                div [] [ text "Whelp... Something seems to be wrong! Is the WebSocket server available?" ]
        ]
