-- TRP3-NameInRoll.lua
-- Replaces /roll system messages with TRP3 profile names colored by their TRP3 profile color

local RESET_CODE = "|r"

local _C_IsLoaded = _G.C_AddOns and _G.C_AddOns.IsAddOnLoaded
local _GetUnitRPName = TRP3_API and TRP3_API.register and TRP3_API.register.getUnitRPName
local _CreateFromUnit = AddOn_TotalRP3 and AddOn_TotalRP3.Player and AddOn_TotalRP3.Player.CreateFromUnit

local function buildRollPattern()
    local template = RANDOM_ROLL_RESULT or "%s rolls %d (%d-%d)"
    local pat = template:gsub("([%(%)%.])", "%%%1")
    pat = pat:gsub("%%s", "(.+)")
    pat = pat:gsub("%%d", "(%%d+)")
    return "^" .. pat .. "$"
end

local ROLL_PATTERN = buildRollPattern()

local function GetRPName(unit)
    local defaultName = UnitName(unit) or "Unknown"
    if not _C_IsLoaded or not _C_IsLoaded("TotalRP3") then return defaultName end

    if _GetUnitRPName then
        local ok, rp = pcall(_GetUnitRPName, unit)
        if ok and rp and rp ~= "" then return rp end
    end

    if _CreateFromUnit then
        local ok, profile = pcall(_CreateFromUnit, unit)
        if ok and profile then
            local full = profile.GetFullName and profile:GetFullName() or nil
            local short = profile.GetName and profile:GetName() or nil
            if full and full ~= "" then return full end
            if short and short ~= "" then return short end
        end
    end

    return defaultName
end

local function GetRPColorCode(unit)
    if _CreateFromUnit then
        local ok, profile = pcall(_CreateFromUnit, unit)
        if ok and profile and profile.GetCustomColorForDisplay then
            local clr = profile:GetCustomColorForDisplay()
            if clr then
                local hex = clr:GenerateHexColor() or "00ff00"
                return "|c" .. hex
            end
        end
    end
    return "|cff00ff00"
end

local function RollFilter(self, event, msg, ...)
    if not msg then return false end
    local name, roll, min, max = msg:match(ROLL_PATTERN)
    if not name then return false end

    local unit
    if name == UnitName("player") then
        unit = "player"
    else
        local prefix = IsInRaid() and "raid" or "party"
        for i = 1, 40 do
            local u = prefix .. i
            if UnitExists(u) then
                local n, r = UnitName(u)
                local full = (r and r ~= "" and (n .. "-" .. r)) or n
                if full == name or n == name then
                    unit = u
                    break
                end
            end
        end
    end

    local display = name
    if unit then
        local rpName = GetRPName(unit)
        if rpName ~= name then
            local colorCode = GetRPColorCode(unit)
            display = colorCode .. rpName .. RESET_CODE
        end
    end

    local out = RANDOM_ROLL_RESULT:format(display, tonumber(roll), tonumber(min), tonumber(max))
    if self and self:GetName() == "ChatFrame1" then
        DEFAULT_CHAT_FRAME:AddMessage(out, 1, 1, 0)
    end
    return true
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", RollFilter)
