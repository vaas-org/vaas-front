module Page.Error exposing (view)

import Html exposing (Html, div, text)


view : Html msg
view =
    div [] [ text "Whelp... Something seems to be wrong! Is the WebSocket server available?" ]
