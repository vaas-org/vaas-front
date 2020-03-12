module Main exposing (main)

import Browser
import Html exposing (Html, h1, text)


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    {}


type Msg
    = NoOp


type alias Flags =
    {}


init : Flags -> ( Model, Cmd Msg )
init _ =
    ( {}, Cmd.none )


view : Model -> Html Msg
view model =
    h1 [] [ text "Hello, world!" ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )



-- util function which accepts a Msg as argument and converts it to a Cmd Msg.
-- This is used when a Msg should trigger another Msg in update


send : Msg -> Cmd Msg
send msg =
    Task.succeed msg |> Task.perform identity


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
