Scriptname MSR_MCM_MainPage extends nl_mcm_module

MSR_Main_Quest Property MSR_Main Auto

string configKey = ".MSR.Config."

string[] perSpellDebuffTypeStrings

event OnInit()
    perSpellDebuffTypeStrings = new string[2]
    perSpellDebuffTypeStrings[0] = "$MSR_perSpellDebuffType_MagickaRate"
    perSpellDebuffTypeStrings[1] = "$MSR_perSpellDebuffType_Magicka"
    RegisterModule("$MSR_SETTINGS")
endevent

event OnPageInit()
    SetModName("$MSR")
    SetLandingPage("$MSR_SETTINGS")
endevent

event OnPageDraw()
    ; SetCursorFillMode(TOP_TO_BOTTOM)
    AddHeaderOption("$MSR_RESERVATIONHEADER")
    AddSliderOptionST("Slider_reserveMultiplier", "$MSR_reserveMultiplier", JDB.solveFlt(configKey + "reserveMultiplier"))
    AddSliderOptionST("Slider_perSpellDebuffAmount", "$MSR_perSpellDebuffAmount", JDB.solveFlt(configKey + "perSpellDebuffAmount"))
    AddSliderOptionST("Slider_perSpellThreshold", "$MSR_perSpellThreshold", JDB.solveFlt(configKey + "perSpellThreshold"))
    AddToggleOptionST("Toggle___debugLogging", "$MSR_debugLogging", JDB.solveInt(".MSR.Config.debugLogging") as bool)
    AddMenuOptionST("Menu_perSpellDebuffType", "$MSR_perSpellDebuffType", perSpellDebuffTypeStrings[JDB.solveInt(configKey + "perSpellDebuffType")])
endevent

State Menu_perSpellDebuffType
    Event OnMenuOpenST(string state_id)
        SetMenuDialog(perSpellDebuffTypeStrings, JDB.solveInt(configKey + "perSpellDebuffType"), 0)
    EndEvent

    Event OnMenuAcceptST(string state_id, int index)
        JDB.solveIntSetter(configKey + "perSpellDebuffType", index)
        SetMenuOptionValueST(perSpellDebuffTypeStrings[JDB.solveInt(configKey + "perSpellDebuffType")])
        MSR_Main.UpdateDebuff()
    EndEvent

    Event OnHighlightST(string state_id)
        SetInfoText("$MSR_perSpellDebuffType_HELP")
    EndEvent
EndState

State Slider_reserveMultiplier
    Event OnSliderOpenST(string state_id)
        SetSliderDialog(JDB.solveFlt(configKey + "reserveMultiplier"), 0, 100, 1, 50)
    EndEvent
    Event OnSliderAcceptST(string state_id, float value)
        JDB.solveFltSetter(configKey + "reserveMultiplier", value, true)
        SetSliderOptionValueST(value)
    EndEvent
    Event OnHighlightST(string state_id)
        SetInfoText("$MSR_reserveMultiplier_HELP")
    EndEvent
EndState

State Slider_perSpellDebuffAmount
    Event OnSliderOpenST(string state_id)
        SetSliderDialog(JDB.solveFlt(configKey + "perSpellDebuffAmount"), 0, 100, 1, 3)
    EndEvent
    Event OnSliderAcceptST(string state_id, float value)
        JDB.solveFltSetter(configKey + "perSpellDebuffAmount", value, true)
        SetSliderOptionValueST(value)
    EndEvent
    Event OnHighlightST(string state_id)
        SetInfoText("$MSR_perSpellDebuffAmount_HELP")
    EndEvent
EndState

State Slider_perSpellThreshold
    Event OnSliderOpenST(string state_id)
        SetSliderDialog(JDB.solveFlt(configKey + "perSpellThreshold"), -1, 100, 1, 3)
    EndEvent
    Event OnSliderAcceptST(string state_id, float value)
        JDB.solveFltSetter(configKey + "perSpellThreshold", value, true)
        SetSliderOptionValueST(value)
    EndEvent
    Event OnHighlightST(string state_id)
        SetInfoText("$MSR_perSpellThreshold_HELP")
    EndEvent
EndState

State Toggle
    Event OnSelectST(string state_id)
        bool currentVal = JDB.solveInt(configKey + state_id) as bool
        currentVal = !currentVal
        JDB.solveIntSetter(configKey + state_id, currentVal as int)
        SetToggleOptionValueST(currentVal)
    EndEvent
    Event OnHighlightST(string state_id)
        SetInfoText("$MSR_" + state_id + "_HELP")
    EndEvent
EndState