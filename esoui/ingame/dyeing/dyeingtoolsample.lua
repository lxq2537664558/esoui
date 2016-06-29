ZO_DyeingToolSample = ZO_DyeingToolBase:Subclass()

function ZO_DyeingToolSample:New(...)
    return ZO_DyeingToolBase.New(self, ...)
end

function ZO_DyeingToolSample:Initialize(owner)
   ZO_DyeingToolBase.Initialize(self, owner)
end

function ZO_DyeingToolSample:Activate(fromTool, suppressSounds)
    if fromTool and not suppressSounds then
        PlaySound(SOUNDS.DYEING_TOOL_SAMPLE_SELECTED)
    end
end

function ZO_DyeingToolSample:HasSwatchSelection()
    return false
end

function ZO_DyeingToolSample:OnLeftClicked(dyeableSlot, dyeChannel)
    local dyeDefId = select(dyeChannel, GetPendingSlotDyes(dyeableSlot))
    if dyeDefId then
        local _, known = GetDyeDefInfoById(dyeDefId)
        local isPlayerDye = self.owner:DoesDyeDefIdExistInPlayerDyes(dyeDefId)
        if known and isPlayerDye then
            local SUPPRESS_SOUNDS = true
            self.owner:SwitchToDyeingWithDyeDefId(dyeDefId, SUPPRESS_SOUNDS)
            PlaySound(SOUNDS.DYEING_TOOL_SAMPLE_USED)
        elseif not isPlayerDye then
            ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.GENERAL_ALERT_ERROR, SI_DYEING_CANNOT_SAMPLE_NON_PLAYER_DYE)
        elseif not known then
            ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.GENERAL_ALERT_ERROR, SI_DYEING_CANNOT_SAMPLE_LOCKED_DYE)
        end
    else
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.GENERAL_ALERT_ERROR, SI_DYEING_CANNOT_SAMPLE)
    end
end

function ZO_DyeingToolSample:OnSavedSetLeftClicked(dyeSetIndex, dyeChannel)
    local dyeIndex = select(dyeChannel, GetSavedDyeSetDyes(dyeSetIndex))
    if dyeIndex then
        local SUPPRESS_SOUNDS = true
        self.owner:SwitchToDyeingWithDyeDefId(dyeIndex, SUPPRESS_SOUNDS)
        PlaySound(SOUNDS.DYEING_TOOL_SAMPLE_USED)
    else
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.GENERAL_ALERT_ERROR, SI_DYEING_CANNOT_SAMPLE)
    end
end

function ZO_DyeingToolSample:GetCursorType(dyeableSlot, dyeChannel)
    return MOUSE_CURSOR_SAMPLE
end
