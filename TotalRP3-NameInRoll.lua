-- RollRP3-NameInRoll.lua
-- Replace /roll system messages with Total RP 3 profile names, with robust API calls and logging

local DEBUG = true
local COLOR_CODE = "|cff00ff00" -- green
local RESET_CODE = "|r"

-- Cache globals before sandboxing
local _C_IsLoaded = _G.C_AddOns and _G.C_AddOns.IsAddOnLoaded
local _GetUnitRPName = TRP3_API and TRP3_API.register and TRP3_API.register.getUnitRPName
local _CreateFromUnit = AddOn_TotalRP3 and AddOn_TotalRP3.Player and AddOn_TotalRP3.Player.CreateFromUnit

-- Logging helper
local function Log(msg)
    if DEBUG then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffff00[RollRP3]|r " .. tostring(msg))
    end
end

Log("Initializing RollRP3-NameInRoll...")

-- Build pattern
local function buildRollPattern()
    local template = RANDOM_ROLL_RESULT or "%s rolls %d (%d-%d)"
    Log("Building roll pattern from: " .. template)
    local pat = template:gsub("([%(%)%.])", "%%%1")
    pat = pat:gsub("%%s", "(.+)")
    pat = pat:gsub("%%d", "(%%d+)")
    local full = "^" .. pat .. "$"
    Log("Roll pattern: " .. full)
    return full
end
local ROLL_PATTERN = buildRollPattern()

-- Fetch RP name robustly
local function GetRPName(unit)
    local defaultName = UnitName(unit) or "Unknown"
    Log(string.format("GetRPName for '%s', default='%s'", unit, defaultName))

    -- 1) Check if TRP3 loaded
    if not _C_IsLoaded or not _C_IsLoaded("TotalRP3") then
        Log("TotalRP3 not loaded -> defaultName")
        return defaultName
    end
    Log("TotalRP3 loaded")

    -- 2) Try low-level register API
    if _GetUnitRPName then
        local ok, rp = pcall(_GetUnitRPName, unit)
        if ok and rp and rp ~= "" then
            Log("Register API returned: " .. rp)
            return rp
        else
            Log("Register API returned empty or error: " .. tostring(rp))
        end
    else
        Log("Register API not available")
    end

    -- 3) Try high-level CreateFromUnit
    if _CreateFromUnit then
        local ok, profile = pcall(_CreateFromUnit, unit)
        if ok and profile then
            local full = profile.GetFullName and profile:GetFullName() or nil
            local short = profile.GetName and profile:GetName() or nil
            if full and full ~= "" then
                Log("CreateFromUnit full name: " .. full)
                return full
            elseif short and short ~= "" then
                Log("CreateFromUnit short name: " .. short)
                return short
            else
                Log("CreateFromUnit returned empty names")
            end
        else
            Log("CreateFromUnit error: " .. tostring(profile))
        end
    else
        Log("High-level API not available")
    end

    -- fallback
    Log("Falling back to defaultName")
    return defaultName
end

-- Chat filter
local function RollFilter(self, event, msg, ...)
    Log("RollFilter received: " .. tostring(msg))
    if not msg then return false end

    -- match
    local name, roll, min, max = msg:match(ROLL_PATTERN)
    if not name then
        Log("Pattern did not match")
        return false
    end
    Log(string.format("Parsed name=%s roll=%s range=%s-%s", name, roll, min, max))

    -- find unit
    local unit
    if name == UnitName("player") then
        unit = "player"
    else
        local prefix = IsInRaid() and "raid" or "party"
        for i=1,40 do
            local u = prefix..i
            if UnitExists(u) then
                local n, r = UnitName(u)
                local full = (r and r~="" and (n.."-"..r)) or n
                if full==name or n==name then unit=u; break end
            end
        end
    end

    local display = name
    if unit then
        local rpName = GetRPName(unit)
        if rpName ~= name then
            display = COLOR_CODE .. rpName .. RESET_CODE
        end
    end

    local out = RANDOM_ROLL_RESULT:format(display, tonumber(roll), tonumber(min), tonumber(max))
    Log("Output: " .. out)
    if self and self:GetName()=="ChatFrame1" then
        DEFAULT_CHAT_FRAME:AddMessage(out, 1,1,0)
    end
    return true
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", RollFilter)
Log("RollFilter registered.")
