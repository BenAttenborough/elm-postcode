module Main exposing (main)

import Browser
import Html exposing (Html, button, input, div, text)
import Html.Events exposing (onClick)
import Html.Attributes exposing (placeholder, value)
import Html.Events exposing (onInput)


type alias Model =
    { postCode : String }


initialModel : Model
initialModel =
    { postCode = "" }


type Msg
    = Submit String


update : Msg -> Model -> Model
update msg model =
    case msg of
        Submit code ->
            { model | postCode = code }


view : Model -> Html Msg
view model =
    div []
        [ input [ placeholder "Postcode", value model.postCode, onInput Submit ] []
        , div [] [text model.postCode]
        ]


main : Program () Model Msg
main =
    Browser.sandbox
        { init = initialModel
        , view = view
        , update = update
        }
 