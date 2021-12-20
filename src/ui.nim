import niup
import strformat
import std/monotimes
import std/locks
import std/tempfiles
import shmem

var
  last_edit_time_ms: int64
  text_modified: bool = false
  cText: MultiLine_t
  nimText: MultiLine_t
  commandText: Text_t
  optionsText: Text_t
  logText: MultiLine_t
  tmpFile = genTempPath("c2nim", "")

proc timer_text_cb(n: PIhandle): cint {.cdecl.} =
  let current_time_ms = int64(ticks(getMonoTime()).float / 1000000.0)

  if text_modified and current_time_ms - last_edit_time_ms > 1500:  # miliseconds
    let cCode = cText.value

    if len(cCode) == 0:
      text_modified = false
    else:
      let
        command = commandText.value
        options = optionsText.value
        fullCommand = &"{command} {tmpfile}.c {options}"

      if tryAcquire(cBufferLock):
        shmem.copyToCBuffer(cstring(cCode))
        shmem.copyToCommandBuffer(cstring(fullCommand))
        shmem.copyToTmpFileBuffer(cstring(tmpFile))
        text_modified = false
        logText.value = ""
        cBufferLock.release()
        cBufferCond.signal()

  if tryAcquire(nimBufferLock):
    let nimCode = shmem.getNimBufferAsString()
    if len(nimCode) > 0:
      nimText.value = nimcode
      shmem.zeroNimBuffer()

    let log = shmem.getLogBufferAsString()
    if len(log) > 0:
      logText.value = log
      shmem.zeroLogBuffer()

    nimBufferLock.release()

  return IUP_DEFAULT


proc valuechanged_cb(ih: PIhandle): cint {.cdecl.} =
  last_edit_time_ms = int64(ticks(getMonoTime()).float / 1000000.0)  # miliseconds
  text_modified = true

  return IUP_CONTINUE  # so dlg CBs can be processed


proc dlg_k_any_cb(ih: PIhandle, c: cint): cint {.cdecl.} =
  if iup_XkeyBase(c) == K_upperq and iup_isCtrlXkey(c):
    shmem.terminateBuffers()
    return IUP_CLOSE
  return IUP_DEFAULT


proc dlg_close_cb(ih: PIhandle): cint {.cdecl.} =
  shmem.terminateBuffers()
  return IUP_DEFAULT


proc displayUI*() =
  Open(utf8Mode = true)

  cText = MultiLine()
  cText.size(400, 200)
  cText.expand = "YES"
  cText.valuechanged_cb = valuechanged_cb

  nimText = MultiLine()
  nimText.size(400, 200)
  nimText.expand = "YES"
  nimText.readonly(true)

  commandText = Text()
  commandText.size = "100"
  commandText.value = &"~/.nimble/bin/c2nim"

  optionsText = Text()
  optionsText.expand = "YES"
  optionsText.value = "--nep1"

  logText = MultiLine()
  logText.size = "0x50"
  logText.expand = "YES"

  let dlg = Dialog(Vbox(
                    Hbox(Label("command"), commandText, Label(&" {tmpFile}.c "), optionsText),
                    Hbox(cText, nimText),
                    logText))
  dlg.title = "C2NIM"
  dlg.k_any = dlg_k_any_cb
  dlg.close_cb = dlg_close_cb

  ShowXY(dlg, IUP_CENTER, IUP_CENTER)
  SetFocus(cText)

  let timer = Timer()

  timer.time(300)
  timer.run(true)
  timer.action_cb = timer_text_cb

  MainLoop()

  Destroy(timer)

  Close()

