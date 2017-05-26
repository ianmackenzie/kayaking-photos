module Main exposing (..)

import Html exposing (Html)
import Html.Attributes as Attributes
import Http
import Json.Decode as Decode exposing (Decoder)
import Kintail.InputWidget as InputWidget


{-| The current state of our app: they query string the user has typed in, and
maybe a list of image URLs to display
-}
type alias Model =
    { query : String
    , imageData : Maybe (List String)
    }


{-| Events that can happen in our app: the user can type in a new query string,
or we can receive a response back from CouchDB that contains either an error or
a list of image URLs
-}
type Msg
    = NewQuery String
    | ResponseIds (Result Http.Error (List String))


{-| Initial state of the app: empty query string, no image URLs
-}
init : ( Model, Cmd Msg )
init =
    ( { query = "", imageData = Nothing }, Cmd.none )


databaseUrl =
    "http://localhost:5984/kayaking-photos"


{-| The URL to our 'view' (a.k.a. index) of images by tag name
-}
viewUrl =
    databaseUrl ++ "/_design/docs/_view/by_tag"


{-| How to decode JSON responses from the server: expect a JSON object with a
field 'rows', that is a list of objects where 'id' is the string we want
-}
responseDecoder : Decoder (List String)
responseDecoder =
    Decode.field "rows" (Decode.list (Decode.field "id" Decode.string))


{-| How to respond to events: for each event, produce an updated model based on
the current model and potentially a 'command' (something to do in response, in
this case sending off an HTTP request whenever the query string changes)
-}
update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        NewQuery query ->
            let
                url =
                    viewUrl ++ "?key=\"" ++ query ++ "\""

                request =
                    Http.get url responseDecoder
            in
                ( { model | query = query }, Http.send ResponseIds request )

        ResponseIds (Err _) ->
            ( { model | imageData = Nothing }, Cmd.none )

        ResponseIds (Ok ids) ->
            ( { model | imageData = Just ids }, Cmd.none )


{-| How the app should look, based on the current state
-}
view : Model -> Html Msg
view model =
    let
        -- Input line edit that sends NewQuery messages whenever the text is
        -- edited
        lineEdit =
            InputWidget.lineEdit [] model.query
                |> Html.map NewQuery

        -- Function that constructs an image URL based on a CouchDB document ID
        imageUrl id =
            databaseUrl ++ "/" ++ id ++ "/image.jpg"

        -- Construct a list of <img> elements
        images =
            case model.imageData of
                Nothing ->
                    []

                Just ids ->
                    ids
                        |> List.map
                            (\id ->
                                Html.img
                                    [ Attributes.src (imageUrl id)
                                    , Attributes.style
                                        [ ( "max-width", "500px" )
                                        , ( "max-height", "500px" )
                                        ]
                                    ]
                                    []
                            )
    in
        -- Final HTML structure of the page
        Html.div []
            [ Html.div [] [ lineEdit ]
            , Html.div [] images
            ]


{-| Wire everything up using 'The Elm Architecture' to create an interactive web
app
-}
main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = always Sub.none
        }
