Scriptname MSR_DetectSpellCast extends ReferenceAlias
{Player Alias Script}
import PO3_SKSEFunctions
MSR_Main_Quest Property MSR_Main Auto
Keyword Property toggleableKeyword Auto
Keyword Property freeToggleOffKeyword Auto

Actor myself
string supportedSpellsKey = ".MSR.supportedSpells"
string maintainedSpellsKey = ".MSR.maintainedSpells"
int jSupportedSpells
int jMaintainedSpells

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
    jSupportedSpells = JDB.solveObj(supportedSpellsKey)
    jMaintainedSpells = JDB.solveObj(maintainedSpellsKey)
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
    Log("Archetype: " + GetEffectArchetypeAsInt(spellCast.GetNthEffectMagicEffect(0))) ; 22 or 17 for reanimate/summon

    if jSupportedSpells == 0
        Log("Err: No supported spells in JDB")
        return
    endif

    if JFormMap.hasKey(jMaintainedSpells, spelLCast)
        Log("Maintained spell detected")
        MSR_Main.ToggleSpellOff(spellCast)
    elseif JFormMap.hasKey(jSupportedSpells, spellCast)
        MSR_Main.ToggleSpellOn(spellCast, dualCasting)
    else
        Log("Unsupported spell")
    endif
EndEvent
