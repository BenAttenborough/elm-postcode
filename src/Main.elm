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
    , postCodeInfo : RemoteData.WebData PostcodeDetails
    , postCodeNearby : RemoteData.WebData (List PostcodeDetails)
    }


type alias PostcodeDetails =
    { postcode : String
    , country : String
    , region : String
    }


initialModel : () -> ( Model, Cmd Msg )
initialModel _ =
    ( { postCode = ""
      , postCodeInfo = RemoteData.NotAsked
      , postCodeNearby = RemoteData.NotAsked
      }
    , Cmd.none
    )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


postcodeDecoder : Decoder PostcodeDetails
postcodeDecoder =
    Decode.succeed PostcodeDetails
        |> required "postcode" string
        |> required "country" string
        |> required "region" string


postcodeResultDecoder : Decoder PostcodeDetails
postcodeResultDecoder =
    Decode.field "result" postcodeDecoder


postcodeNearbyDecoder : Decoder (List PostcodeDetails)
postcodeNearbyDecoder =
    Decode.field "result" (Decode.list postcodeDecoder)


type Msg
    = OnChange String
    | OnKeyDown Int
    | Submit String
    | GotPostcode (RemoteData.WebData PostcodeDetails)
    | GotPostcodeNearby (RemoteData.WebData (List PostcodeDetails))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnChange code ->
            ( { model | postCode = code }, Cmd.none )

        Submit code ->
            ( { model
                | postCodeInfo = RemoteData.Loading
                , postCodeNearby = RemoteData.Loading
              }
            , Cmd.batch
                [ getPostcodeInfo code
                , getPostcodeNearby code
                ]
            )

        OnKeyDown key ->
            if key == 13 then
                ( { model | postCodeInfo = RemoteData.Loading }
                , Cmd.batch
                    [ getPostcodeInfo model.postCode
                    , getPostcodeNearby model.postCode
                    ]
                )

            else
                ( model, Cmd.none )

        GotPostcode response ->
            ( { model | postCodeInfo = response }
            , Cmd.none
            )

        GotPostcodeNearby response ->
            ( { model | postCodeNearby = response }
            , Cmd.none
            )


onKeyDown : (Int -> msg) -> Html.Attribute msg
onKeyDown tagger =
    on "keydown" (Decode.map tagger keyCode)


view : Model -> Html Msg
view { postCode, postCodeInfo, postCodeNearby } =
    div []
        [ input [ placeholder "Postcode", value postCode, onInput OnChange, onKeyDown OnKeyDown ] []
        , button [ onClick (Submit postCode) ] [ text "Submit" ]
        , div []
            []
        , case postCodeInfo of
            RemoteData.NotAsked ->
                text "Waiting for input"

            RemoteData.Loading ->
                text "Loading postcode info"

            RemoteData.Failure err ->
                text ("Error: " ++ errorToString err)

            RemoteData.Success response ->
                postcodeDetailsView response
        , case postCodeNearby of
            RemoteData.NotAsked ->
                div []
                    [ text "Waiting for input" ]

            RemoteData.Loading ->
                div []
                    [ text "Loading nearby postcodes" ]

            RemoteData.Failure err ->
                div []
                    [ text ("Error: " ++ errorToString err) ]

            RemoteData.Success response ->
                div []
                    (List.map
                        postcodeNearbyView
                        response
                        |> List.append
                            [ text "Nearby postcodes:" ]
                    )
        ]


postcodeDetailsView : PostcodeDetails -> Html Msg
postcodeDetailsView details =
    div []
        [ div []
            [ text ("Country: " ++ details.country) ]
        , div []
            [ text ("Region: " ++ details.region) ]
        ]


postcodeNearbyView : PostcodeDetails -> Html Msg
postcodeNearbyView details =
    div []
        [ div []
            [ text ("Postcode: " ++ details.postcode) ]
        , div []
            [ text ("Country: " ++ details.country) ]
        , div []
            [ text ("Region: " ++ details.region) ]
        ]


main : Program () Model Msg
main =
    Browser.element
        { init = initialModel
        , subscriptions = subscriptions
        , view = view
        , update = update
        }


getPostcodeInfo : String -> Cmd Msg
getPostcodeInfo code =
    Http.get
        { url = postcodeApiUrl ++ code
        , expect = Http.expectJson (RemoteData.fromResult >> GotPostcode) postcodeResultDecoder
        }


getPostcodeNearby : String -> Cmd Msg
getPostcodeNearby code =
    Http.get
        { url = postcodeApiUrl ++ code ++ "/nearest"
        , expect = Http.expectJson (RemoteData.fromResult >> GotPostcodeNearby) postcodeNearbyDecoder
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
