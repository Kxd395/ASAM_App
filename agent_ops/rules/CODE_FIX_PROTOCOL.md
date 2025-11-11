# CODE_FIX_PROTOCOL

## Purpose
Mandatory protocol for all code fixes to prevent cascading errors and ensure complete resolution.

## Problem Statement
When fixing compile errors, the agent must verify that the fix doesn't introduce NEW errors in related code. A fix is NOT complete until ALL downstream impacts are checked and resolved.

---

## MANDATORY PRE-FIX CHECKLIST

Before applying any code fix, the agent MUST:

### 1. Read Full Context
- Read at least 20-30 lines around the error location
- Understand the function/class/struct being modified
- Identify all dependencies and usages

### 2. Check Property/Type Definitions
- If fixing property access (e.g., `checksum.hash`), read the struct/class definition
- Verify the correct property name exists
- Check property types match expected usage

### 3. Identify Related Code
- Search for all usages of the type/function being modified
- Check for extensions, protocols, or related views
- Look for duplicate declarations across files

### 4. Verify Imports
- Ensure required modules are imported (Foundation, Combine, SwiftUI, etc.)
- Check if types referenced are in scope

---

## MANDATORY POST-FIX VERIFICATION

After applying a fix, the agent MUST:

### 1. Read Back Modified Code
- Use `read_file` to verify the exact changes made
- Confirm no syntax errors were introduced

### 2. Check Cascade Errors
- Review ALL lint errors returned by the tool
- Identify if NEW errors appeared in the same file
- Identify if NEW errors appeared in related files

### 3. Fix Cascade Errors IMMEDIATELY
- Do NOT report success if new errors appear
- Fix all related errors in the same response
- Continue until ALL errors in the affected area are resolved

### 4. Document Dependencies
- Note which files/types depend on the fix
- Check if those dependencies need updates

---

## ERROR PATTERNS & REQUIRED CHECKS

### Pattern 1: Property/Member Access Errors
**Error**: `Value of type 'X' has no member 'Y'`

**Required Checks**:
1. ✅ Read the struct/class definition of type X
2. ✅ Find the correct property name
3. ✅ Check property type matches usage
4. ✅ Search for ALL usages of that property in the codebase
5. ✅ Fix ALL usages, not just the reported error

**Example**: `checksum.hash` → Must check RulesChecksum definition, find it's actually `sha256`, fix ALL places that use `checksum.hash`

### Pattern 2: Type Not Found Errors
**Error**: `Cannot find type 'X' in scope`

**Required Checks**:
1. ✅ Search for where type X is defined
2. ✅ Check if file defining X is in Xcode targets
3. ✅ Add missing `import` statement if needed
4. ✅ Verify access level (public/internal/private)
5. ✅ Check for naming conflicts or duplicate definitions

### Pattern 3: Access Level Errors
**Error**: `'X' is inaccessible due to 'private' protection level`

