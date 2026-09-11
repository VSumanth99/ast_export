import Lake
open Lake DSL

package ast_export where
  -- Reuse the exact dependency checkouts and build artifacts used by the REPL.
  packagesDir := "../mathlib4/.lake/packages"

require mathlib from "../mathlib4"

lean_lib AstExport

/-- Returns true if we are on macOS ≥ 26.0 -/
def isMacOS26OrLater : IO Bool := do
  if !System.Platform.isOSX then
    return false
  let proc ← IO.Process.run {
    cmd := "sw_vers"
    args := #["-productVersion"]
  }
  let version := proc.trim
  -- crude but sufficient: check major version ≥ 26
  match version.splitOn "." with
  | major :: _ =>
      match major.toNat? with
      | some n => return n ≥ 26
      | none   => return false
  | _ => return false

@[default_target]
lean_exe «ast-export» where
  root := `Main
  -- Enables the use of the Lean interpreter by the executable (e.g.,
  -- `runFrontend`) at the expense of increased binary size on Linux.
  -- Remove this line if you do not need such functionality.
  supportInterpreter := true
  -- Fix for macOS 26.0 + Lean 4.15-4.19-rc3: rename __DATA_CONST segment to avoid
  -- "dyld: __DATA_CONST segment missing SG_READ_ONLY flag" error when linked with lld
  moreLinkArgs := run_io do
    if (← isMacOS26OrLater) then
      return #["-Wl,-rename_segment,__DATA_CONST,__DATA"]
    else
      return #[]
