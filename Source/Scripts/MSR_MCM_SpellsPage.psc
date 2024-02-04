Scriptname MSR_MCM_SpellsPage extends nl_mcm_module

MSR_Main_Quest Property MSR_Main Auto

string supportedSpellsKey = ".MSR.supportedSpells" ; JFormMap
string userConfiguredSpellsKey = ".MSR.userConfiguredSpells" ; JArray
int supportedSpells
int supportedSpellsLookup
int userConfiguredSpells

event OnInit()
    RegisterModule("$MSR_SPELLSPAGE", 2)
endevent

event OnPageDraw()
    supportedSpells = JDB.solveObj(supportedSpellsKey)
    supportedSpellsLookup = JMap.object()
    userConfiguredSpells = JDB.solveObj(userConfiguredSpellsKey, JArray.object())
    JValue.retain(supportedSpells)
    JValue.retain(supportedSpellsLookup)
    JValue.retain(userConfiguredSpells)

    AddTextOptionST("AddSpell___Left", "$MSR_LEFTSPELL", None)
    AddTextOptionST("AddSpell___Right", "$MSR_RIGHTSPELL", None)
    AddHeaderOption("$MSR_SPELLHEADER")
    AddHeaderOption("$MSR_SPELLHEADER")
    SetCursorFillMode(TOP_TO_BOTTOM)
    Form nextSpell = JFormMap.nextKey(supportedSpells)
    int cursorPosition = 4
    while nextSpell != None
        AddSpellBlock(nextSpell as Spell)
        if (cursorPosition % 2) == 0
            cursorPosition +=1
        else
            cursorPosition += 5
        endif
        SetCursorPosition(cursorPosition)
        nextSpell = JFormMap.nextKey(supportedSpells, nextSpell)
    endwhile
endevent

event OnConfigClose()
    JValue.release(supportedSpells)
    JValue.release(supportedSpellsLookup)
    JValue.release(userConfiguredSpells)
EndEvent

Function AddSpellBlock(Spell akSpell)
    int spellData = JFormMap.getObj(supportedSpells, akSpell)
    string spellName = akSPell.getName()
    string currentKeyword = JMap.GetStr(spellData,"Keyword")
    int reserveMultiplier = JMap.getInt(spellData, "reserveMultiplier")

    JMap.setForm(supportedSpellsLookup, spellName, akSpell)
    
    AddTextOptionST("NoState___" + spellName, FONT_PRIMARY(spellName), None)
    AddInputOptionST("Input_Keyword___" + spellName, "$MSR_INPUT_KEYWORD", currentKeyword)
    AddSliderOptionST("Slider_ReserveMultiplier___" + spellName, "$MSR_SLIDER_RESERVEMULTIPLIER", reserveMultiplier)
EndFunction

State Input_Keyword
    Event OnInputAcceptST(string state_id, string newKeyword)
        Form currentSpell = JMap.getForm(supportedSpellsLookup, state_id)
        int spellData = JFormMap.getObj(supportedSpells, currentSpell)

        JMap.setStr(spellData, "Keyword", newKeyword)
        JFormMap.setObj(supportedSpells, currentSpell, spellData)
        JArray.addForm(userConfiguredSpells, currentSpell)

        JDB.solveObjSetter(supportedSpellsKey, supportedSpells)
        JDB.solveObjSetter(userConfiguredSpellsKey, userConfiguredSpells)
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
        JFormMap.setObj(supportedSpells, currentSpell, spellData)
        JArray.addForm(userConfiguredSpells, currentSpell)

        JDB.solveObjSetter(supportedSpellsKey, supportedSpells)
        JDB.solveObjSetter(userConfiguredSpellsKey, userConfiguredSpells)

        SetSliderOptionValueST(value)
    EndEvent

    Event OnHighlightST(string state_id)
        SetInfoText("$MSR_SLIDER_RESERVEMULTIPLIER_HELP")
    EndEvent
EndState