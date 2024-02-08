Scriptname MSR_SummonedCreature_Effect extends ActiveMagicEffect

import PO3_SKSEFunctions
import PO3_Events_AME 

MSR_Main_Quest Property MSR_Main Auto
Actor Property playerRef Auto
Actor[] commandedActors

Function Log(string msg)
    MSR_Main.Log("SummonedCreature - " + msg)
EndFunction

Event OnEffectStart(Actor akTarget, Actor akCaster)
    Log("Effect Started")
    RegisterForModEvent("MSR_SummonSpellCast", "OnSummonSpellCast")
EndEvent

Event OnSummonSpellCast()
    Log("Summon Spell Cast")
    Utility.Wait(0.5)
    RegisterForActorKilled(self)
    commandedActors = GetCommandedActors(playerRef)
EndEvent

Event OnActorKilled(Actor akVictim, Actor akKiller)
    
    if commandedActors.Length > 0 && commandedActors.Find(akVictim) != -1
        Log("Commanded actor killed")
         MSR_Main.RemoveConjuration("Summon")
        commandedActors = GetCommandedActors(playerRef)
    endif

    if commandedActors.Length == 0
        UnregisterForActorKilled(self)
    endif

EndEvent