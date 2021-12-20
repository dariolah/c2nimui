# Package

backend       = "c"
version       = "0.1.0"
author        = "Dario Lah"
description   = "UI for c2nim"
license       = "MIT"
srcDir        = "src"
bin           = @["c2nimui"]


# Dependencies

requires "nim >= 1.6.0"
requires "niup >= 3.30.0"

task c2nimui, "Runs c2nimui":
  exec "nim c -r src/c2nimui"
