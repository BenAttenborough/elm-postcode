module Main exposing (main)

-- import Browser.Navigation as Nav

import Browser exposing (Document, UrlRequest)
import Browser.Navigation
import Html exposing (Html, a, button, div, input, text)
import Html.Attributes exposing (class, placeholder, value)
import Html.Events exposing (keyCode, on, onClick, onInput)
import Http
import Json.Decode as Decode exposing (Decoder, string)
import Json.Decode.Pipeline exposing (required)
import RemoteData
import Task
import Url exposing (Url)
import Url.Parser exposing (Parser)


postcodeApiUrl : String
postcodeApiUrl =
    "https://api.postcodes.io/postcodes/"


type alias Model =
    { postCode : String
    , postCodeInfo : RemoteData.WebData PostcodeDetails
    , postCodeNearby : RemoteData.WebData (List PostcodeDetails)
    , navKey : Browser.Navigation.Key
    , currentRoute : Url
    }


type alias PostcodeDetails =
    { postcode : String
    , country : String
    , region : String
    }


init : () -> Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
init flags url navKey =
    let
        _ =
            Debug.log "url>" url.path

        postcodeInUrl =
            url.path
                |> String.dropLeft 1
                |> String.isEmpty
                |> not
    in
    if postcodeInUrl then
        update
            (Submit (String.dropLeft 1 url.path))
            { postCode = String.dropLeft 1 url.path
            , postCodeInfo = RemoteData.NotAsked
            , postCodeNearby = RemoteData.NotAsked
            , navKey = navKey
            , currentRoute = url
            }

    else
        ( { postCode = ""
          , postCodeInfo = RemoteData.NotAsked
          , postCodeNearby = RemoteData.NotAsked
          , navKey = navKey
          , currentRoute = url
          }
        , Cmd.none
        )



-- |> (\a -> ( a, Cmd.none ))


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


routeParser : Parser (String -> a) a
routeParser =
    Url.Parser.string


type Msg
    = OnChange String
    | OnKeyDown Int
    | Submit String
    | GotPostcode (RemoteData.WebData PostcodeDetails)
    | GotPostcodeNearby (RemoteData.WebData (List PostcodeDetails))
    | LinkClicked UrlRequest
    | UrlChanged Url


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

        LinkClicked response ->
            let
                _ =
                    Debug.log "x" "y"
            in
            ( model, Cmd.none )

        UrlChanged url ->
            let
                _ =
                    Debug.log "url" url
            in
            ( model, Cmd.none )


onKeyDown : (Int -> msg) -> Html.Attribute msg
onKeyDown tagger =
    on "keydown" (Decode.map tagger keyCode)


view : Model -> Document Msg
view model =
    { title = "Postcode finder"
    , body = [ currentView model ]
    }


currentView : Model -> Html Msg
currentView { postCode, postCodeInfo, postCodeNearby } =
    div [ class "main" ]
        [ div [ class "title" ]
            [ text "Postcode finder" ]
        , div [ class "input-controls" ]
            [ input [ placeholder "Postcode", value postCode, onInput OnChange, onKeyDown OnKeyDown ] []
            , button [ onClick (Submit postCode) ] [ text "Submit" ]
            ]
        , div [ class "postcode-results" ]
            [ div [ class "postcode-info" ]
                [ case postCodeInfo of
                    RemoteData.NotAsked ->
                        div []
                            [ text "Waiting on input" ]

                    RemoteData.Loading ->
                        div []
                            [ text "Loading postcode info" ]

                    RemoteData.Failure err ->
                        div []
                            [ text ("Error: " ++ errorToString err) ]

                    RemoteData.Success response ->
                        div []
                            [ postcodeDetailsView response ]
                ]
            , div [ class "postcode-nearby" ]
                [ case postCodeNearby of
                    RemoteData.NotAsked ->
                        div []
                            []

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
            ]
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
    Browser.application
        { init = init
        , onUrlRequest = LinkClicked
        , onUrlChange = UrlChanged
        , subscriptions = subscriptions
        , update = update
        , view = view
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
