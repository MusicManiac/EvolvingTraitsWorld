# Disabling a CharacterTrait via Sandbox Option (StarlitLibrary)

**Mod:** StarlitLibrary — Workshop ID `3378285185`

---

## How It Works

StarlitLibrary hooks into `CharacterTraitDefinition`'s metatable and overrides `getTexture()`.
When a trait's texture returns `nil`, the character creation screen hides it from all listboxes.

It's driven by a `toggleOption` string field stored per-trait in `Traits.traitInfos`.

**Key files in the library:**
- `sandbox/Traits.lua` — shared data store (`Traits.traitInfos` table)
- `client/internal/Traits.lua` — the actual metatable hook + listbox cleanup
- `sandbox/SandboxUtils.lua` — reads `SandboxVars` by dot-separated option name

---

## Step 1 — Add a Sandbox Option

In your mod's `media/scripts/` add a boolean option:

```
option EnableMyTrait
{
    type = boolean,
    default = true,
    page = MyModPage,
    ...
}
```

---

## Step 2 — Register the Toggle in Lua

In a **client-side** Lua file:

```lua
local Traits = require("Starlit/sandbox/Traits")

local info = Traits.getOrCreateInfo("YourTraitStringHere")
-- "YourTraitStringHere" = the trait's string key (e.g. "Pluviophobia")

info.toggleOption = "YourModName.EnableMyTrait"
-- Format: "ModSandboxPrefix.OptionName" (dot-separated, no SandboxVars. prefix)
```

That's it. The library handles the rest automatically.

---

## What Happens Internally

```lua
-- client/internal/Traits.lua
function traitMetatable:getTexture()
    local info = Traits.traitInfos[self:getType()]
    if not info or info.toggleOption == "" then
        return old_getTexture(self)  -- unchanged
    end
    -- nil texture = trait hidden from all listboxes
    return SandboxUtils.getOptionValue(info.toggleOption) and old_getTexture(self) or nil
end
```

Also hooks `SandboxOptionsScreen.setSandboxVars` to call `updateTraits()` live when the
player changes settings — removes/hides the trait from `listboxTrait`, `listboxBadTrait`,
and `listboxTraitSelected` on the fly.

---

## Notes

- **Client-only feature** — `getOrCreateInfo` call must be in a `client/` Lua file.
- `Traits.traitInfos` is in shared, so it *can* be populated from shared code too, but
  the visual hiding only runs client-side.
- `addTraitToggleOption` / `addTraitCostOption` seen in `sandbox/Traits.lua` are **commented
  out** (refactored away). Just set `info.toggleOption` directly as shown above.
- StarlitLibrary must be listed as a **dependency** of your mod.

---

## Also Exists: Cost Option

Same pattern, controls the trait's point cost from a sandbox slider/enum:

```lua
local info = Traits.getOrCreateInfo("YourTraitStringHere")
info.costOption = "YourModName.TraitCostOption"
-- The sandbox option value is negated and used as the trait cost
```
