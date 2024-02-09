Scriptname MSR_MCM_SpellsPage extends nl_mcm_module

MSR_Main_Quest Property MSR_Main Auto
string Property noSpellErrorMessage = "No spell equipped in that hand" Auto
string Property spellAddedMessage = "Spell added successfully" Auto

string supportedSpellsKey = ".MSR.supportedSpells" ; JFormMap
string userConfiguredSpellsKey = ".MSR.userConfiguredSpells" ; JArray
int supportedSpells
int supportedSpellsLookup
int userConfiguredSpells

event OnInit()
    RegisterModule("$MSR_SPELLSPAGE", 1)
endevent

int currentSpellsPage = 0
event OnPageDraw()
    supportedSpells = JDB.solveObj(supportedSpellsKey)
    supportedSpellsLookup = JMap.object()
    userConfiguredSpells = JDB.solveObj(userConfiguredSpellsKey, JFormMap.object())
    JValue.retain(supportedSpells)
    JValue.retain(supportedSpellsLookup)
    JValue.retain(userConfiguredSpells)

    AddTextOptionST("AddSpell___0", "$MSR_LEFTSPELL", None)
    AddTextOptionST("AddSpell___1", "$MSR_RIGHTSPELL", None)
    AddHeaderOption("$MSR_SPELLHEADER")
    AddHeaderOption("$MSR_SPELLHEADER")
    SetCursorFillMode(TOP_TO_BOTTOM)
    PaginateSpells(currentSpellsPage)
endevent

event OnConfigClose()
    JValue.release(supportedSpells)
    JValue.release(supportedSpellsLookup)
    JValue.release(userConfiguredSpells)
    MSR_Main.SaveSupportedSpells()
    currentSpellsPage = 0
EndEvent

Function PaginateSpells(int startingPage = 0)
    Form nextSpell = JFormMap.nextKey(supportedSpells)
    while nextSpell != None
        string spellName = nextSpell.getName()
        JMap.setForm(supportedSpellsLookup, spellName, nextSpell)
        nextSpell = JFormMap.nextKey(supportedSpells, nextSpell)
    endwhile
    int sortedKeys = JArray.sort(JMap.allKeys(supportedSpellsLookup))
    int cursorPosition = 4
    MSR_Main.Log(JArray.asStringArray(sortedKeys))
    int i = (startingPage * 22)
    while i < JArray.count(sortedKeys) && cursorPosition < 110
        Form currentSpell = JMap.GetForm(supportedSpellsLookup, JArray.getStr(sortedKeys, i))
        AddSpellBlock(currentSpell as Spell)
        
        if (cursorPosition % 2) == 0
            cursorPosition +=1
            SetCursorPosition(cursorPosition)
        else
            cursorPosition += 9
            SetCursorPosition(cursorPosition)
        endif
        i += 1
    endwhile

    if (cursorPosition % 2) != 0
        SetCursorPosition(cursorPosition + 9)
    endif
    
    SetCursorFillMode(LEFT_TO_RIGHT)
    AddHeaderOption("")
    AddHeaderOption("")

    if currentSpellsPage != 0
        AddTextOptionST("Paginate___Previous", "$MSR_PREVIOUSPAGE", None)
    else
        AddEmptyOption()
    endif
    if cursorPosition >= 110
        if i < JArray.count(sortedKeys)
            AddTextOptionST("Paginate___Next", "$MSR_NEXTPAGE", None)
        endif
    endif
    SetCursorFillMode(TOP_TO_BOTTOM)

EndFunction

Function AddSpellBlock(Spell akSpell)
    int spellData = JFormMap.getObj(supportedSpells, akSpell)
    string spellName = akSPell.getName()
    string currentKeyword = JMap.GetStr(spellData,"Keyword")
    int reserveMultiplier = JMap.getInt(spellData, "reserveMultiplier")
    bool isBlackListed = JMap.getInt(spellData, "isBlacklisted") as bool
    bool isUtilitySpell = JMap.getInt(spellData, "isUtilitySpell") as bool
  
    AddTextOptionST("NoState___" + spellName, FONT_PRIMARY(spellName), None)
    AddInputOptionST("Input_Keyword___" + spellName, "$MSR_INPUT_KEYWORD", currentKeyword)
    AddSliderOptionST("Slider_ReserveMultiplier___" + spellName, "$MSR_SLIDER_RESERVEMULTIPLIER", reserveMultiplier)
    AddToggleOptionST("Toggle_Blacklist___" + spellName, "$MSR_BLACKLIST", isBlackListed)
    AddToggleOptionST("Toggle_UtilitySpell___" + spellName, "$MSR_UTILITYSPELL", isUtilitySpell)