**Required Checks**:
1. ✅ Read the declaration showing the access level
2. ✅ Determine if access should be elevated or if a public wrapper is needed
3. ✅ Check if there's already a public API available
4. ✅ Add public wrapper method if appropriate (don't blindly make things public)

**Example**: `initialize` is private → Add public `reinitialize()` method that calls it, don't just make `initialize` public

### Pattern 4: Duplicate Declaration Errors
**Error**: `Invalid redeclaration of 'X'`

**Required Checks**:
1. ✅ Search for ALL files containing the declaration
2. ✅ Use `file_search` to find duplicate files (e.g., `X.swift` and inline in `Y.swift`)
3. ✅ Determine which is the canonical definition
4. ✅ Remove duplicates and update references
5. ✅ Check for numbered duplicates (file "2.swift", "3.swift")

### Pattern 5: Contextual Reference Errors
**Error**: `Cannot infer contextual base in reference to member 'X'`

**Required Checks**:
1. ✅ Check if shorthand syntax (`.member`) is being used
2. ✅ Determine the type that should be inferred
3. ✅ Add explicit type name (`TypeName.member`) if inference fails
4. ✅ Verify the member exists on that type

**Example**: `.main` → `Bundle.main` when Bundle can't be inferred

---

## RESPONSE FORMAT

When fixing errors, the agent MUST structure responses as:

```
I found [N] errors in the file. I'll fix them all:

1. **Error**: [describe the error]
   **Root Cause**: [explain why it's happening]
   **Fix**: [describe the fix]

2. **Error**: [second error]
   **Root Cause**: [explanation]
   **Fix**: [fix]

[Apply all fixes using tools]

✅ All [N] errors in [filename] should now be resolved.
```

### NEVER Say:
- ❌ "Try building again and let me know the next error"
- ❌ "The error should be fixed now" (when new errors appeared)
- ❌ "I fixed [X] but there are new errors" (fix them now!)

### ALWAYS Say:
- ✅ "I found 3 errors in this file. Fixing all of them now..."
- ✅ "The fix revealed 2 additional errors. Resolving those as well..."
- ✅ "All errors in [filename] are now resolved"

---

## WORKFLOW ENFORCEMENT

### Before ANY Code Edit:
```
1. Read file context (20-30 lines minimum)
2. Search for type/property definitions
3. Check for related usages
4. Identify potential cascade errors
```

### After ANY Code Edit:
```
1. Review all lint errors from tool response
2. If NEW errors appeared → Fix them immediately
3. Read back the modified code
4. Confirm no syntax issues
```

### When Multiple Errors Exist:
```
1. Group errors by file
2. Fix all errors in File A before moving to File B
3. Use parallel tool calls when fixing independent errors
4. Verify each file is clean before proceeding
```

---

## ANTI-PATTERNS (PROHIBITED)

### ❌ PROHIBITED: Partial Fixes
```
DON'T: Fix error #1, tell user to rebuild, wait for error #2
DO: Fix errors #1, #2, #3 all at once if they're in the same file
```

### ❌ PROHIBITED: Ignoring Cascade Errors
```
DON'T: "I added the property. The lint shows 16 new errors but try building."
DO: "I added the property. This revealed 16 related errors. Fixing those now..."
```

### ❌ PROHIBITED: Blind Fixes Without Context
```
DON'T: Change `hash` to `sha256` without checking the struct definition
DO: Read RulesChecksum definition, confirm `sha256` exists, then fix
```

### ❌ PROHIBITED: Assuming Success
```
DON'T: "The error should be fixed"
DO: "The error is fixed" (after verification)
```

---

## SPECIAL CASES

### Working with Xcode Projects
- Remember: Files not in targets won't be found by compiler
- Use `file_search` to check for duplicate file paths
- Check for numbered duplicates (sign of manual file additions gone wrong)
- Verify folder structure matches Xcode groups

### Working with Extensions
- Extensions can't declare stored properties
- Extensions can't override members
- Check if functionality should be in main class instead
- Verify extension is in the same module or type is public

### Working with SwiftUI
- `@Published` requires `import Combine`
- `@EnvironmentObject` requires type to be `ObservableObject`
- View previews need all dependencies provided
- Sheet/navigationDestination closures must have correct signatures

### Working with Async/Await
- `@MainActor` functions must be called with `await` from non-MainActor contexts
- Private async functions can't be called from outside the class
- Task { } creates new async context
- Combine `await` with `@MainActor` when needed

---

## VERIFICATION COMMANDS

### After Fixing Type Issues:
```swift
// Check the type definition
grep_search: "struct TypeName|class TypeName"
read_file: [file containing definition]
```

### After Fixing Property Access:
```swift
// Find all usages
grep_search: "propertyName"
// Verify each usage is updated
```

### After Fixing Imports:
```swift
// Verify import is present
grep_search: "import ModuleName" in the file
```

### After Removing Duplicates:
```swift
// Verify only one definition remains
grep_search: "struct X|class X"
file_search: "**/*X.swift"
```

---

## COMPLIANCE

This protocol is MANDATORY for:
- ✅ All compile error fixes
- ✅ All lint error resolutions
- ✅ All type/property/method changes
- ✅ All refactoring operations
- ✅ All Xcode target integrations

Violations of this protocol constitute a failed run and must be corrected.

---

## INTEGRATION WITH AGENT_CONSTITUTION

This protocol extends the Agent Constitution's "Change Control" section:
- A code fix is NOT complete until cascade errors are resolved
- A run is NOT successful if it leaves new errors unfixed
- Transparency requires documenting ALL errors found and fixed, not just the first one

---

## REVISION HISTORY

- 2025-11-10: Initial protocol created in response to cascade error handling issues
- User reported: "why do you make changes and see that it come with other info needed and you say you fix but dont fix the new issue"
- Root cause: Agent was fixing error #1 but not addressing errors #2, #3, #4 revealed by the fix
