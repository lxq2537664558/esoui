ZO_LOOT_HISTORY_NAME = "ZO_LootHistory"

--
--[[ LootHistory_Manager ]]--
--

-- TODO: change into a callback object so that we don't have to keep using systems for the callback functions
local LootHistory_Manager = ZO_Object:Subclass()

function LootHistory_Manager:New(...)
    local lootHistory = ZO_Object.New(self)
    lootHistory:Initialize(...)
    return lootHistory
end

local function CanAddLootEntry()
    return tonumber(GetSetting(SETTING_TYPE_LOOT,LOOT_SETTING_LOOT_HISTORY)) == 1
end

do
    local IGNORED_LOOT_TYPES =
    {
        [LOOT_TYPE_ITEM] = true,
        [LOOT_TYPE_QUEST_ITEM] = true,
        [LOOT_TYPE_COLLECTIBLE] = true,
    }

    function LootHistory_Manager:Initialize()
        local function OnNewItemReceived(...)
            if CanAddLootEntry() then
                SYSTEMS:GetObject(ZO_LOOT_HISTORY_NAME):OnNewItemReceived(...)
            end
        end

        local function OnNewCollectibleReceived(collectibleId)
            if CanAddLootEntry() then
                SYSTEMS:GetObject(ZO_LOOT_HISTORY_NAME):OnNewCollectibleReceived(collectibleId)
            end
        end

        local function OnCurrencyUpdate(...)
            if CanAddLootEntry() then
                SYSTEMS:GetObject(ZO_LOOT_HISTORY_NAME):OnCurrencyUpdate(...)
            end
        end

        local function OnExperienceGainUpdate(...)
            if CanAddLootEntry() then
                SYSTEMS:GetObject(ZO_LOOT_HISTORY_NAME):OnExperienceGainUpdate(...)
            end
        end

        local function OnMedalAwarded(...)
            if CanAddLootEntry() then
                SYSTEMS:GetObject(ZO_LOOT_HISTORY_NAME):OnMedalAwarded(...)
            end
        end

        local function OnBattlegroundStateChanged(oldState, newState)
            if CanAddLootEntry() then
                if newState == BATTLEGROUND_STATE_POSTGAME then
                    SYSTEMS:GetObject(ZO_LOOT_HISTORY_NAME):OnBattlegroundEnteredPostGame()
                end
            end
        end

        local function OnInventorySlotUpdate(bagId, slotId, isNewItem, itemSound, inventoryUpdateReason, stackCountChange)
            -- This includes any inventory item update, only display if the item was new
            if isNewItem and stackCountChange > 0 then
                local itemLink = GetItemLink(bagId, slotId)

                -- cover the case where we got an inventory item update but then the item got whisked away somewhere else
                -- before we had a chance to get the info out of it
                if itemLink ~= nil and itemLink ~= "" then
                    local lootType = LOOT_TYPE_ITEM
                    local itemId = GetItemInstanceId(bagId, slotId)
                    local isVirtual = bagId == BAG_VIRTUAL
                    local isStolen = IsItemStolen(bagId, slotId)
                    OnNewItemReceived(itemLink, stackCountChange, itemSound, lootType, nil, itemId, isVirtual, isStolen)
                end
            end
        end

        local IS_NOT_VIRTUAL = false

        local function OnLootReceived(receivedBy, itemLinkOrName, stackCount, itemSound, lootType, lootedBySelf, isPickpocketLoot, questItemIcon, itemId, isStolen)
            -- This includes any loot event, only display if this was the player's loot and wasn't an inventory item
            -- OnInventorySlotUpdate() must be used for Inventory Items so that we know what bag they went into
            -- we also are going to handle quest items through the QuestToolUpdated event
            if lootedBySelf and not IGNORED_LOOT_TYPES[lootType] then
                OnNewItemReceived(itemLinkOrName, stackCount, itemSound, lootType, questItemIcon, itemId, IS_NOT_VIRTUAL, isStolen)
            end
        end

        local IS_NOT_STOLEN = false
        local function OnQuestToolUpdate(questIndex, questName, countDelta, questItemIcon, questItemId, questItemName)
            if countDelta > 0 then
                OnNewItemReceived(questItemName, countDelta, nil, LOOT_TYPE_QUEST_ITEM, questItemIcon, questItemId, IS_NOT_VIRTUAL, IS_NOT_STOLEN)
            end
        end

        EVENT_MANAGER:RegisterForEvent(ZO_LOOT_HISTORY_NAME, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, function(eventId, ...) OnInventorySlotUpdate(...) end)
        EVENT_MANAGER:RegisterForEvent(ZO_LOOT_HISTORY_NAME, EVENT_LOOT_RECEIVED, function(eventId, ...) OnLootReceived(...) end)
        EVENT_MANAGER:RegisterForEvent(ZO_LOOT_HISTORY_NAME, EVENT_CURRENCY_UPDATE, function(eventId, ...) OnCurrencyUpdate(...) end)
        EVENT_MANAGER:RegisterForEvent(ZO_LOOT_HISTORY_NAME, EVENT_EXPERIENCE_GAIN, function(eventId, ...) OnExperienceGainUpdate(...) end)
        EVENT_MANAGER:RegisterForEvent(ZO_LOOT_HISTORY_NAME, EVENT_QUEST_TOOL_UPDATED, function(eventId, ...) OnQuestToolUpdate(...) end)
        EVENT_MANAGER:RegisterForEvent(ZO_LOOT_HISTORY_NAME, EVENT_COLLECTIBLE_NOTIFICATION_NEW, function(eventId, ...) OnNewCollectibleReceived(...) end)
        EVENT_MANAGER:RegisterForEvent(ZO_LOOT_HISTORY_NAME, EVENT_MEDAL_AWARDED, function(eventId, ...) OnMedalAwarded(...) end)
        EVENT_MANAGER:RegisterForEvent(ZO_LOOT_HISTORY_NAME, EVENT_BATTLEGROUND_STATE_CHANGED, function(eventId, ...) OnBattlegroundStateChanged(...) end)
        -- TODO: wait for icons to be made before allowing skill experience from guilds to come through loot history
    end
end

ZO_LOOT_HISTORY_MANAGER = LootHistory_Manager:New()
