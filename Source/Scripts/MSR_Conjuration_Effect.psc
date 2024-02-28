Scriptname MSR_Conjuration_Effect extends ActiveMagicEffect

MSR_Main_Quest Property MSR_Main Auto
Actor Property playerRef Auto

import PO3_SKSEFunctions
import PO3_Events_AME

string configKey = ".MSR.Config."

bool effectFinished = false
Spell conjuringSpell = None
float spellCost
float reserveMultiplier
bool blacklisted
Actor conjuredActor

Function Log(string msg)
    MSR_Main.Log("Conjuration Effect - " + msg)
EndFunction

Function UpdateConjuringSpell()
    int i = 0
    while conjuringSpell == None && i < 10
        Utility.Wait(0.1)
        conjuringSpell = MSR_Main.lastConjureSpell
        i += 1
    endwhile
    MSR_Main.lastConjureSpell = None
    if conjuringSpell == None
        Debug.Notification("MSR ERR: Could not retrieve last conjure spell")
    endif
EndFunction

Event OnEffectStart(Actor akTarget, Actor akCaster)
    if GetCommandingActor(akTarget) == playerRef
        Log("Creature Summoned")
        conjuredActor = akTarget
        UpdateConjuringSpell()
        ToggleOn()
        RegisterForActorKilled(self)
    endif
    Utility.Wait(0.1)
    if !effectFinished
        RegisterForActorReanimateStart(self)
    endif
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
    effectFinished = true
EndEvent

Event OnActorReanimateStart(Actor akTarget, Actor akCaster)
    Log("Actor Reanimated")
    if GetCommandingActor(akTarget) == playerRef
        conjuredActor = akTarget
        UpdateConjuringSpell()
        ToggleOn()
        RegisterForActorKilled(self)
    endif
EndEvent

Event OnActorKilled(Actor akVictim, Actor akKiller)
    if akVictim == conjuredActor
        Log("Conjured Creature Killed")
        Log("    Victim: " + akVictim)
        Log("    conjuredActor: " + conjuredActor)
        Log("    conjuringSpell: " + conjuringSpell)
        UnRegisterForActorKilled(self)
        ToggleOff()
        Dispel()
    endif
EndEvent

Function ToggleOn()
    int spellData = JFormMap.getObj(MSR_Main.jSupportedSpells, conjuringSpell)
    reserveMultiplier = JMap.getInt(spellData, "reserveMultiplier", -1)
    if reserveMultiplier == -1
        reserveMultiplier = JDB.solveInt(configKey + "reserveMultiplier", 50)
    endif
    blacklisted = JMap.getInt(spellData, "isBlacklisted", 0) as bool
    Log("Reserve Multiplier: " + reserveMultiplier)
    if (JMap.getInt(JFormMap.getObj(MSR_Main.jMaintainedSpells, conjuringSpell), "isUtilitySpell") as bool)
        RegisterForModEvent("MSR_DispelUtility_Event", "DispelConjuringSpell")
    else
        RegisterForModEvent("MSR_DispelAll_Event", "DispelConjuringSpell")
    endif
    if blacklisted
        Log("Spell is blacklisted")
        return
    endif
    spellCost = conjuringSpell.GetEffectiveMagickaCost(playerRef)

    if !MSR_Main.UpdateReservedMagicka(spellCost, reserveMultiplier)
        Log("Backlash triggered")
        playerRef.DispelSpell(conjuringSpell)
        Dispel()
        return
    endif
    playerRef.RestoreActorValue("Magicka", spellCost)
    MSR_Main.UpdateDebuff()
EndFunction

Function ToggleOff()
    if blacklisted
        return
    endif
    MSR_Main.UpdateReservedMagicka(spellCost * -1, reserveMultiplier)
    MSR_Main.UpdateDebuff()
EndFunction

Function DispelConjuringSpell()
    playerRef.DispelSpell(conjuringSpell)
EndFunction