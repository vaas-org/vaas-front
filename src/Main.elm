module Main exposing (main)

import Browser exposing (Document)
import Html exposing (h1, text)

main : Program Flags Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
type alias Model = {}

type Msg = NoOp

type alias Flags = {}

init : Flags -> (Model, Cmd Msg)
init _ = ({}, Cmd.none)

view : Model -> Document Msg
view _ = {title= "", body= [h1 [] [text "Hello, world!"]]}

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = 
    case msg of
        NoOp ->
            (model, Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
