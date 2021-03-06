CHARACTER_FACING_INCREMENT = 2;
MAX_RACES = 10;
MAX_CLASSES_PER_RACE = 10;
NUM_CHAR_CUSTOMIZATIONS = 5;
MIN_CHAR_NAME_LENGTH = 2;
CHARACTER_CREATE_ROTATION_START_X = nil;
CHARACTER_CREATE_INITIAL_FACING = nil;

FACTION_BACKDROP_COLOR_TABLE = {
	Alliance = {
		color = GLUE_ALLIANCE_COLOR,
		borderColor = GLUE_ALLIANCE_BORDER_COLOR,
	},
	Horde = {
		color = GLUE_HORDE_COLOR,
		borderColor = GLUE_HORDE_BORDER_COLOR,
	},
};

FRAMES_TO_BACKDROP_COLOR = { 
	"CharacterCreateCharacterRace",
	"CharacterCreateCharacterClass",
};
RACE_ICON_TCOORDS = {
	["HUMAN_MALE"]		= {0, 0.125, 0, 0.25},
	["DWARF_MALE"]		= {0.125, 0.25, 0, 0.25},
	["GNOME_MALE"]		= {0.25, 0.375, 0, 0.25},
	["NIGHTELF_MALE"]	= {0.375, 0.5, 0, 0.25},
	
	["TAUREN_MALE"]		= {0, 0.125, 0.25, 0.5},
	["SCOURGE_MALE"]	= {0.125, 0.25, 0.25, 0.5},
	["TROLL_MALE"]		= {0.25, 0.375, 0.25, 0.5},
	["ORC_MALE"]		= {0.375, 0.5, 0.25, 0.5},

	["HUMAN_FEMALE"]	= {0, 0.125, 0.5, 0.75},  
	["DWARF_FEMALE"]	= {0.125, 0.25, 0.5, 0.75},
	["GNOME_FEMALE"]	= {0.25, 0.375, 0.5, 0.75},
	["NIGHTELF_FEMALE"]	= {0.375, 0.5, 0.5, 0.75},
	
	["TAUREN_FEMALE"]	= {0, 0.125, 0.75, 1.0},   
	["SCOURGE_FEMALE"]	= {0.125, 0.25, 0.75, 1.0}, 
	["TROLL_FEMALE"]	= {0.25, 0.375, 0.75, 1.0}, 
	["ORC_FEMALE"]		= {0.375, 0.5, 0.75, 1.0}, 

	["BLOODELF_MALE"]	= {0.5, 0.625, 0.25, 0.5},
	["BLOODELF_FEMALE"]	= {0.5, 0.625, 0.75, 1.0}, 

	["DRAENEI_MALE"]	= {0.5, 0.625, 0, 0.25},
	["DRAENEI_FEMALE"]	= {0.5, 0.625, 0.5, 0.75}, 								   
};
CLASS_ICON_TCOORDS = {
	["WARRIOR"]	= {0, 0.25, 0, 0.25},
	["MAGE"]	= {0.25, 0.49609375, 0, 0.25},
	["ROGUE"]	= {0.49609375, 0.7421875, 0, 0.25},
	["DRUID"]	= {0.7421875, 0.98828125, 0, 0.25},
	["HUNTER"]	= {0, 0.25, 0.25, 0.5},
	["SHAMAN"]	= {0.25, 0.49609375, 0.25, 0.5},
	["PRIEST"]	= {0.49609375, 0.7421875, 0.25, 0.5},
	["WARLOCK"]	= {0.7421875, 0.98828125, 0.25, 0.5},
	["PALADIN"]	= {0, 0.25, 0.5, 0.75},
	["DEATHKNIGHT"]	= {0.25, 0.49609375, 0.5, 0.75}
};

