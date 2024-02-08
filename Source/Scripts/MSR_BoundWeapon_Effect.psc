Scriptname MSR_BoundWeapon_Effect extends ActiveMagicEffect

MSR_Main_Quest Property MSR_Main Auto

Function Log(string msg)
    MSR_Main.Log("Bound Weapon - " + msg)
EndFunction

Event OnEffectStart(Actor akTarget, Actor akCaster)
    Log("Bound Weapon Started")
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
    Log("Bound Weapon Ended")
    MSR_Main.RemoveBoundWeapon()
EndEvent