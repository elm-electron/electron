var _elm_electron$elm_electron$Native_Shell = (function () {
  var dialog = require('electron').dialog

  function runAndSucceed(work) {
    return _elm_lang$core$Native_Scheduler.nativeBinding(function (callback) {
      work()
      callback(_elm_lang$core$Task.succeed(_elm_lang$core$Native_Utils.Tuple0));
    })
  }

  // showItemInFolder: String -> Task Never ()
  function showOpenDialog() {
    return runAndSucceed(function () {
      dialog.showItemInFolder();
    })
  }

  return {
  	showItemInFolder: showItemInFolder
  };
}());
