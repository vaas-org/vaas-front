module Page.Admin exposing (view)

import Html exposing (Html, button, div, h2, text)
import Html.Events exposing (onClick)
import Model exposing (Model, Msg, dummyIssue)
import Page.CreateIssue


view : Model -> Html Msg
view model =
    div []
        [ h2 [] [ text "Admin page" ]
        , button [ onClick Model.ListAllIssues ] [ text "List all issues" ]
        , case model.newIssue of
            Just issue ->
                Page.CreateIssue.view issue

            Nothing ->
                button [ onClick (Model.UpdateIssue dummyIssue) ] [ text "Create new issue" ]
        ]
