module Page.Portal exposing (view)

import Html exposing (Html, button, div, h2, input, label, text)
import Html.Attributes exposing (for, style, value)
import Html.Events exposing (onClick, onInput)
import Model exposing (Msg(..))


view : String -> Html Msg
view username =
    div []
        [ h2 [] [ text "Portal" ]
        , div []
            [ label [ for "username" ] [ text "Username: " ]
            , input [ style "height" "16px", onInput SetUsername, value username ] []
            , button [ onClick (SendLogin username) ] [ text "📞" ]
            ]
        ]