Scriptname MSR_Dispel_Effect extends ActiveMagicEffect

MSR_Main_Quest Property MSR Auto
bool Property utilityOnly = false Auto

Function Log(string msg)
    MSR.Log("Dispel - " + msg)
EndFunction

Event OnEffectStart(Actor akTarget, Actor akCaster)
    Log("Utility Only: " + utilityOnly)
    MSR.ToggleAllSpellsOff(utilityOnly)
EndEvent