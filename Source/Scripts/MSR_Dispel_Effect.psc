Scriptname MSR_Dispel_Effect extends ActiveMagicEffect

MSR_Main_Quest Property MSR_Main Auto
bool Property utilityOnly = false Auto

Function Log(string msg)
    MSR_Main.Log("Dispel - " + msg)
EndFunction

Event OnEffectStart(Actor akTarget, Actor akCaster)
    Log("Utility Only: " + utilityOnly)
    MSR_Main.ToggleAllSpellsOff(utilityOnly)
EndEvent