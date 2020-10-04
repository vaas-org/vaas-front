module Page.Admin exposing (view)

import Html exposing (Html, button, div, h2, h3, h4, p, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Model exposing (Issue, IssueState(..), Model, Msg, dummyIssue)
import Page.CreateIssue


view : Model -> Html Msg
view model =
    let
        activeIssues =
            List.filter (\i -> i.state == InProgress || i.state == VotingFinished) model.issues

        finishedIssues =
            List.filter (\i -> i.state == Finished) model.issues

        availableIssues =
            List.filter (\i -> i.state == NotStarted) model.issues
    in
    div []
        [ h2 [] [ text "Admin page" ]
        , case model.newIssue of
            Just issue ->
                Page.CreateIssue.view issue

            Nothing ->
                button [ onClick (Model.UpdateIssue dummyIssue) ] [ text "Create new issue" ]
        , div []
            [ h3 [] [ text "Issues" ]
            , button [ onClick Model.ListAllIssues ] [ text "List all issues" ]
            , div [ class "issue-list issue-list--active" ] [ issueList "Active Issue" activeIssues ]
            , div [ class "issue-list issue-list--available" ] [ issueList "Available Issues" availableIssues ]
            , div [ class "issue-list issue-list--completed" ] [ issueList "Completed Issues" finishedIssues ]
            ]
        ]


issueList : String -> List Issue -> Html Msg
issueList title issues =
    div []
        [ h4 []
            [ text
                (if List.isEmpty issues then
                    "No " ++ title

                 else
                    title
                )
            ]
        , div [] (List.map issueListItem issues)
        ]


type alias IssueStateTransition =
    { toState : IssueState
    , text : String
    }


issueListItem : Issue -> Html Msg
issueListItem issue =
    let
        availableActions =
            case issue.state of
                NotStarted ->
                    [ { toState = InProgress, text = "set active" }
                    , { toState = NotStarted, text = "delete" }
                    ]

                InProgress ->
                    [ { toState = InProgress, text = "reset voting" }
                    , { toState = VotingFinished, text = "close voting" }
                    ]

                VotingFinished ->
                    [ { toState = InProgress, text = "reset voting" }
                    , { toState = Finished, text = "publish results" }
                    ]

                Finished ->
                    []
    in
    div [ class "issue-list--item" ]
        [ div [ class "issue-list--item--header" ]
            [ h4 [] [ text issue.title ]
            , div [ class "issue-list--actions" ] (List.map (actionButton issue) availableActions)
            ]
        , div [] [ p [] [ text issue.description ] ]
        ]


actionButton : Issue -> IssueStateTransition -> Html Msg
actionButton issue transition =
    div [ onClick (Model.SetIssueState issue transition.toState) ] [ text ("[" ++ transition.text ++ "]") ]
