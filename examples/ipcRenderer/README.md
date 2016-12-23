# ipcRenderer

## How to

```bash
npm install
elm-make Main.elm --output=elm.js && electron .
```

## Under the hood

### Main.js

The entry point for this example is the `main.js` file. This is where the electron ipc communication is handled.

```js
ipcMain.on('time-request', (event, arg) => {
  let t;

  if (arg['format'] == "timestamp") {
    t = Date.now().toString();
  } else {
    t = Date().toLocaleString();
  }

  event.sender.send('time-response', {
    status: "success",
    time: t
  });
});
```

In this example, we set the main process IPC listener to react on `time-request` channel events. Whenever an event comes in, it extracts the provided `format` and send back the time whether as a timestamp or a locale date string to the renderer process.

### Main.elm

On Elm side, we want to send an IPC message to the main process (as we are living in a renderer process) on the `time-request` channel, whenever a button is pressed. And we want to listen for responses from the main process on the `time-response` channel, as well as decoding them.

To do this we start by declaring our `Msg` type to provide a `Send` and an `OnResponse` messages

```elm
type Msg
  = Send String
  | OnResponse TimeResponse
```

As well as some types to represent the requests and the responses

```elm
type alias TimeRequest =
    { format : String
    }

type alias TimeResponse =
    { status : String
    , time : String
    }
```

Then we want our view to integrate two buttons to get the date back from the main process in both possible formats.
To do this we ensure the button's `onClick` emits a `Send` message with the desired date format to the update loop.

```elm
view : Model -> Html Msg
view model =
  div []
    [ h2 [] [ text model.currentTime ]
    , button [ class "btn btn-default btn-lg btn-block", onClick (Send "timestamp") ] [ text "Get timestamp" ]
    , button [ class "btn btn-default btn-lg btn-block", onClick (Send "date") ] [ text "Get date" ]
    ]
```

Here is the core of the IPC communication happening. In the update loop, when a `Send` message is processed, we will use the *elm-electron* `IpcRenderer` constructs to send the message to the main process. We do so by providing the `Electron.IpcRenderer.send` function the channel it should send the message on, and a JSON encoded message.

At this the point the message will be sent to the main process.

We also handle the `OnResponse` message by updating the model currentTime with the date we received. More about this later on.

```elm
update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Send format ->
      ( model, IPC.send "time-request" <| encodeRequest { format = format } )
    OnResponse response ->
        ( { model | currentTime = response.time }, Cmd.none )
```

Now we are able ton send messages to the main process. But how do we listen for incoming responses? You will need to use the `Electron.IpcRenderer.on` function as a subscription.

the `Electron.IpcRenderer.on` function takes a channel it should listen on, and a JSON decoder to deserialize the responses, as input.

```elm
subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch
  [ IPC.on "time-response" (Decode.map OnResponse decodeResponse)
  ]
```

In this example, we subscribe to responses incoming on the `time-response` channel, and decode them using our custom decodeResponse.

```elm
decodeResponse : Decode.Decoder TimeResponse
decodeResponse =
    Decode.object2 TimeResponse
        ("status" := Decode.string)
        ("time" := Decode.string)
```
