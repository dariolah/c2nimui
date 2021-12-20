import std/locks
import osproc
import shmem
import strformat

var c2nim_thread: Thread[void]

proc execute_c2nim(cTxt: string) =
    let tmpFile = shmem.getTmpFileBufferAsString()
    writeFile(&"{tmpFile}.c", cTxt)
    let (output, exitCode) = execCmdEx(shmem.getCommandBufferAsString())
    shmem.copyToLogBuffer(output)

    if exitCode == 0:
      let nimCode = readFile(&"{tmpFile}.nim")
      withLock shmem.nimBufferLock:
        shmem.copyToNimBuffer(nimCode)


proc execute_c2nim_thread() {.thread.} =
  while true:
    withLock shmem.cBufferLock:
      cBufferCond.wait(shmem.cBufferLock)

      var cTxt = shmem.getCBufferAsString()
      if len(cTxt) == 0:
        # empty buffer, end thread
        break

      execute_c2nim(cTxt)

      # zero buffer after processing
      shmem.zeroCBuffer()

proc createThread*() =
  createThread(c2nim_thread, bgproc.execute_c2nim_thread)

proc joinThread*() =
  joinThread(c2nim_thread)
