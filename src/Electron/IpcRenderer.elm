effect module Electron.IpcRenderer
    where { subscription = MySub, command = MyCmd }
    exposing
        ( on
        , send
        )

{-|
# Subscriptions
@docs on, send
-}

import Platform exposing (Router)
import Native.IpcRenderer
import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder, Value)
import Process
import Task exposing (Task)


{-| Subscribe to an event incoming over ipcRenderer
-}
on : String -> Decoder msg -> Sub msg
on eventName decoder =
    subscription (On eventName decoder)


{-| Send a value over ipcRenderer
-}
send : String -> Value -> Cmd msg
send eventName value =
    command (Send eventName value)


type MySub msg
    = On String (Decoder msg)


subMap : (a -> b) -> MySub a -> MySub b
subMap mapper (On eventName decoder) =
    On eventName <| Decode.map mapper decoder


type MyCmd msg
    = Send String Value


cmdMap : (a -> b) -> MyCmd a -> MyCmd b
cmdMap _ (Send eventName value) =
    Send eventName value


type alias State msg =
    Dict String (Watcher msg)


type alias Watcher msg =
    { decoders : List (Decoder msg)
    , pid : Process.Id
    }


type alias SubDict msg =
    Dict String (List (Decoder msg))


categorize : List (MySub msg) -> SubDict msg
categorize subs =
    categorizeHelp subs Dict.empty


categorizeHelp : List (MySub msg) -> SubDict msg -> SubDict msg
categorizeHelp subs subDict =
    case subs of
        [] ->
            subDict

        (On eventName decoder) :: rest ->
            categorizeHelp rest
                <| Dict.update eventName (categorizeHelpHelp decoder) subDict


categorizeHelpHelp : a -> Maybe (List a) -> Maybe (List a)
categorizeHelpHelp value maybeValues =
    case maybeValues of
        Nothing ->
            Just [ value ]

        Just values ->
            Just (value :: values)


init : Task Never (State msg)
init =
    Task.succeed Dict.empty


type alias Msg =
    { eventName : String
    , value : Value
    }


andThen : (a -> Task b c) -> Task b a -> Task b c
andThen =
    flip Task.andThen


onWatcherEffects :
    Router msg Msg
    -> List (MySub msg)
    -> Dict String (Watcher msg)
    -> Task Never (Dict String (Watcher msg))
onWatcherEffects router newSubs oldState =
    let
        leftStep eventName watcher task =
            watcher.pid
                |> Process.kill
                |> andThen (always task)

        bothStep eventName watcher decoders task =
            task
                `Task.andThen` \state ->
                                Task.succeed (Dict.insert eventName ({ watcher | decoders = decoders }) state)

        rightStep eventName decoders task =
            task
                `Task.andThen` \state ->
                                Process.spawn (Native.IpcRenderer.on eventName (Platform.sendToSelf router << Msg eventName))
                                    `Task.andThen` \pid ->
                                                    Task.succeed (Dict.insert eventName (Watcher decoders pid) state)
    in
        Dict.merge leftStep
            bothStep
            rightStep
            oldState
            (categorize newSubs)
            (Task.succeed Dict.empty)


onEffects :
    Router msg Msg
    -> List (MyCmd msg)
    -> List (MySub msg)
    -> State msg
    -> Task Never (State msg)
onEffects router newCmds newSubs oldState =
    let
        updatedForWatchers =
            onWatcherEffects router newSubs oldState

        runCommand (Send eventName value) =
            Native.IpcRenderer.send eventName value

        runCommands =
            newCmds
                |> List.map runCommand
                |> Task.sequence
    in
        runCommands
            |> andThen (always updatedForWatchers)


onSelfMsg : Router msg Msg -> Msg -> State msg -> Task Never (State msg)
onSelfMsg router msg state =
    case Dict.get msg.eventName state of
        Nothing ->
            Task.succeed state

        Just watcher ->
            let
                send decoder =
                    msg.value
                        |> Decode.decodeValue decoder
                        |> Result.map (Platform.sendToApp router)
                        |> Result.toMaybe
            in
                Task.sequence (List.filterMap send watcher.decoders)
                    `Task.andThen` (always (Task.succeed state))