EndFunction

Function UpdateUserConfig(Form spellToUpdate, int spellData)
    JFormMap.setObj(supportedSpells, spellToUpdate, spellData)
    JFormMap.setObj(userConfiguredSpells, spellToUpdate, spellData)
    JDB.solveObjSetter(supportedSpellsKey, supportedSpells)
    JDB.solveObjSetter(userConfiguredSpellsKey, userConfiguredSpells)
    MSR_Main.UpdateSpell(spellToUpdate as Spell, JMap.GetInt(spellData, "isBlacklisted", 0))
EndFunction

State Input_Keyword
    Event OnInputAcceptST(string state_id, string newKeyword)
        Form currentSpell = JMap.getForm(supportedSpellsLookup, state_id)
        int spellData = JFormMap.getObj(supportedSpells, currentSpell)

        JMap.setStr(spellData, "Keyword", newKeyword)
        UpdateUserConfig(currentSpell, spellData)
        SetInputOptionValueST(newKeyword)
    EndEvent

    Event OnHighlightST(string state_id)
        SetInfoText("$MSR_INPUT_KEYWORD_HELP")
    EndEvent
EndState

State Slider_ReserveMultiplier
    Event OnSliderOpenST(string state_id)
        Form currentSpell = JMap.getForm(supportedSpellsLookup, state_id)
        int spellData = JFormMap.getObj(supportedSpells, currentSpell)
        SetSliderDialog(JMap.getInt(spellData, "reserveMultiplier"), 0, 100, 1, 50)
    EndEvent
    
    Event OnSliderAcceptST(string state_id, float value)
        Form currentSpell = JMap.getForm(supportedSpellsLookup, state_id)
        int spellData = JFormMap.getObj(supportedSpells, currentSpell)

        JMap.setInt(spellData, "reserveMultiplier", value as int)
        UpdateUserConfig(currentSpell, spellData)
        
        SetSliderOptionValueST(value)
    EndEvent

    Event OnHighlightST(string state_id)
        SetInfoText("$MSR_SLIDER_RESERVEMULTIPLIER_HELP")
    EndEvent
EndState

State AddSpell
    Event OnSelectST(string state_id)
        SetOptionFlagsST(OPTION_FLAG_DISABLED, false, "AddSpell___" + state_id)
        Spell equippedSpell = MSR_Main.playerRef.GetEquippedSpell(state_id as int)
        if equippedSpell == None
            MSR_Main.Log("Spell not equipped in slot: " + state_id)
            Debug.MessageBox(noSpellErrorMessage)
            SetOptionFlagsST(OPTION_FLAG_None, false, "AddSpell___" + state_id)
            return
        endif
        
        int spellData = JMap.object()
        JMap.setInt(spellData, "reserveMultiplier", 50)
        JMap.setStr(spellData, "Keyword", "Generic")
        UpdateUserConfig(equippedSpell, spellData)

        ForcePageReset()
        Debug.MessageBox(spellAddedMessage)
        SetOptionFlagsST(OPTION_FLAG_NONE, false, "AddSpell___" + state_id)
    EndEvent
EndState

State Toggle_Blacklist
    Event OnSelectST(string state_id)
        Form currentSpell = JMap.getForm(supportedSpellsLookup, state_id)
        int spellData = JFormMap.getObj(supportedSpells, currentSpell)
        bool currentValue = !JMap.GetInt(spellData, "isBlacklisted") as bool

        JMap.setInt(spellData, "isBlacklisted", currentValue as int)
        UpdateUserConfig(currentSpell, spellData)

        SetToggleOptionValueST(currentValue)
    EndEvent

    Event OnHighlightST(string state_id)
        SetInfoText("$MSR_BLACKLIST_HELP")
    EndEvent
EndState

State Toggle_UtilitySpell
    Event OnSelectST(string state_id)
        Form currentSpell = JMap.getForm(supportedSpellsLookup, state_id)
        int spellData = JFormMap.getObj(supportedSpells, currentSpell)
        bool currentValue = !JMap.GetInt(spellData, "isUtilitySpell") as bool

        JMap.setInt(spellData, "isUtilitySpell", currentValue as int)
        UpdateUserConfig(currentSpell, spellData)

        SetToggleOptionValueST(currentValue)
    EndEvent

    Event OnHighlightST(string state_id)
        SetInfoText("$MSR_UTILITYSPELL_HELP")
    EndEvent
EndState

State Paginate
    Event OnSelectST(string state_id)
        if state_id == "Next"
            currentSpellsPage += 1
        elseif state_id == "Previous"
            currentSpellsPage -= 1
        endif
        ForcePageReset()
    endEvent
EndState