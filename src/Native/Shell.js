var _elm_electron$elm_electron$Native_Shell = (function () {
  var shell = require('electron').shell

  function runAndSucceed(work) {
    return _elm_lang$core$Native_Scheduler.nativeBinding(function (callback) {
      work()
      callback(_elm_lang$core$Task.succeed(_elm_lang$core$Native_Utils.Tuple0));
    })
  }

  // showItemInFolder: String -> Task Never ()
  function showItemInFolder(fullPath) {
    return runAndSucceed(function () {
      shell.showItemInFolder(fullPath);
    })
  }

  // openItem: String -> Task Never ()
  function openItem(fullPath) {
    return runAndSucceed(function () {
      shell.openItem(fullPath)
    })
  }

  // openExternal: String -> Task Never ()
  function openExternal(url) {
    return runAndSucceed(function () {
      shell.openExternal(url);
    })
  }

  // moveItemToTrash: String -> Task Never ()
  function moveItemToTrash(fullPath) {
    return runAndSucceed(function () {
      shell.moveItemToTrash(fullPath)
    })
  }

  // beep: Task Never ()
  var beep = runAndSucceed(function () {
    shell.beep()
  })

  return {
  	showItemInFolder: showItemInFolder,
    openItem: openItem,
    openExternal: openExternal,
    moveItemToTrash: moveItemToTrash,
    beep: beep,
  };
}());