function CharacterCreate_OnLoad(self)
	self:RegisterEvent("RANDOM_CHARACTER_NAME_RESULT");
	self:RegisterEvent("UPDATE_EXPANSION_LEVEL");
	self:RegisterEvent("CHARACTER_CREATION_RESULT");
	self:RegisterEvent("CUSTOMIZE_CHARACTER_STARTED");
	self:RegisterEvent("CUSTOMIZE_CHARACTER_RESULT");
	self:RegisterEvent("RACE_FACTION_CHANGE_STARTED");
	self:RegisterEvent("RACE_FACTION_CHANGE_RESULT");

	self:SetSequence(0);
	self:SetCamera(0);

	CharacterCreate.numRaces = 0;
	CharacterCreate.selectedRace = 0;
	CharacterCreate.numClasses = 0;
	CharacterCreate.selectedClass = 0;
	CharacterCreate.selectedGender = 0;

	C_CharacterCreation.SetCharCustomizeFrame("CharacterCreate");
	--CharCreateModel:SetLight(1, 0, 0, -0.707, -0.707, 0.7, 1.0, 1.0, 1.0, 0.8, 1.0, 1.0, 0.8);

	for i=1, NUM_CHAR_CUSTOMIZATIONS, 1 do
		_G["CharacterCustomizationButtonFrame"..i.."Text"]:SetText(_G["CHAR_CUSTOMIZATION"..i.."_DESC"]);
	end

	-- Color edit box backdrop
	local backdropColor = FACTION_BACKDROP_COLOR_TABLE["Alliance"];
	CharacterCreateNameEdit:SetBackdropBorderColor(backdropColor.borderColor:GetRGB());
	CharacterCreateNameEdit:SetBackdropColor(backdropColor.color:GetRGB());
end

function CharacterCreate_OnShow(self)
	InitializeCharacterScreenData();
	SetInCharacterCreate(true);

	--randomly selects a combination
	C_CharacterCreation.ResetCharCustomize();

	CharacterCreateEnumerateRaces();
	SetCharacterRace(C_CharacterCreation.GetSelectedRace());

	CharacterCreateEnumerateClasses();
	SetDefaultClass();

	SetCharacterGender(C_CharacterCreation.GetSelectedSex())
	
	CharacterCreateNameEdit:SetText("");
	C_CharacterCreation.SetCharacterCreateFacing(-15);

	-- Set in locale files. We only support random names for English.
	if ( ALLOW_RANDOM_NAME_BUTTON ) then
		CharacterCreateRandomName:Show();
	end

	SetGameLogo(CharacterCreateLogo);

	if( IsKioskGlueEnabled() ) then
		local templateIndex = Kiosk.GetCharacterTemplateSetIndex();
		if (templateIndex) then
			C_CharacterCreation.SetCharacterTemplate(templateIndex);
		else
			C_CharacterCreation.ClearCharacterTemplate();
		end
	end
end

function CharacterCreate_OnHide()
	SetInCharacterCreate(false);
end

function CharacterCreate_OnEvent(self, event, ...)
	if ( event == "RANDOM_CHARACTER_NAME_RESULT" ) then
		local success, name = ...;
		if ( not success ) then
			-- Failed.  Generate a random name locally.
			CharacterCreateNameEdit:SetText(C_CharacterCreation.GenerateRandomName());
		else
			-- Succeeded.  Use what the server sent.
			CharacterCreateNameEdit:SetText(name);
		end
		CharacterCreateRandomName:Enable();
		PlaySound(SOUNDKIT.GS_CHARACTER_CREATION_LOOK);
	elseif ( event == "UPDATE_EXPANSION_LEVEL" ) then
		-- Expansion level changed while online, so enable buttons as needed
		if ( CharacterCreateFrame:IsShown() ) then
			CharacterCreateEnumerateRaces();
			CharacterCreateEnumerateClasses();
		end
	elseif ( event == "CHARACTER_CREATION_RESULT" ) then
		local success, errorCode = ...;
		if ( success ) then
			CharacterSelect.selectLast = true;
			GlueParent_SetScreen("charselect");
		else
			GlueDialog_Show("OKAY", _G[errorCode]);
		end
	elseif ( event == "CUSTOMIZE_CHARACTER_STARTED" ) then
		GlueDialog_Show("PAID_SERVICE_IN_PROGRESS", CHAR_CUSTOMIZE_IN_PROGRESS);
	elseif ( event == "CUSTOMIZE_CHARACTER_RESULT" ) then
		local success, err = ...;
		if ( success ) then
			GlueDialog_Hide("PAID_SERVICE_IN_PROGRESS");
			GlueParent_SetScreen("charselect");
		else
			GlueDialog_Show("OKAY", _G[err]);
		end
	elseif ( event == "RACE_FACTION_CHANGE_STARTED" ) then
		local changeType = ...;
		if ( changeType == "RACE" ) then
			GlueDialog_Show("PAID_SERVICE_IN_PROGRESS", RACE_CHANGE_IN_PROGRESS);
		elseif ( changeType == "FACTION" ) then
			GlueDialog_Show("PAID_SERVICE_IN_PROGRESS", FACTION_CHANGE_IN_PROGRESS);
		end
	elseif ( event == "RACE_FACTION_CHANGE_RESULT" ) then
		local success, err = ...;
		if ( success ) then
			GlueDialog_Hide("PAID_SERVICE_IN_PROGRESS");
			GlueParent_SetScreen("charselect");
		else
			GlueDialog_Show("OKAY", _G[err]);
		end
	end
