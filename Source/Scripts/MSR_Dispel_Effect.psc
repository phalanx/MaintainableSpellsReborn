Scriptname MSR_Dispel_Effect extends ActiveMagicEffect

MSR_Main_Quest Property MSR Auto
bool Property utilityOnly = false Auto

Event OnEffectStart(Actor akTarget, Actor akCaster)
    MSR.Log("Dispel Effect: " + utilityOnly)
    if utilityOnly
        MSR.ToggleUtilitySpellsOff()
    else
        MSR.ToggleAllSpellsOff()
    endif
EndEvent