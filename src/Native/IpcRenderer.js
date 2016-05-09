var _elm_electron$elm_electron$Native_IpcRenderer = (function () {
  var ipcRenderer = require('electron').ipcRenderer;

  function on(eventName, toTask) {
		return _elm_lang$core$Native_Scheduler.nativeBinding(function (callback) {
			function performTask(event, value) {
				_elm_lang$core$Native_Scheduler.rawSpawn(toTask(value));
			}

			ipcRenderer.on(eventName, performTask);

			return function () {
				ipcRenderer.removeListener(eventName, performTask);
			};
		});
  }

  function send(eventName, value) {
  	return _elm_lang$core$Native_Scheduler.nativeBinding(function (callback) {
      ipcRenderer.send(eventName, value);
  		callback(_elm_lang$core$Native_Scheduler.succeed(_elm_lang$core$Native_Utils.Tuple0));
  	});
  }

  return {
  	on: F2(on),
    send: F2(send),
  };
}());
