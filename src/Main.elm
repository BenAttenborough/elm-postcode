module Main exposing (main)

import Browser
import Html exposing (Html, button, input, div, text)
import Html.Events exposing (onClick)
import Html.Attributes exposing (placeholder, value)
import Html.Events exposing (onInput)
import Http
import Json.Decode exposing (Decoder, field, int)

postcodeApiUrl : String
postcodeApiUrl = "https://api.postcodes.io/postcodes/CO94LN"

type alias Model =
    { postCode : String
    , isLoading : Bool 
    , data : Maybe String }


initialModel : () -> (Model, Cmd Msg)
initialModel _ =
    ({ postCode = "" 
    , isLoading = False
    , data = Nothing
    },
    Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions _ =
  Sub.none

statusDecoder : Decoder Int
statusDecoder = 
    (field "status" int)


type Msg
    = OnChange String
    | Submit
    | Loading
    | GotPostcode (Result Http.Error String)


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        OnChange code ->
            ({ model | postCode = code }, Cmd.none)
        
        Submit ->
            ({ model | isLoading = True}, getPostcode)
        
        Loading ->
            (model, Cmd.none)

        GotPostcode result ->
            case result of
                Ok code ->
                    ({ model | isLoading = False, data = Just code}, Cmd.none)

                Err _ ->
                    ({ model | isLoading = False, data = Nothing}, Cmd.none)


view : Model -> Html Msg
view ({postCode, isLoading, data})  =
    div []
        [ input [ placeholder "Postcode", value postCode, onInput OnChange ] []
        , button [ onClick Submit ] [ text "Submit" ]
        , div [] [text postCode]
        , div [] [
            if isLoading == True then
                text "Loading data"
            else
                text "Waiting for input"
        ]
        ]


main : Program () Model Msg
main =
    Browser.element
        { init = initialModel
        , subscriptions = subscriptions
        , view = view
        , update = update
        }
 
getPostcode : Cmd Msg
getPostcode =
    Http.get
        {
            url = postcodeApiUrl
            , expect = Http.expectString GotPostcode
        }