module Page.Admin exposing (view)

import Html exposing (Html, div, h2, text)
import Model exposing (Model, Msg)
import Page.CreateIssue


view : Model -> Html Msg
view model =
    div []
        [ h2 [] [ text "Admin page" ]
        , Page.CreateIssue.view model.activeIssue
        ]
