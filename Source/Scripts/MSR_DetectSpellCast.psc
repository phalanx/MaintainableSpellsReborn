Scriptname MSR_DetectSpellCast extends ReferenceAlias
{Player Alias Script}

MSR_Main_Quest Property MSR_Main Auto
Spell Property removeAllPower Auto

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
    Spell spellCast = akSpell as Spell
    Log(spellCast + " cast")
    int jSupportedSpells = JDB.solveObj(supportedSpellsKey)
    int jMaintainedSpells = JDB.solveObj(maintainedSpellsKey)
    if jSupportedSpells == 0
        Log("Err: No supported spells in JDB")
        return
    endif
    
    if spellCast == removeAllPower
        MSR_Main.RemoveAllSpells()
    elseif JArray.findForm(jMaintainedSpells, spellCast) != -1
        Log("Maintained spell detected")
        MSR_Main.RemoveSpell(spellCast)
    elseif JArray.findForm(jSupportedSpells, spellCast) != -1
        Log("Supported spell detected")
        MSR_Main.AddSpell(spellCast)
    else
        Log("Spell not supported")
    endif
EndEvent
