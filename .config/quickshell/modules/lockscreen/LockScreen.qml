import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import QtQuick

Scope {
  id: root

  required property var notificationServer

  property string pendingPassword: ""
  property bool authInProgress: false
  property string statusText: "Enter password"
  property int attempts: 0
  property int failureNonce: 0
  property date lockedAt: new Date()
  property date currentTime: new Date()

  readonly property string primaryScreenName: Quickshell.screens.length > 0 ? Quickshell.screens[0].name : ""
  readonly property int lockedSeconds: sessionLock.locked ? Math.max(0, Math.floor((currentTime.getTime() - lockedAt.getTime()) / 1000)) : 0

  function lock(): bool {
    if (sessionLock.locked) {
      return true;
    }

    pendingPassword = "";
    authInProgress = false;
    statusText = "Enter password";
    attempts = 0;
    failureNonce = 0;
    lockedAt = new Date();
    currentTime = lockedAt;
    sessionLock.locked = true;
    tick.start();
    return true;
  }

  function isLocked(): bool {
    return sessionLock.locked;
  }

  function submit(password) {
    if (authInProgress || password.length === 0) {
      return;
    }

    pendingPassword = password;
    authInProgress = true;
    statusText = "Checking";

    if (!pam.start()) {
      pendingPassword = "";
      authInProgress = false;
      statusText = "Authentication unavailable";
      failureNonce += 1;
    }
  }

  function answerPam() {
    if (pam.responseRequired && pendingPassword.length > 0) {
      pam.respond(pendingPassword);
      pendingPassword = "";
    }
  }

  function fail(message) {
    pendingPassword = "";
    authInProgress = false;
    attempts += 1;
    statusText = message;
    failureNonce += 1;
    resetStatusTimer.restart();
  }

  function unlock() {
    pendingPassword = "";
    authInProgress = false;
    statusText = "Enter password";
    sessionLock.locked = false;
    tick.stop();
  }

  IpcHandler {
    target: "lock"

    function lock(): bool {
      return root.lock();
    }

    function isLocked(): bool {
      return root.isLocked();
    }
  }

  PamContext {
    id: pam

    configDirectory: "pam"
    config: "password.conf"

    onPamMessage: {
      if (pam.message.length > 0 && pam.messageIsError) {
        root.statusText = pam.message;
      }
      root.answerPam();
    }

    onCompleted: result => {
      if (result === PamResult.Success) {
        root.unlock();
      } else if (result === PamResult.MaxTries) {
        root.fail("Too many attempts");
      } else {
        root.fail("Authentication failed");
      }
    }

    onError: root.fail("Authentication error")
  }

  Timer {
    id: tick
    interval: 1000
    repeat: true
    running: false
    onTriggered: root.currentTime = new Date()
  }

  Timer {
    id: resetStatusTimer
    interval: 1200
    repeat: false
    onTriggered: {
      if (sessionLock.locked && !root.authInProgress) {
        root.statusText = "Enter password";
      }
    }
  }

  WlSessionLock {
    id: sessionLock

    locked: false

    LockSurface {
      controller: root
      notificationServer: root.notificationServer
      fullCard: root.primaryScreenName === "" || (screen && screen.name === root.primaryScreenName)
    }
  }
}
