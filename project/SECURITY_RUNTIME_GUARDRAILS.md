# Security Runtime Guardrails

**Policy Version**: 1.0
**Project**: Spellloop
**Goal**: Zero tolerance for debug/test leaks in production.

## 1. Forbidden Paths
The following directories and files MUST NOT be referenced by Runtime code (Production Scenes, Core Scripts, UI):

- `res://scripts/tests/*`
- `res://scripts/debug/*` (Exception: `PerfTracker` via Autoload if configured safely)
- `res://tests/*`
- `res://debug/*`

## 2. Forbidden Symbols
Usage of the following classes/resources in Runtime is prohibited:

- `ItemTestRunner`
- `StructureValidator`
- `TestRunner`
- `CalibrationSuite`
- `StressTest`

## 3. Tooling Enforcement
The `DependencyScanner.gd` tool enforces this policy during CI/Build.

### Run Compliance Check
```powershell
godot --headless -s scripts/tools/DependencyScanner.gd --path "c:\git\spellloop\project"
```

### Exit Codes
- `0`: Compliant.
- `1`: Violation detected.

## 4. Troubleshooting
If the build fails due to security violation:
1. Check the logs for `[SECURITY VIOLATION]`.
2. Locate the file referencing a forbidden path (e.g., a `preload` in a UI script).
3. **Fix**: Remove the dependency. Use strict separation. If logic is needed, move it to `scripts/core`.
