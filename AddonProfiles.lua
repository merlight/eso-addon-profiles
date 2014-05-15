AddonProfiles = {
    name = "AddonProfiles",
    savedVariables,
    defaultSavedVariables = {
		-- todo put something here
    },
	addons = {},
	addonTitleSortIndexes = {},
	sliderValue = 1,
	profiles = {
		[1] = {
			disable = {"HarvensProvisioningTooltips", "Alchemist"},
		},
	},
    checkboxes = {}
}

local AddOnManager = GetAddOnManager()

local function DisableAnyAddonsThatShouldBeDisabled(index)
    local disabled = {}

    for _,addonName in pairs(AddonProfiles.profiles[index].disable) do
        AddOnManager:SetAddOnEnabled(AddonProfiles.addons[addonName].index, false)
        disabled[addonName] = true
        d("Disabling addon: "..addonName)
    end

    return disabled
end

local function EnableAnyAddonsThatShouldNotBeDisabled(disabled)
    for addonName,_ in pairs(AddonProfiles.addons) do
        if not disabled[addonName] then
            AddOnManager:SetAddOnEnabled(AddonProfiles.addons[addonName].index, true)
        end
    end
end

local function ActivateProfile(index)
	if AddonProfiles.profiles[index] then
        local disabled = DisableAnyAddonsThatShouldBeDisabled(index)
        EnableAnyAddonsThatShouldNotBeDisabled(disabled)
        -- todo reloadui call?
        -- todo keybinding?
    else
        d("Profile #"..index.." is not initialized, please configure it in the settings menu")
	end
end

local function PopulateUnsortedAddons()
    local numberOfAddons = AddOnManager:GetNumAddOns()
    for i = 1, numberOfAddons do
        local name, title, _, _, enabled, _, _ = AddOnManager:GetAddOnInfo(i)
        AddonProfiles.addons[name] = {name=name, title=title, enabled=enabled, index=i}
    end
end

local function PopulateSortedAddonIndex()
    for name,_ in pairs(AddonProfiles.addons) do
        AddonProfiles.addonTitleSortIndexes[#AddonProfiles.addonTitleSortIndexes+1] = name
    end

    table.sort(AddonProfiles.addonTitleSortIndexes, function (a, b)
        return string.lower(AddonProfiles.addons[a].title) < string.lower(AddonProfiles.addons[b].title)
    end)
end

local function PopulateAddonList()
    PopulateUnsortedAddons()
    PopulateSortedAddonIndex()
end

local function GetAddonIndexKeyAndDisabledState(addonName)
	local disabled = false
	local keyIndex
	for k,v in pairs(AddonProfiles.profiles[1].disable) do
		if v == addonName then
			disabled = true
			keyIndex = k
			break
		end
	end
	return keyIndex, disabled
end

local function BuildAddonMenu()
	local LAM = LibStub:GetLibrary("LibAddonMenu-1.0")
    local panelId = LAM:CreateControlPanel(AddonProfiles.name.."ControlPanel", "Addon Profiles")
    LAM:AddHeader(panelId, AddonProfiles.name.."ControlPanelHeader", "By Marihk")

	LAM:AddSlider(panelId, AddonProfiles.name.."Slider", "Profile to edit:", nil, 1, 5, 1,
		function() return AddonProfiles.sliderValue end,
		function(value)
			AddonProfiles.sliderValue = value
			-- todo update checkbox states to reflect changed profile
		end
	)

	LAM:AddHeader(panelId, AddonProfiles.name.."ProfileHeader", "Editing Profile #"..1)

	local sortIndexes = AddonProfiles.addonTitleSortIndexes
	for i=1, #sortIndexes do
		local addonName = AddonProfiles.addons[sortIndexes[i]].name
		local checkbox = LAM:AddCheckbox(panelId,
			AddonProfiles.name..i.."Checkbox",
			AddonProfiles.addons[sortIndexes[i]].title,
			nil,
			function()
				local _, disabled = GetAddonIndexKeyAndDisabledState(addonName)
				return not disabled
			end,
			function()
				local keyIndex, disabled = GetAddonIndexKeyAndDisabledState(addonName)
				if disabled then
					-- remove the entry from 'disable'
					AddonProfiles.profiles[1].disable[keyIndex] = nil
				else
					-- add the entry to 'disable'
					AddonProfiles.profiles[1].disable[#AddonProfiles.profiles[1].disable+1] = addonName
				end
			end
		)
        AddonProfiles.checkboxes[#AddonProfiles.checkboxes+1] = {checkbox}
	end
end

local function onLoad(_, name)
    if name ~= AddonProfiles.name then return end
    EVENT_MANAGER:UnregisterForEvent(AddonProfiles.name, EVENT_ADD_ON_LOADED);
	PopulateAddonList()
	BuildAddonMenu()

	SLASH_COMMANDS["/addonprofiles"] = function (args)
		if args == "show" then BuildAddonMenu() end

		local profileNumber = tonumber(args)
		if profileNumber and profileNumber > 0 and profileNumber < 6 then
			ActivateProfile(profileNumber)
		end

		if #args == 0 or args == "help" then
			d("Addon Profiles: /addonprofiles #, where # is a profile number from 1 to 5")
		end
	end
end

EVENT_MANAGER:RegisterForEvent(AddonProfiles.name, EVENT_ADD_ON_LOADED, onLoad)
