Scriptname MSR_Conjuration_Effect extends ActiveMagicEffect

MSR_Main_Quest Property MSR_Main Auto
Actor Property playerRef Auto

import PO3_SKSEFunctions
import PO3_Events_AME

string configKey = ".MSR.Config."
string maintainedConjurationsKey = ".MSR.MaintainedConjurationsKey" ; FormMap
; <ConjuredActor>
;     "spellCost"
;     "conjuringSpell"
int jMaintainedConjurations

bool effectFinished = false
Actor conjuredActor
Spell conjuringSpell = None
float spellCost
float reserveMultiplier
bool blacklisted


Function Log(string msg)
    MSR_Main.Log("Conjuration Effect - " + msg)
EndFunction

Function UpdateConjuringSpell()
    int i = 0
    conjuringSpell = None
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

Function LoadData()
    jMaintainedConjurations = JDB.solveObj(maintainedConjurationsKey)
    if jMaintainedConjurations == 0
        jMaintainedConjurations = JFormMap.object()
        JDB.solveObjSetter(maintainedConjurationsKey, jMaintainedConjurations, true)
    endif
    int spellData = JFormMap.getObj(jMaintainedConjurations, conjuredActor)
    conjuringSpell = JMap.GetForm(spellData, "conjuringSpell") as Spell
    spellCost = JMap.GetFlt(spellData, "spellCost")
    reserveMultiplier = JMap.getFlt(spellData, "reserveMultiplier", -1)
    blacklisted = JMap.getInt(spellData, "isBlacklisted", 0) as bool
EndFunction

Function SaveData()
    jMaintainedConjurations = JDB.solveObj(maintainedConjurationsKey)
    if jMaintainedConjurations == 0
        jMaintainedConjurations = JFormMap.object()
        JDB.solveObjSetter(maintainedConjurationsKey, jMaintainedConjurations, true)
    endif
    int spellData = JMap.object()
    JMap.SetForm(spellData, "conjuringSpell", conjuringSpell)
    JMap.SetFlt(spellData, "reserveMultiplier", reserveMultiplier)
    JMap.SetInt(spellData, "isBlacklisted", blacklisted as int)
    JMap.SetFlt(spellData, "spellCost", spellCost)
    JFormMap.SetObj(jMaintainedConjurations, conjuredActor, spellData)
    JDB.solveObjSetter(maintainedConjurationsKey, jMaintainedConjurations, true)
EndFunction

Event OnEffectStart(Actor akTarget, Actor akCaster)
    if GetCommandingActor(akTarget) == playerRef
        Log("Creature Summoned: " + akTarget)
        conjuredActor = akTarget
        LoadData()
        if conjuringSpell == None
            UpdateConjuringSpell()
            ToggleOn()
        endif
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
    if GetCommandingActor(akTarget) == playerRef
        Log("Actor Reanimated:" + akTarget)
        conjuredActor = akTarget
        LoadData()
        if conjuringSpell == None
            UpdateConjuringSpell()
            ToggleOn()
        endif
        RegisterForActorKilled(self)
    endif
EndEvent

Event OnActorKilled(Actor akVictim, Actor akKiller)
    if akVictim == conjuredActor
        Log("Conjured Creature Killed")
        Log("    Victim: " + akVictim)
        Log("    conjuredActor: " + conjuredActor)
        Log("    conjuringSpell: " + conjuringSpell)
        Log("    spellCost: " + spellCost)
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
   
    if blacklisted
        Log("Spell is blacklisted")
        return
    endif

    if (JMap.getInt(JFormMap.getObj(MSR_Main.jSupportedSpells, conjuringSpell), "isUtilitySpell") as bool)
        RegisterForModEvent("MSR_DispelUtility_Event", "DispelConjuringSpell")
    else
        RegisterForModEvent("MSR_DispelAll_Event", "DispelConjuringSpell")
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
    SaveData()
EndFunction

Function ToggleOff()
    if spellCost == 0
        LoadData()
    endif
    MSR_Main.UpdateReservedMagicka(spellCost * -1, reserveMultiplier)
    MSR_Main.UpdateDebuff()
    JFormMap.SetObj(jMaintainedConjurations, conjuredActor, 0)
EndFunction

Function DispelConjuringSpell()
    playerRef.DispelSpell(conjuringSpell)
EndFunction