module Page.Vote exposing (issueContainer)

import Html exposing (Html, div, form, h2, h3, h4, input, label, li, p, span, text, ul)
import Html.Attributes exposing (name, style, type_)
import Html.Events exposing (onClick)
import Model exposing (Alternative, ConnectionStatus(..), EventStatus(..), Issue, IssueState(..), Model, Msg(..), UUID, Vote)
import Page.Common exposing (progressBar)


issueContainer : Model -> Html Msg
issueContainer model =
    div
        [ style "display" "grid"
        , style "grid-template-columns" "repeat(auto-fit, minmax(15rem, 30rem))"
        , style "grid-gap" "1rem"
        ]
        [ issueView model.activeIssue model.selectedAlternative (model.sendVoteStatus /= NotSent)
        , issueProgress model.activeIssue.maxVoters model.activeIssue
        , voteListContainer model.activeIssue.votes
        ]


issueView : Issue -> Maybe Alternative -> Bool -> Html Msg
issueView issue maybeSelectedAlternative disableSubmit =
    let
        selectedAlternative =
            case maybeSelectedAlternative of
                Just a ->
                    a

                Nothing ->
                    { id = "", title = "" }

        submitDisabledState =
            disableSubmit || maybeSelectedAlternative == Nothing
    in
    div
        [ style "border" "1px solid #ddd"
        , style "border-radius" "4px"
        , style "padding" "0 1rem 1rem"
        ]
        [ div []
            [ h2 [] [ text issue.title ]
            , p [] [ text issue.description ]
            ]
        , form
            [ style "display" "flex"
            , style "flex-direction"
                "column"
            , Html.Events.onSubmit NoOp
            ]
            [ div [] (List.map (\a -> alternative a (selectedAlternative.id == a.id)) issue.alternatives)
            , Html.button
                [ style "width" "10rem"
                , style "margin-left" "auto"
                , style "padding" "0.75rem"
                , if submitDisabledState then
                    style "background-color" "#ccc"

                  else
                    style "background-color" "rgb(50, 130, 215)"
                , if submitDisabledState then
                    style "border" "1px solid #ccc"

                  else
                    style "border" "1px solid rgb(50, 130, 215)"
                , style "border-radius" "6px"
                , style "color" "#fefefe"
                , onClick (SendVote selectedAlternative)
                , Html.Attributes.disabled submitDisabledState
                ]
                [ text "Submit" ]
            ]
        ]


alternative : Alternative -> Bool -> Html Msg
alternative alt selected =
    div
        [ style "margin" "0.5rem 0"
        , style "border-radius" "6px"
        , if selected then
            style "border" "3px solid rgb(40, 90, 150)"

          else
            style "border" "3px solid rgb(50, 130, 215)"
        , style "background-color" "rgb(50, 130, 215)"
        ]
        [ label
            [ Html.Attributes.for alt.title
            , style "padding" "0.75rem"
            , style "display" "block"
            , style "width" "100%"
            , style "color" "#fefefe"
            , if selected then
                style "text-decoration" "underline"

              else
                style "text-decoration" "none"
            ]
            [ text alt.title ]
        , input
            [ type_ "radio"
            , name "alternative"
            , Html.Attributes.id alt.title
            , style "display" "none"
            , onClick (SelectAlternative alt)
            ]
            []
        ]


getVotesForAlternative : UUID -> List UUID -> Int
getVotesForAlternative alternativeId votes =
    List.length (List.filter (\vId -> vId == alternativeId) votes)


issueProgress : Int -> Issue -> Html msg
issueProgress voters issue =
    let
        voteStatus =
            case issue.state of
                NotStarted ->
                    "Not Started"

                InProgress ->
                    "In Progress"

                Finished ->
                    "Finished"

        votes =
            if issue.showDistribution then
                List.map
                    (\v ->
                        case v of
                            Model.PublicVote vv ->
                                vv.alternativeId

                            -- This should never be the case, since we already checked if we should show
                            -- the vote distribution. Therefore the backend should only have sent us PublicVotes.
                            Model.AnonVote _ ->
                                ""
                    )
                    issue.votes

            else
                []
    in
    div
        [ style "border" "1px solid #ddd"
        , style "border-radius" "4px"
        , style "padding" "0 1rem 1rem"
        ]
        [ div []
            [ h3 [] [ text "Status" ]
            , h4 []
                [ span []
                    [ span [] [ text "Voting - " ]
                    , span [ style "font-style" "italic" ] [ text voteStatus ]
                    ]
                ]
            , progressBar "Total" (Basics.toFloat (List.length issue.votes)) (Basics.toFloat voters)
            , if issue.showDistribution then
                div [] (List.map (\a -> progressBar a.title (Basics.toFloat (getVotesForAlternative a.id votes)) (Basics.toFloat (List.length votes))) issue.alternatives)

              else
                div [] []
            ]
        ]


voteListContainer : List Vote -> Html msg
voteListContainer votes =
    div
        [ style "min-width" "12rem"
        , style "border" "1px solid #ddd"
        , style "border-radius" "4px"
        , style "padding" "0 1rem 1rem"
        ]
        [ h3 [] [ text "Votes" ]
        , voteList votes
        ]


voteList : List Vote -> Html msg
voteList votes =
    ul []
        (List.map
            (\v ->
                case v of
                    Model.AnonVote a ->
                        li [] [ text ("(" ++ a.id ++ ") Voted") ]

                    Model.PublicVote p ->
                        li [] [ text ("(" ++ p.id ++ ") Voted for " ++ p.alternativeId) ]
            )
            votes
        )
