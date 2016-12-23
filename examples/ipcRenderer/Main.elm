import Electron.IpcRenderer as IPC exposing (on, send)

import Html exposing (Html, program, text, button, h2, div)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Json.Encode
-- import Json.Decode as Decode exposing (Decoder, map, (:=))
import Json.Decode exposing (int, string, float, nullable, map, Decoder)
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)


main =
  program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }


-- MODEL


type alias Model =
  { currentTime : String
  }


init : ( Model, Cmd Msg )
init =
  ({ currentTime = "None" }, Cmd.none)


type alias TimeRequest =
    { format : String
    }


encodeRequest : TimeRequest -> Json.Encode.Value
encodeRequest request =
    Json.Encode.object
      [ ( "format", Json.Encode.string request.format ) ]


type alias TimeResponse =
    { status : String
    , time : String
    }


decodeResponse : Decoder TimeResponse
decodeResponse =
    decode TimeResponse
        |> required "status" string
        |> required "time" string


-- UPDATE


type Msg
  = Send String
  | OnResponse TimeResponse


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Send format ->
      ( model, IPC.send "time-request" <| encodeRequest { format = format } )
    OnResponse response ->
        ( { model | currentTime = response.time }, Cmd.none )


-- VIEW


view : Model -> Html Msg
view model =
  div []
    [ h2 [] [ text model.currentTime ]
    , button [ class "btn btn-default btn-lg btn-block", onClick (Send "timestamp") ] [ text "Get timestamp" ]
    , button [ class "btn btn-default btn-lg btn-block", onClick (Send "date") ] [ text "Get date" ]
    ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch
  [ IPC.on "time-response" (map OnResponse decodeResponse)
  ]