end

function CharacterCreateFrame_OnMouseDown(button)
	if ( button == "LeftButton" ) then
		CHARACTER_CREATE_ROTATION_START_X = GetCursorPosition();
		CHARACTER_CREATE_INITIAL_FACING = C_CharacterCreation.GetCharacterCreateFacing();
	end
end

function CharacterCreateFrame_OnMouseUp(button)
	if ( button == "LeftButton" ) then
		CHARACTER_CREATE_ROTATION_START_X = nil
	end
end

function CharacterCreateFrame_OnUpdate(self, elapsed)
	if ( CHARACTER_CREATE_ROTATION_START_X ) then
		local x = GetCursorPosition();
		local diff = (x - CHARACTER_CREATE_ROTATION_START_X) * CHARACTER_ROTATION_CONSTANT;
		CHARACTER_CREATE_ROTATION_START_X = x;
		C_CharacterCreation.SetCharacterCreateFacing(C_CharacterCreation.GetCharacterCreateFacing() + diff);
	end
end

function CharacterCreateRaceButton_OnEnter(self)
	if(self:IsEnabled()) then
		return;
	end
	GlueTooltip:SetOwner(self, "ANCHOR_RIGHT", 4, -8);
	GlueTooltip:SetText(self.tooltip, nil, 1.0, 1.0, 1.0);
	GlueTooltip:Show();
end

function CharacterCreateRaceButton_OnLeave(self)
	GlueTooltip:Hide();
end

function CharacterCreateEnumerateRaces()
	local races = C_CharacterCreation.GetAvailableRaces();
	CharacterCreate.numRaces = #races;
	if ( CharacterCreate.numRaces > MAX_RACES ) then
		message("Too many races!  Update MAX_RACES");
		return;
	end

	local isBoostedCharacter = CharacterUpgrade_IsCreatedCharacterUpgrade() or CharacterUpgrade_IsCreatedCharacterTrialBoost();
	local coords;
	local button;
	local gender;
	if ( C_CharacterCreation.GetSelectedSex() == Enum.UnitSex.Male ) then
		gender = "MALE";
	else
		gender = "FEMALE";
	end
	for index, raceData in pairs(races) do
		coords = RACE_ICON_TCOORDS[strupper(raceData.fileName.."_"..gender)];
		_G["CharacterCreateRaceButton"..index.."NormalTexture"]:SetTexCoord(coords[1], coords[2], coords[3], coords[4]);
		button = _G["CharacterCreateRaceButton"..index];
		button:Show();
		local isNewTBCRace = raceData.fileName == "BloodElf" or raceData.fileName == "Draenei";
		if isBoostedCharacter and isNewTBCRace then
			button:Disable();
			local texture = button:GetNormalTexture();
			if ( texture ) then
				texture:SetDesaturated(true);
			end
			button:SetText("");
			button.tooltip = CHAR_CREATE_NO_BOOST;
		else
			button:Enable();
			local texture = button:GetNormalTexture();
			if ( texture ) then
				texture:SetDesaturated(false);
			end
			button.tooltip = raceData.name;
		end
		button.raceID = raceData.raceID;
	end
	for i=#races + 1, MAX_RACES, 1 do
		_G["CharacterCreateRaceButton"..i]:Hide();
	end
