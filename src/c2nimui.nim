import ui
import shmem
import bgproc

proc Main() =
  shmem.initSharedMemory()
  bgproc.createThread()

  ui.displayUI()

  bgproc.joinThread()
  shmem.cleanupSharedMemory()

when isMainModule:
  Main()
