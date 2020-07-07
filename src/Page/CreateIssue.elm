module Page.CreateIssue exposing (view)

import Html exposing (Html, button, div, input, label, li, text, ul)
import Html.Attributes exposing (style, value)
import Html.Events exposing (onClick, onInput)
import Model exposing (Issue, IssueField(..), Msg(..))


view : Issue -> Html Msg
view issue =
    div []
        [ div []
            [ formField "Title" (update issue Title) issue.title
            , formField "Description" (update issue Description) issue.description
            , formField "Alternatives" (update issue AddAlternative) ""
            , ul [] (List.map (\a -> li [ style "display" "flex" ] [ formField ("Alternative" ++ a.id) (update issue (UpdateAlternative a.id)) a.title, button [ onClick (update issue RemoveAlternative a.id) ] [ text "❌" ] ]) issue.alternatives)
            ]
        , div [] [ button [ onClick (CreateIssue issue) ] [ text "Create issue" ] ]
        ]


formField : String -> (String -> Msg) -> String -> Html Msg
formField fieldName updater val =
    div []
        [ label [] [ text fieldName ]
        , input [ onInput updater, value val ] []
        ]


update : Issue -> IssueField -> String -> Msg
update issue field val =
    case field of
        Title ->
            UpdateIssue { issue | title = val }

        Description ->
            UpdateIssue { issue | description = val }

        AddAlternative ->
            UpdateIssue { issue | alternatives = issue.alternatives ++ [ { id = String.fromInt (List.length issue.alternatives + 1), title = val } ] }

        RemoveAlternative ->
            UpdateIssue { issue | alternatives = List.filter (\a -> a.id /= val) issue.alternatives }

        UpdateAlternative id ->
            let
                alternatives =
                    List.map
                        (\a ->
                            { id = a.id
                            , title =
                                if a.id == id then
                                    val

                                else
                                    a.title
                            }
                        )
                        issue.alternatives
            in
            UpdateIssue { issue | alternatives = alternatives }
