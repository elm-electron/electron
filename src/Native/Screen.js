var _elm_electron$elm_electron$Native_Screen = (function () {
  var electronScreen = require('electron').screen;

  function onDisplaysChanged(decoder, toTask) {
		return _elm_lang$core$Native_Scheduler.nativeBinding(function (callback) {

			function performTask() {
        var displays = electronScreen.getDisplays();
        var result = _elm_lang$core$Native_Json.run(decoder, displays);
        if (result.ctor === 'Ok') {
          _elm_lang$core$Native_Scheduler.rawSpawn(toTask(result));
        }
			}

			electronScreen.on('display-added', performTask);
      electronScreen.on('display-removed', performTask);
      electronScreen.on('display-metrics-changed', performTask);

      performTask();

			return function () {
        electronScreen.removeListener('display-added', performTask);
        electronScreen.removeListener('display-removed', performTask);
        electronScreen.removeListener('display-metrics-changed', performTask);
      };
		});
  }

  return {
  	onDisplaysChanged: F2(onDisplaysChanged)
  };
}());
