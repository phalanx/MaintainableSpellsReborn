Scriptname MSR_SummonedCreature_Effect extends ActiveMagicEffect
{To be removed}


import PO3_SKSEFunctions
import PO3_Events_AME 

MSR_Main_Quest Property MSR_Main Auto
Actor Property playerRef Auto

; Actor[] commandedActors
string conjurationEffectsKey = ".MSR.conjurationEffects" ; JFormMap

Function Log(string msg)
    MSR_Main.Log("SummonedCreature - " + msg)
EndFunction

Event OnEffectStart(Actor akTarget, Actor akCaster)
EndEvent

Event OnSummonSpellCast()
    UnRegisterForModEvent("MSR_SummonSpellCast")
    UnregisterForActorKilled(self)
EndEvent

Event OnActorReanimateStart(Actor akTarget, Actor akCaster)
EndEvent

Event OnActorKilled(Actor akVictim, Actor akKiller)
    UnregisterForActorKilled(self)
EndEvent