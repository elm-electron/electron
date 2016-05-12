effect module Electron.Screen where { subscription = MySub } exposing
  ( displays
  , Rect
  , TouchSupport(..)
  , Display
  )

{-|
# Subscriptions
@docs displays

# Types
@docs Rect, TouchSupport, Display
-}

import Platform exposing (Router)
import Json.Decode as Decode exposing (Decoder, Value, (:=))
import Process
import Task exposing (Task)
import Native.Screen


{-| Subscribe to changes in the state of the user's available displays
-}
displays : (List Display -> msg) -> Sub msg
displays toMsg =
  subscription <| Displays toMsg


(|:) : Decoder (a -> b) -> Decoder a -> Decoder b
(|:) =
  Decode.object2 (<|)


{-| Denotes whether a display supports touch interactions and whether that
capability is even known.
-}
type TouchSupport
  = Available
  | Unavailable
  | Unknown


decodeTouchSupport : Decoder TouchSupport
decodeTouchSupport =
  let
    parse value =
      case value of
        "available" ->
          Ok Available
        "unavailable" ->
          Ok Unavailable
        "unknown" ->
          Ok Unknown
        _ ->
          Err ("Unknown TouchSupport type: " ++ value)
  in
    Decode.customDecoder Decode.string parse


{-| Describes an area of the screen in pixels
-}
type alias Rect =
  { x : Int
  , y : Int
  , width : Int
  , height : Int
  }


decodeRect : Decoder Rect
decodeRect =
  Decode.succeed Rect
    |: ("x" := Decode.int)
    |: ("y" := Decode.int)
    |: ("width" := Decode.int)
    |: ("height" := Decode.int)


{-| All available information about a user's display
-}
type alias Display =
  { id : Int
  , rotation : Int
  , scaleFactor : Float
  , touchSupport : TouchSupport
  , bounds : Rect
  , workArea : Rect
  , workAreaSize : Rect
  }


decodeDisplay : Decoder Display
decodeDisplay =
  Decode.succeed Display
    |: ("id" := Decode.int)
    |: ("rotation" := Decode.int)
    |: ("scaleFactor" := Decode.float)
    |: ("touchSupport" := decodeTouchSupport)
    |: ("bounds" := decodeRect)
    |: ("workArea" := decodeRect)
    |: ("workAreaSize" := decodeRect)


type alias Watcher a =
  { pid : Process.Id
  , listeners : List a
  }


type MySub msg
  = Displays (List Display -> msg)


subMap : (a -> b) -> MySub a -> MySub b
subMap mapper (Displays toMsg) =
  Displays (toMsg >> mapper)


type alias State msg =
  { displays : Maybe (Watcher (List Display -> msg))
  }


init : Task Never (State msg)
init =
  Task.succeed { displays = Nothing }


type Msg =
  DisplaysMsg (List Display)


andThen : (a -> Task b c) -> Task b a -> Task b c
andThen =
  flip Task.andThen


onDisplaysEffects
  : Router msg Msg
  -> (List (List Display -> msg))
  -> Maybe (Watcher (List Display -> msg))
  -> Task Never (Maybe (Watcher (List Display -> msg)))
onDisplaysEffects router newListeners maybeWatcher =
  case (newListeners, maybeWatcher) of
    ([], Nothing) ->
      Task.succeed Nothing

    ([], Just watcher) ->
      Process.kill watcher.pid
        |> Task.map (always Nothing)

    (subs, Nothing) ->
      Process.spawn (Native.Screen.onDisplaysChanged (Decode.list decodeDisplay) (DisplaysMsg >> Platform.sendToSelf router))
        |> andThen (\pid -> (Task.succeed (Just (Watcher pid subs))))

    (subs, Just watcher) ->
      Task.succeed <| Just { watcher | listeners = subs }


subsToDisplayListeners : List (MySub msg) -> List (List Display -> msg)
subsToDisplayListeners subs =
  let
    extractListener sub =
      case sub of
        Displays listener ->
          Just listener
  in
    List.filterMap extractListener subs


onEffects
  : Router msg Msg
  -> List (MySub msg)
  -> State msg
  -> Task Never (State msg)
onEffects router newSubs oldState =
  onDisplaysEffects router (subsToDisplayListeners newSubs) oldState.displays
    |> andThen (\maybeWatcher -> Task.succeed { oldState | displays = maybeWatcher })


sendDisplaysMsg : Router msg Msg -> List Display -> (List Display -> msg) -> Task Never ()
sendDisplaysMsg router latestDisplays listener =
  Platform.sendToApp router (listener latestDisplays)


onSelfMsg : Router msg Msg -> Msg -> State msg -> Task Never (State msg)
onSelfMsg router msg state =
  case msg of
    DisplaysMsg displays ->
      state.displays
        |> Maybe.map (\watcher -> Task.sequence <| List.map (sendDisplaysMsg router displays) watcher.listeners)
        |> Maybe.map (\task -> Task.map (always state) task)
        |> Maybe.withDefault (Task.succeed state)
