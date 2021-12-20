import std/locks

var
  cBufferLock*: Lock
  cBufferCond*: Cond
  nimBufferLock*: Lock

  cBuffer: pointer
  cBufferSize: Natural
  nimBuffer: pointer
  nimBufferSize: Natural
  commandBuffer: pointer
  commandBufferSize: Natural
  tmpFileBuffer: pointer
  tmpFileBufferSize: Natural
  logBuffer: pointer
  logBufferSize: Natural

proc initSharedMemory*() =
  cBufferSize = 4096
  cBuffer = allocShared0(cBufferSize)
  initLock(cBufferLock)

  nimBufferSize = 4096
  nimBuffer = allocShared0(nimBufferSize)
  initLock(nimBufferLock)

  commandBufferSize = 1024
  commandBuffer = allocShared0(commandBufferSize)

  tmpFileBufferSize = 256
  tmpFileBuffer = allocShared0(tmpFileBufferSize)

  logBufferSize = 1024
  logBuffer = allocShared0(logBufferSize)

  initCond(cBufferCond)


proc cleanupSharedMemory*() =
  deallocShared(cBuffer)
  deallocShared(nimBuffer)
  deallocShared(commandBuffer)
  deallocShared(tmpFileBuffer)
  deallocShared(logBuffer)

  deinitLock(cBufferLock)
  deinitLock(nimBufferLock)

  deinitCond(cBufferCond)


proc zeroCBuffer*() =
  var cTxt: cstring = cast[cstring](cBuffer)
  cTxt[0] = '\0'


proc terminateBuffers*() =
  zeroCBuffer()
  cBufferCond.broadcast()


proc copyToCBuffer*(src: cstring) =
  let srcLen = len(src)
  if srcLen >= cBufferSize:
    cBufferSize = max(cBufferSize * 2, srcLen + 1)
    cBuffer = cBuffer.reallocShared(cBufferSize)

  copyMem(cBuffer, src, srcLen + 1)


proc getCBufferAsString*(): string =
  var cTxt: cstring = cast[cstring](shmem.cBuffer)
  return $cTxt


proc copyToCommandBuffer*(src: cstring) =
  let srcLen = len(src)
  if srcLen >= commandBufferSize:
    commandBufferSize = max(commandBufferSize * 2, srcLen + 1)
    commandBuffer = commandBuffer.reallocShared(commandBufferSize)

  copyMem(commandBuffer, src, srcLen + 1)


proc getCommandBufferAsString*(): string =
  var command: cstring = cast[cstring](shmem.commandBuffer)
  return $command


proc copyToTmpFileBuffer*(src: cstring) =
  let srcLen = len(src)
  if srcLen >= tmpFileBufferSize:
    tmpFileBufferSize = max(tmpFileBufferSize * 2, srcLen + 1)
    tmpFileBuffer = tmpFileBuffer.reallocShared(tmpFileBufferSize)

  copyMem(tmpFileBuffer, src, srcLen + 1)


proc getTmpFileBufferAsString*(): string =
  var tmpFile: cstring = cast[cstring](shmem.tmpFileBuffer)
  return $tmpFile


proc copyToNimBuffer*(srcs: string) =
  let
    src = cstring(srcs)
    srcLen = len(src)
  if srcLen >= nimBufferSize:
    nimBufferSize = max(nimBufferSize * 2, srcLen + 1)
    nimBuffer = nimBuffer.reallocShared(nimBufferSize)

  copyMem(nimBuffer, src, srcLen + 1)


proc getNimBufferAsString*(): string =
  var nim: cstring = cast[cstring](shmem.nimBuffer)
  return $nim


proc zeroNimBuffer*() =
  var nim: cstring = cast[cstring](nimBuffer)
  nim[0] = '\0'

proc copyToLogBuffer*(srcs: string) =
  let
    src = cstring(srcs)
    srcLen = len(src)
  if srcLen >= logBufferSize:
    logBufferSize = max(logBufferSize * 2, srcLen + 1)
    logBuffer = logBuffer.reallocShared(logBufferSize)

  copyMem(logBuffer, src, srcLen + 1)


proc getLogBufferAsString*(): string =
  var log: cstring = cast[cstring](shmem.logBuffer)
  return $log


proc zeroLogBuffer*() =
  var log: cstring = cast[cstring](logBuffer)
  log[0] = '\0'
