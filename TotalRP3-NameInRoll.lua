local f = CreateFrame("Frame")

-- Register system chat event
f:RegisterEvent("CHAT_MSG_SYSTEM")

-- Basic pattern for roll messages in English (can be localized later)
local ROLL_PATTERN = "^(.+) rolls (%d+) %((%d+)%-(%d+)%)$"

-- Chat message filter to suppress the original roll
local function SuppressRoll(_, msg, ...)
    if string.match(msg, ROLL_PATTERN) then
        return true -- suppress the original
    end
    return false
end
ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", SuppressRoll)

-- Actual handler to replace with TRP3 name
f:SetScript("OnEvent", function(_, event, msg)
    local name, roll, min, max = string.match(msg, ROLL_PATTERN)
    if not name then return end

    local isSelf = (name == "You")
    local unit = nil

    if isSelf then
        unit = "player"
    else
        -- Check all party/raid members
        for i = 1, 40 do
            local groupUnit = IsInRaid() and "raid"..i or "party"..i
            if UnitExists(groupUnit) then
                local unitName, unitRealm = UnitName(groupUnit)
                local fullName = unitRealm and unitRealm ~= "" and (unitName .. "-" .. unitRealm) or unitName
                if fullName == name then
                    unit = groupUnit
                    break
                end
            end
        end
    end

    local displayName = name -- fallback
    if unit and IsAddOnLoaded("TotalRP3") and TRP3_API and TRP3_API.register then
        local rpName = TRP3_API.register.getUnitRPName(unit)
        if rpName and rpName ~= "" then
            displayName = rpName
        end
    end

    local out = string.format("%s rolls %s (%s-%s)", displayName, roll, min, max)
    SendSystemMessage(out)
end)
