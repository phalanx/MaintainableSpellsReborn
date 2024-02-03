Scriptname MSR_MCM_MainPage extends nl_mcm_module

MSR_Main_Quest Property MSR_Main Auto

event OnInit()
    RegisterModule("Main")
endevent

event OnPageInit()
    SetModName("MSR")
    SetLandingPage("Settings")
endevent

event OnPageDraw()
    SetCursorFillMode(TOP_TO_BOTTOM)
    AddHeaderOption("Reservation Settings")
endevent