end

function CharacterCreateEnumerateClasses()
	local classes = C_CharacterCreation.GetAvailableClasses();

	CharacterCreate.numClasses = #classes;
	if ( CharacterCreate.numClasses > MAX_CLASSES_PER_RACE ) then
		message("Too many classes!  Update MAX_CLASSES_PER_RACE");
		return;
	end

	local coords;
	local button;
	for index, classData in pairs(classes) do
		coords = CLASS_ICON_TCOORDS[strupper(classData.fileName)];
		_G["CharacterCreateClassButton"..index.."NormalTexture"]:SetTexCoord(coords[1], coords[2], coords[3], coords[4]);
		button = _G["CharacterCreateClassButton"..index];
		if (classData.enabled) then 
			button.enable = true;
			button:Enable();
			_G["CharacterCreateClassButton"..index.."DisableTexture"]:Hide();
		else
			button.enable = false;
			button:Disable();
			_G["CharacterCreateClassButton"..index.."DisableTexture"]:Show();
		end
		button.tooltip = classData.name;
		button.classID = classData.classID;
	end
	for i=CharacterCreate.numClasses+1, MAX_CLASSES_PER_RACE, 1 do
		_G["CharacterCreateClassButton"..i]:Hide();
	end
end

function SetCharacterRace(id)
	CharacterCreate.selectedRace = id;

	for i=1, CharacterCreate.numRaces, 1 do
		local button = _G["CharacterCreateRaceButton"..i];
		if ( button.raceID == id ) then
			_G["CharacterCreateRaceButton"..i.."Text"]:SetText(button.tooltip);
			button:SetChecked(1);
		else
			_G["CharacterCreateRaceButton"..i.."Text"]:SetText("");
			button:SetChecked(nil);
		end
	end

	--twain SetSelectedRace(id);
	local name, faction = C_CharacterCreation.GetFactionForRace(CharacterCreate.selectedRace);

	-- Set Race
	local race, fileString = C_CharacterCreation.GetNameForRace(CharacterCreate.selectedRace);
	CharacterCreateRaceLabel:SetText(race);
	fileString = strupper(fileString);
	if ( C_CharacterCreation.GetSelectedSex() == Enum.UnitSex.Male ) then
		gender = "MALE";
	else
		gender = "FEMALE";
	end
	local coords = RACE_ICON_TCOORDS[fileString.."_"..gender];
	CharacterCreateRaceIcon:SetTexCoord(coords[1], coords[2], coords[3], coords[4]);
	local raceText = _G["RACE_INFO_"..fileString];

	-- Loop over all the ability strings we can find and concatenate them into a giant block.
	local abilityIndex = 1;
	local tempText = _G["ABILITY_INFO_"..fileString..abilityIndex];
	abilityText = "";
	if (tempText) then
		abilityText = tempText;
		abilityIndex = abilityIndex + 1;
		tempText = _G["ABILITY_INFO_"..fileString..abilityIndex];

		while ( tempText ) do
			-- If we found another ability, throw on a couple line breaks before adding it.
			abilityText = abilityText.."\n\n"..tempText;
			abilityIndex = abilityIndex + 1;
			tempText = _G["ABILITY_INFO_"..fileString..abilityIndex];
		end
		abilityText = abilityText.."\n"; -- A bit of spacing at the bottom (to match Classic).
	end


	CharacterCreateRaceScrollFrameScrollBar:SetValue(0);
	if ( abilityText and abilityText ~= "" ) then
		CharacterCreateRaceText:SetText(_G["RACE_INFO_"..fileString]);
		CharacterCreateRaceAbilityText:SetText(abilityText);
	else
		CharacterCreateRaceText:SetText(_G["RACE_INFO_"..fileString]);
		CharacterCreateRaceAbilityText:SetText("");
	end
	CharacterCreateRaceScrollFrame:UpdateScrollChildRect();
	--CharacterCreateCharacterRace:SetHeight(CharacterCreateRaceText:GetHeight() + 40);

	-- Set backdrop colors based on faction
	local backdropColor = FACTION_BACKDROP_COLOR_TABLE[faction];
	for index, value in ipairs(FRAMES_TO_BACKDROP_COLOR) do
		_G[value]:SetBackdropColor(backdropColor.color:GetRGB());
	end

	SetBackgroundModel(CharacterCreate, C_CharacterCreation.GetCreateBackgroundModel());
	--twainUpdateCustomizationBackground();
	
	CharacterCreateEnumerateClasses();
	SetDefaultClass();

	-- Hair customization stuff
	CharacterCreate_UpdateFacialHairCustomization();
	CharacterCreate_UpdateCustomizationOptions();
