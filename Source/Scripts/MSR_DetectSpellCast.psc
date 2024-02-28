Scriptname MSR_DetectSpellCast extends ReferenceAlias
{Player Alias Script}
import PO3_SKSEFunctions
MSR_Main_Quest Property MSR_Main Auto
Keyword Property toggleableKeyword Auto
Keyword Property freeToggleOffKeyword Auto

Actor myself
string supportedSpellsKey = ".MSR.supportedSpells"
string maintainedSpellsKey = ".MSR.maintainedSpells"

Function Log(string msg)
    MSR_Main.Log("DetectSpellCast - " + msg)
EndFunction

Event OnInit()
    Maintenance()
EndEvent

Event OnPlayerLoadGame()
    Utility.Wait(0.5)
    Maintenance()
    MSR_Main.Maintenance()
EndEvent

Function Maintenance()
    myself = self.GetReference() as Actor
EndFunction

Event OnSpellCast(Form akSpell)
    bool dualCasting = false
    if MSR_Main.playerRef.GetAnimationVariableBool("isCastingDual")
        Log("Dual Casting")
        dualCasting = true
    endif
    Spell spellCast = akSpell as Spell
    if spellCast == None
        return
    endif
    Log(spellCast + " cast")
    int archetype = GetEffectArchetypeAsInt(spellCast.GetNthEffectMagicEffect(0))
    Log("Archetype: " + archetype) ; 22 or 18 for reanimate/summon
    
    int jSupportedSpells = JDB.solveObj(supportedSpellsKey)
    int jMaintainedSpells = JDB.solveObj(maintainedSpellsKey)
    if jSupportedSpells == 0
        Log("Err: No supported spells in JDB")
        return
    endif

    int commandedActors = GetCommandedActors(myself).Length

    if archetype == 18 || archetype == 22
        MSR_Main.lastConjureSpell = spellCast
    elseif JFormMap.hasKey(jMaintainedSpells, spellCast)
        Log("Maintained spell detected")
        MSR_Main.ToggleSpellOff(spellCast)
    elseif JFormMap.hasKey(jSupportedSpells, spellCast)
        MSR_Main.ToggleSpellOn(spellCast, dualCasting)
    else
        Log("Unsupported spell")
    endif
EndEvent
