module Page.Portal exposing (view)

import Html exposing (Html, button, div, h2, input, label, text)
import Html.Attributes exposing (for, style, value)
import Html.Events exposing (onClick, onInput)
import Model exposing (Msg(..))


view : String -> Html Msg
view username =
    div [ style "grid-column" "2" ]
        [ h2 [] [ text "Portal" ]
        , div []
            [ label [ for "username" ] [ text "Username: " ]
            , input [ style "height" "16px", onInput SetUsername, value username ] []
            , button [ onClick (SendLogin username) ] [ text "📞" ]
            ]
        , div []
            [ label [ for "sessionid" ] [ text "SessionID: " ]
            , input [ style "height" "16px", onInput SetUsername, value username ] []
            , button [ onClick (Model.SendWebsocketReconnect username) ] [ text "☎️" ]
            ]
        ]
