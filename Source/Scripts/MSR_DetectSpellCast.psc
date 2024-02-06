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
    myself = self.GetReference() as Actor
EndEvent

Event OnPlayerLoadGame()
    MSR_Main.Maintenance()
EndEvent

Event OnSpellCast(Form akSpell)
    bool dualCasting = false
    if myself.GetAnimationVariableBool("isCastingDual")
        dualCasting = true
    endif
    Spell spellCast = akSpell as Spell
    Log(spellCast + " cast")
    int jSupportedSpells = JDB.solveObj(supportedSpellsKey)
    if jSupportedSpells == 0
        Log("Err: No supported spells in JDB")
        return
    endif
 
    if spellCast.HasKeyword(freeToggleOffKeyword)
        Log("Maintained spell detected")
        MSR_Main.ToggleSpellOff(spellCast)
    elseif spellCast.HasKeyword(toggleableKeyword)
        MSR_Main.ToggleSpellOn(spellCast, dualCasting)
    else
        Log("Unsupported spell")
    endif
EndEvent
