module Route exposing (Route(..), fromUrl, href, replaceUrl)

import Browser.Navigation as Nav
import Html exposing (Attribute)
import Html.Attributes as Attr
import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), Parser, oneOf, s, string)


type Route
    = Landing
    | Meeting String
    | Login
    | Admin
    | Config


parser : Parser (Route -> a) a
parser =
    oneOf
        [ Parser.map Landing Parser.top
        , Parser.map Meeting (s "meeting" </> string)
        , Parser.map Admin (s "admin")
        , Parser.map Config (s "config")
        , Parser.map Login (s "login")
        ]


href : Route -> Attribute msg
href targetRoute =
    Attr.href (routeToString targetRoute)


fromUrl : Url -> Maybe Route
fromUrl =
    Parser.parse parser


replaceUrl : Nav.Key -> Route -> Cmd msg
replaceUrl key route =
    Nav.replaceUrl key (routeToString route)


routeToString : Route -> String
routeToString route =
    "/" ++ String.join "/" (routeToPieces route)


routeToPieces : Route -> List String
routeToPieces route =
    case route of
        Landing ->
            []

        Meeting id ->
            [ "meeting", id ]

        Admin ->
            [ "admin" ]

        Config ->
            [ "config" ]

        Login ->
            [ "login" ]
