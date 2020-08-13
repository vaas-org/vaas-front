module Page.Config exposing (view)

import Html exposing (Html, button, div, h2, span, text)
import Html.Events exposing (onClick)
import Model exposing (Config, Msg(..), Theme(..))


view : Config -> Html Msg
view config =
    div []
        [ h2 [] [ text "Config" ]
        , div []
            [ span [] [ text "Theme" ]
            , button [ onClick (update config (SetTheme Light)) ] [ text "Light" ]
            , button [ onClick (update config (SetTheme Dark)) ] [ text "Dark" ]
            ]
        ]


type ConfigChange
    = SetTheme Theme


update : Config -> ConfigChange -> Msg
update _ change =
    case change of
        SetTheme theme ->
            SetConfig theme
