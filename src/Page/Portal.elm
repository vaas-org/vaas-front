module Page.Portal exposing (view)

import Html exposing (Html, a, button, div, h2, input, label, text)
import Html.Attributes exposing (for, href, style, value)
import Html.Events exposing (onClick, onInput)
import Model exposing (Client, Msg(..))
import Route exposing (Route(..))


view : Maybe Client -> String -> Html Msg
view client username =
    case client of
        Just c ->
            let
                initialText =
                    "You are already logged in"
                loggedInText =
                    case c.username of
                        Just connectedUser ->
                            initialText ++ " as " ++ connectedUser
                        Nothing ->
                            initialText
            in
            div []
                [ div [] [ text loggedInText ]
                -- go back ? go to stored state ?
                , div [] [ a [ Route.href Landing ] [ text "Go to landing page" ] ]
                ]

        Nothing ->
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
