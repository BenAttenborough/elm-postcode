module Main exposing (main)

import Browser
import Html exposing (Html, button, div, input, text)
import Html.Attributes exposing (placeholder, value)
import Html.Events exposing (keyCode, on, onClick, onInput)
import Http
import Json.Decode as Decode exposing (Decoder, string)
import Json.Decode.Pipeline exposing (required, requiredAt)
import RemoteData


postcodeApiUrl : String
postcodeApiUrl =
    "https://api.postcodes.io/postcodes/"


type alias Model =
    { postCode : String
    , data : RemoteData.WebData PostcodeDetails
    }

type alias PostcodeDetails =
    { country : String
    , region : String
    }


-- type alias Response =
--     { result : PostcodeDetails
--     }

initialModel : () -> ( Model, Cmd Msg )
initialModel _ =
    ( { postCode = ""
      , data = RemoteData.NotAsked
      }
    , Cmd.none
    )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


postcodeDecoder : Decoder PostcodeDetails
postcodeDecoder =
    Decode.succeed PostcodeDetails
        |> requiredAt ["result", "country"] string
        |> requiredAt ["result", "region"] string


-- responseDecoder : Decoder Response
-- responseDecoder =
--     Decode.succeed Response
--         |> required "result" postcodeDecoder


type Msg
    = OnChange String
    | OnKeyDown Int
    | Submit String
    | GotPostcode (RemoteData.WebData PostcodeDetails)





update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnChange code ->
            ( { model | postCode = code }, Cmd.none )

        Submit code ->
            ( { model | data = RemoteData.Loading }, getPostcode code )

        OnKeyDown key ->
            if key == 13 then
                ( { model | data = RemoteData.Loading }, getPostcode model.postCode )

            else
                ( model, Cmd.none )

        GotPostcode response ->
            ( { model | data = response }
            , Cmd.none
            )


onKeyDown : (Int -> msg) -> Html.Attribute msg
onKeyDown tagger =
    on "keydown" (Decode.map tagger keyCode)


view : Model -> Html Msg
view { postCode, data } =
    div []
        [ input [ placeholder "Postcode", value postCode, onInput OnChange, onKeyDown OnKeyDown ] []
        , button [ onClick (Submit postCode) ] [ text "Submit" ]
        , div []
            []
        , case data of
            RemoteData.NotAsked ->
                text "Waiting for input"

            RemoteData.Loading ->
                text "Loading"

            RemoteData.Failure err ->
                text ("Error: " ++ errorToString err)

            RemoteData.Success response ->
                div []
                    [ text response.country
                    , text response.region
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


getPostcode : String -> Cmd Msg
getPostcode code =
    Http.get
        { url = postcodeApiUrl ++ code
        , expect = Http.expectJson (RemoteData.fromResult >> GotPostcode) postcodeDecoder
        }


errorToString : Http.Error -> String
errorToString error =
    case error of
        Http.BadUrl url ->
            "The URL " ++ url ++ " was invalid"

        Http.Timeout ->
            "Unable to reach the server, try again"

        Http.NetworkError ->
            "Unable to reach the server, check your network connection"

        Http.BadStatus 500 ->
            "The server had a problem, try again later"

        Http.BadStatus 400 ->
            "Verify your information and try again"

        Http.BadStatus _ ->
            "Unknown error"

        Http.BadBody errorMessage ->
            errorMessage