end

function SetDefaultClass()
	local classData = C_CharacterCreation.GetSelectedClass();
	SetCharacterClass(classData.classID);
end


function SetCharacterClass(id)
	if (not id) then
		-- If no ID is provided, default to the first.
		id = _G["CharacterCreateClassButton1"].classID;
	end

	CharacterCreate.selectedClass = id;
	for i=1, CharacterCreate.numClasses, 1 do
		local button = _G["CharacterCreateClassButton"..i];
		if ( button.classID == id ) then
			button:SetChecked(1);
			CharacterCreateClassName:SetText(button.tooltip);
		else
			button:SetChecked(nil);
		end
	end
	
	--twain SetSelectedClass(id);
	local classData = C_CharacterCreation.GetSelectedClass();
	local coords = CLASS_ICON_TCOORDS[strupper(classData.fileName)];
	CharacterCreateClassIcon:SetTexCoord(coords[1], coords[2], coords[3], coords[4]);
	CharacterCreateClassLabel:SetText(classData.name);
	CharacterCreateClassScrollFrameScrollBar:SetValue(0);
	CharacterCreateClassText:SetText(_G["CLASS_"..strupper(classData.fileName)]);
	CharacterCreateClassScrollFrame:UpdateScrollChildRect();
	--CharacterCreateCharacterClass:SetHeight(CharacterCreateClassText:GetHeight() + 45);

	UpdateGlueTag();
end

function CharacterCreate_OnChar()
end

function CharacterCreate_OnKeyDown(self, key)
	if ( key == "ESCAPE" ) then
		CharacterCreate_Back();
	elseif ( key == "ENTER" ) then
		CharacterCreate_Okay();
	elseif ( key == "PRINTSCREEN" ) then
		Screenshot();
	end
end

function CharacterCreate_UpdateModel(self)
	C_CharacterCreation.UpdateCustomizationScene();
end

function CharacterCreate_Okay()
	PlaySound(SOUNDKIT.GS_CHARACTER_CREATION_CREATE_CHAR);

	if( Kiosk.IsEnabled() ) then
		KioskModeSplash:SetAutoEnterWorld(true);
	else
		KioskModeSplash:SetAutoEnterWorld(false)
	end

	C_CharacterCreation.CreateCharacter(CharacterCreateNameEdit:GetText());
end

function CharacterCreate_Back()
	if( IsKioskGlueEnabled() ) then
		PlaySound(SOUNDKIT.GS_CHARACTER_CREATION_CANCEL);
		GlueParent_SetScreen("kioskmodesplash");
	else
		PlaySound(SOUNDKIT.GS_CHARACTER_CREATION_CANCEL);
		CHARACTER_SELECT_BACK_FROM_CREATE = true;
		GlueParent_SetScreen("charselect");
	end
end

function CharacterClass_OnClick(self, id)
	PlaySound(SOUNDKIT.GS_CHARACTER_CREATION_CLASS);
	C_CharacterCreation.SetSelectedClass(id);
	SetCharacterClass(id);
end

