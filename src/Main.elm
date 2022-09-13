module Main exposing (main)

import Browser
import Html exposing (Html, button, input, div, text)
import Html.Events exposing (onClick)
import Html.Attributes exposing (placeholder, value)
import Html.Events exposing (onInput)
import Http
import Json.Decode exposing (Decoder, map4, field, int, string)

type alias Model =
    { postCode : String
    , isLoading : Bool }


initialModel : () -> (Model, Cmd Msg)
initialModel _ =
    ({ postCode = "" 
    , isLoading = True
    },
    Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions _ =
  Sub.none


type Msg
    = OnChange String
    | Submit
    | Loading
    -- | GotPostcode (Result Http.Error Response)


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        OnChange code ->
            ({ model | postCode = code }, Cmd.none)
        
        Submit ->
            (model, Cmd.none)
        
        Loading ->
            (model, Cmd.none)

        -- GotPostcode ->
        --     (model, Cmd.none)

view : Model -> Html Msg
view ({postCode, isLoading})  =
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
 