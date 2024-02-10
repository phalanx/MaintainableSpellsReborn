Scriptname MSR_MCM_MainPage extends nl_mcm_module

MSR_Main_Quest Property MSR_Main Auto

string configKey = ".MSR.Config."
string[] perSpellDebuffTypeStrings
string[] backlashTypeStrings

event OnInit()
    perSpellDebuffTypeStrings = new string[2]
    perSpellDebuffTypeStrings[0] = "$MSR_perSpellDebuffType_MagickaRate"
    perSpellDebuffTypeStrings[1] = "$MSR_perSpellDebuffType_Magicka"

    backlashTypeStrings = new string[4]
    backlashTypeStrings[0] = "$MSR_Backlash_DispelOnly"
    backlashTypeStrings[1] = "$MSR_Backlash_MagickaRate"
    backlashTypeStrings[2] = "$MSR_Backlash_Magicka"
    backlashTypeStrings[3] = "$MSR_Backlash_Both"
    RegisterModule("$MSR_SETTINGS", 0)
endevent

event OnPageInit()
    SetModName("$MSR")
    SetLandingPage("$MSR_SETTINGS")
endevent

event OnPageDraw()
    SetCursorFillMode(TOP_TO_BOTTOM)
    AddHeaderOption(FONT_PRIMARY("$MSR_RESERVATIONHEADER"))
    AddMenuOptionST("Menu_perSpellDebuffType", "$MSR_perSpellDebuffType", perSpellDebuffTypeStrings[JDB.solveInt(configKey + "perSpellDebuffType")])
    AddSliderOptionST("Slider_perSpellDebuffAmount", "$MSR_perSpellDebuffAmount", JDB.solveFlt(configKey + "perSpellDebuffAmount"))
    AddSliderOptionST("Slider_perSpellThreshold", "$MSR_perSpellThreshold", JDB.solveFlt(configKey + "perSpellThreshold"))
    AddSliderOptionST("Slider_dualCastModifier", "$MSR_dualCastModifier", JDB.solveFlt(configKey + "dualCastMultiplier", 2.8), "{2}")
    AddSliderOptionST("Slider_reserveMultiplier", "$MSR_reserveMultiplier", JDB.solveFlt(configKey + "reserveMultiplier"))

    AddHeaderOption(FONT_PRIMARY("$MSR_BACKLASHHEADER"))
    AddMenuOptionST("Menu_BacklashType", "$MSR_BacklashType", backlashTypeStrings[JDB.solveInt(configKey + "backlashType")])
    AddSliderOptionST("Slider_Mag___backlashMagickaRateMult", "$MSR_MAG_backlashMagickaRateMult", JDB.solveFlt(configKey + "backlashMagickaRateMult"))
    AddSliderOptionST("Slider_Mag___backlashMagicka", "$MSR_MAG_backlashMagicka", JDB.solveFlt(configKey + "backlashMagicka"))
    AddSliderOptionST("Slider_Backlash_Duration", "$MSR_backlashDuration", JDB.solveInt(configKey + "backlashDuration"))

    SetCursorPosition(1)
    AddHeaderOption(FONT_PRIMARY("$MSR_DEBUGHEADER"))
    AddToggleOptionST("Toggle___debugLogging", "$MSR_debugLogging", JDB.solveInt(".MSR.Config.debugLogging") as bool)
endevent

Event OnConfigClose()
    MSR_Main.SaveMainMCMConfig()
endEvent

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

State Slider_dualCastModifier
    Event OnSliderOpenST(string state_id)
        SetSliderDialog(JDB.solveFlt(configKey + "dualCastMultiplier"), 0, 100, 0.1, 2.8)
    EndEvent
    Event OnSliderAcceptST(string state_id, float value)
        JDB.solveFltSetter(configKey + "dualCastMultiplier", value, true)
        SetSliderOptionValueST(value, "{2}")
    EndEvent
    Event OnHighlightST(string state_id)
        SetInfoText("$MSR_dualCastModifier_HELP")
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

State Menu_BacklashType
    Event OnMenuOpenST(string state_id)
        SetMenuDialog(backlashTypeStrings, JDB.solveInt(configKey + "backlashType"), 3)
    EndEvent

    Event OnMenuAcceptST(string state_id, int index)
        JDB.solveIntSetter(configKey + "backlashType", index)
        SetMenuOptionValueST(backlashTypeStrings[JDB.solveInt(configKey + "backlashType")])
    EndEvent

    Event OnHighlightST(string state_id)
        SetInfoText("$MSR_BacklashType_HELP")
    EndEvent
EndState

State Slider_Mag
    Event OnSliderOpenST(string state_id)
        SetSliderDialog(JDB.solveFlt(configKey + state_id), 0, 100, 1, 30)
    EndEvent
    Event OnSliderAcceptST(string state_id, float value)
        JDB.solveFltSetter(configKey + state_id, value, true)
        SetSliderOptionValueST(value)
    EndEvent
    Event OnHighlightST(string state_id)
        SetInfoText("$MSR_MAG_" + state_id + "_HELP")
    EndEvent
EndState

State Slider_Backlash_Duration
    Event OnSliderOpenST(string state_id)
        SetSliderDialog(JDB.solveFlt(configKey + "backlashDuration"), 0, 100, 1, 30)
    EndEvent
    Event OnSliderAcceptST(string state_id, float value)
        JDB.solveFltSetter(configKey + "backlashDuration", value, true)
        SetSliderOptionValueST(value)
    EndEvent
    Event OnHighlightST(string state_id)
        SetInfoText("$MSR_backlashDuration_HELP")
    EndEvent
EndState