function CharacterRace_OnClick(self, id)
	PlaySound(SOUNDKIT.GS_CHARACTER_CREATION_CLASS);
	if ( C_CharacterCreation.GetSelectedRace() == id ) then
		self:SetChecked(1);
		return;
	end
	C_CharacterCreation.SetSelectedRace(id);
	SetCharacterRace(id);
	C_CharacterCreation.SetSelectedSex(C_CharacterCreation.GetSelectedSex());
	C_CharacterCreation.SetCharacterCreateFacing(-15);
end

function SetCharacterGender(sex)
	local gender;
	C_CharacterCreation.SetSelectedSex(sex);
	if ( sex == Enum.UnitSex.Male ) then
		gender = "MALE";
		CharacterCreateGender:SetText(MALE);
		CharacterCreateGenderButtonMale:SetChecked(1);
		CharacterCreateGenderButtonFemale:SetChecked(nil);
	else
		gender = "FEMALE";
		CharacterCreateGender:SetText(FEMALE);
		CharacterCreateGenderButtonMale:SetChecked(nil);
		CharacterCreateGenderButtonFemale:SetChecked(1);
	end
	
	--twain SetSelectedSex(id);
	-- Update race images to reflect gender
	CharacterCreateEnumerateRaces();

	-- Update facial hair customization since gender can affect this
	CharacterCreate_UpdateFacialHairCustomization();

	-- Update right hand race portrait to reflect gender change
	-- Set Race
	local race, fileString = C_CharacterCreation.GetNameForRace(CharacterCreate.selectedRace);
	CharacterCreateRaceLabel:SetText(race);
	fileString = strupper(fileString);
	local coords = RACE_ICON_TCOORDS[fileString.."_"..gender];
	CharacterCreateRaceIcon:SetTexCoord(coords[1], coords[2], coords[3], coords[4]);
end

function CharacterCustomization_Left(id)
	PlaySound(SOUNDKIT.GS_CHARACTER_CREATION_LOOK);
	C_CharacterCreation.CycleCharCustomization(id, -1);
end

function CharacterCustomization_Right(id)
	PlaySound(SOUNDKIT.GS_CHARACTER_CREATION_LOOK);
	C_CharacterCreation.CycleCharCustomization(id, 1);
end

function CharacterCreate_GenerateRandomName(button)
	button:Disable();
	CharacterCreateNameEdit:SetText("...");
	C_CharacterCreation.RequestRandomName();
end

function CharacterCreate_Randomize()
	PlaySound(SOUNDKIT.GS_CHARACTER_CREATION_LOOK);
	C_CharacterCreation.RandomizeCharCustomization();
end

function CharacterCreateRotateRight_OnUpdate(self)
	if ( self:GetButtonState() == "PUSHED" ) then
		C_CharacterCreation.SetCharacterCreateFacing(C_CharacterCreation.GetCharacterCreateFacing() + CHARACTER_FACING_INCREMENT);
	end
end

function CharacterCreateRotateLeft_OnUpdate(self)
	if ( self:GetButtonState() == "PUSHED" ) then
		C_CharacterCreation.SetCharacterCreateFacing(C_CharacterCreation.GetCharacterCreateFacing() - CHARACTER_FACING_INCREMENT);
	end
end

function CharacterCreate_UpdateFacialHairCustomization()
	local facialHairType = C_CharacterCreation.GetCustomizationDetails(4);
	if ( facialHairType == "" ) then
		CharacterCustomizationButtonFrame5:Hide();
		CharCreateRandomizeButton:SetPoint("TOP", "CharacterCustomizationButtonFrame5", "BOTTOM", 0, -2);
	else
		CharacterCustomizationButtonFrame5Text:SetText(facialHairType);
		CharacterCustomizationButtonFrame5:Show();
		CharCreateRandomizeButton:SetPoint("TOP", "CharacterCustomizationButtonFrame5", "BOTTOM", 0, -2);
	end
end

function CharacterCreate_UpdateCustomizationOptions()
	for i=Enum.CharCustomizeMeta.MinValue, Enum.CharCustomizeMeta.MaxValue do
		_G["CharacterCustomizationButtonFrame"..(i+1).."Text"]:SetText(C_CharacterCreation.GetCustomizationDetails(i));
	end
end
