Scriptname MSR_MCM_MainPage extends nl_mcm_module

MSR_Main_Quest Property MSR_Main Auto

event OnInit()
    RegisterModule("$MSR_MAIN")
endevent

event OnPageInit()
    SetModName("$MSR")
    SetLandingPage("$MSR_MAIN")
endevent

event OnPageDraw()
    SetCursorFillMode(TOP_TO_BOTTOM)
    AddHeaderOption("$MSR_MAIN_RESERVATIONHEADER")
    AddSliderOptionST("Slider_reservedMagickaPercentage", "$MSR_MAIN_RESERVEDMAGICKAPERCENTAGE", MSR_Main.reserveMultiplier * 100)
endevent

State Slider_reservedMagickaPercentage
    Event OnSliderOpenST(string state_id)
        SetSliderDialog(MSR_Main.reserveMultiplier * 100, 0, 100, 1, 50)
    EndEvent
    Event OnSliderAcceptST(string state_id, float value)
        MSR_Main.reserveMultiplier = value/100
        SetSliderOptionValueST(value)
    EndEvent
    Event OnHighlightST(string state_id)
        SetInfoText("$MSR_MAIN_RESERVEDMAGICKAPERCENTAGE_HELP")
    EndEvent
EndState
