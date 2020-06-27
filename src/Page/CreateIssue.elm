module Page.CreateIssue exposing (view)

import Html exposing (Html, div, text)
import Model exposing (Issue, Msg)


view : Issue -> Html Msg
view issue =
    div [] [ text ("Issue title:" ++ issue.title) ]
