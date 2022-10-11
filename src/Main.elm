module Main exposing (main)

import Browser
import Html exposing (Html, button, input, div, text)
import Html.Events exposing (onClick)
import Html.Attributes exposing (placeholder, value)
import Html.Events exposing (onInput, on, keyCode)
import Http
import Json.Decode as Decode exposing (Decoder, string)
import Json.Decode.Pipeline exposing (required)

postcodeApiUrl : String
postcodeApiUrl = "https://api.postcodes.io/postcodes/"

type alias Model =
    { postCode : String
    , isLoading : Bool 
    , data : Maybe String
    , details : Maybe Response }


initialModel : () -> (Model, Cmd Msg)
initialModel _ =
    ({ postCode = "" 
    , isLoading = False
    , data = Nothing
    , details = Nothing
    },
    Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions _ =
  Sub.none

postcodeDecoder : Decoder PostcodeDetails
postcodeDecoder = 
    Decode.succeed PostcodeDetails
        |> required "country" string
        |> required "region" string

responseDecoder : Decoder Response
responseDecoder = 
    Decode.succeed Response
        |> required "status" Decode.int
        |> required "result" postcodeDecoder

type Msg
    = OnChange String
    | OnKeyDown Int
    | Submit String
    | Loading
    | GotPostcode (Result Http.Error Response)

type alias PostcodeDetails =
    { country : String
    , region : String
    }

type alias Response =
    { status : Int
    , result : PostcodeDetails}




update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        OnChange code ->
            ({ model | postCode = code }, Cmd.none)
        
        Submit code ->
            ({ model | isLoading = True}, (getPostcode code))

        OnKeyDown key ->
            if key == 13 then
                ({ model | isLoading = True}, (getPostcode model.postCode))
            else
                (model, Cmd.none)

        Loading ->
            (model, Cmd.none)

        GotPostcode result ->
            case result of
                Ok code ->
                    ({ model | isLoading = False, details = Just code}, Cmd.none)

                Err _ ->
                    ({ model | isLoading = False, details = Nothing}, Cmd.none)

onKeyDown : (Int -> msg) -> Html.Attribute msg
onKeyDown tagger =
    on "keydown" (Decode.map tagger keyCode)

view : Model -> Html Msg
view ({postCode, isLoading, details})  =
    div []
        [ input [ placeholder "Postcode", value postCode, onInput OnChange, onKeyDown OnKeyDown ] []
        , button [ onClick (Submit postCode) ] [ text "Submit" ]
        , div [] [
            if isLoading then
                text "Loading data"
            else
                text "Waiting for input"
        ]
        , case details of
            Just data ->
                div [] 
                [text data.result.country
                , text data.result.region
                ]

            Nothing ->
                div [] []
        ]


main : Program () Model Msg
main =
    Browser.element
        { init = initialModel
        , subscriptions = subscriptions
        , view = view
        , update = update
        }
 
getPostcode : String -> Cmd Msg
getPostcode code =
    Http.get
        {
            url = postcodeApiUrl ++ code
            , expect = Http.expectJson GotPostcode responseDecoder
        }