Scriptname MSR_Main_Quest extends Quest
{The documentation string.}

Spell Property magickaDebuffSpell Auto
Float Property reserveMultiplier = 0.5 Auto
Actor Property playerRef Auto
bool Property debugLogging = true Auto Hidden

string dataDir = "Data/MSR"
string retainTag = "MaintainableSpellsReborn"
string supportedSpellsKey = ".MSR.supportedSpells"
string maintainedSpellsKey = ".MSR.maintainedSpells"

int jSpellCostMap

int spellDurationSeconds = 5962000 ; 69 Days. This is just an arbitrarily large number
float currentReservedMagicka = 0.0

Function Log(string msg)
    if debugLogging
        Debug.Trace("[MSR] " + msg)
    endif
EndFunction

Event OnInit()
    Maintenance()
        
    jSpellCostMap = JFormMap.object()
    JValue.retain(jSpellCostMap, retainTag)
EndEvent

Function Maintenance()
    Log("Maintenance Running")
    GetSupportedSpells()
    Log("Maintenance Finished")
EndFunction

Function Uninstall()
    RemoveAllSpells()
    playerRef.RemoveSpell(magickaDebuffSpell)
    JValue.releaseObjectsWithTag(retainTag)
EndFunction

Function GetSupportedSpells()
    int jSupportedSpells = JArray.object()
    int jDir = JValue.readFromDirectory(dataDir)
    string[] jFileNameArray = JMap.allKeysPArray(jDir)
    int i = 0
    while i < jFileNameArray.Length
        Log("Reading File " + jFileNameArray[i])
        int jFileData = JMap.getObj(jDir, jFileNameArray[i])
        JArray.addFromArray(jSupportedSpells, JMap.getObj(jFileData, "supportedSpells"))
        i += 1
    endwhile
    JDB.solveObjSetter(supportedSpellsKey, jSupportedSpells, true)
EndFunction

Function UpdateDebuff()
    Log("Debuff reserved magicka: " + currentReservedMagicka)
    magickaDebuffSpell.SetNthEffectMagnitude(0, currentReservedMagicka)
    playerRef.RemoveSpell(magickaDebuffSpell)
    playerRef.AddSpell(magickaDebuffSpell, false)
EndFunction

Function SaveSupportedSpells()
    ; Log("Saving")
    ; int dataMap = JMap.object()
    ; JMap.setObj(dataMap, "supportedSpells", jSupportedSpells)
    ; JValue.writeToFile(dataMap, "Data/MSR/Vanilla.json")
EndFunction

Function UpdateReservedMagicka(int amount)
    Log("Current reserved magicka: " + currentReservedMagicka)
    currentReservedMagicka += amount * reserveMultiplier
    if currentReservedMagicka < 1 && currentReservedMagicka > -1
        currentReservedMagicka = 0
    endif
    currentReservedMagicka = Math.Floor(currentReservedMagicka)
EndFunction

Function AddSpell(Spell akSpell)
    int spellCost = akSPell.GetEffectiveMagickaCost(playerRef)
    Log("Spell cost: " + spellCost)
   
    UpdateReservedMagicka(spellCost)
    playerRef.RestoreActorValue("Magicka", spellCost)

    jFormMap.setInt(jSpellCostMap, akSpell, spellCost)

    int i = 0
    MagicEffect[] spellEffects = akSpell.GetMagicEffects()
    while i < spellEffects.Length
        Log("Setting Effect " + i + " Duration")
        akSpell.SetNthEffectDuration(i, spellDurationSeconds)
        i += 1
    endwhile
    playerRef.DispelSpell(akSpell)
    Utility.Wait(0.1)
    akSpell.Cast(playerRef)
    int jMaintainedSpells = JDB.solveObj(maintainedSpellsKey, JArray.object())
    JArray.addForm(jMaintainedSpells, akSpell)
    UpdateDebuff()
    JDB.solveObjSetter(maintainedSpellsKey, jMaintainedSpells, true)
EndFunction

Function RemoveSpell(Spell akSpell)
    playerRef.DispelSpell(akSpell)
    int jMaintainedSpells = JDB.solveObj(maintainedSpellsKey)
    if jMaintainedSpells == 0
        Log("Err: Removing spell but jMaintainedSpells is empty")
    endif
    jArray.eraseForm(jMaintainedSpells, akSpell)
    JDB.solveObjSetter(maintainedSpellsKey, jMaintainedSpells)
    
    int spellCost = jFormMap.getInt(jSpellCostMap, akSpell)
    Log("Removal spell cost: " + spellCost)
    UpdateReservedMagicka(spellCost * -1)
    playerRef.RestoreActorValue("Magicka", spellCost)
    
    JFormMap.removeKey(jSpellCostMap, akSpell)
    UpdateDebuff()
EndFunction

Function RemoveAllSpells()
    int jMaintainedSpells = JDB.solveObj(maintainedSpellsKey)
    int i = 0
    while i < JArray.count(jMaintainedSpells)
        RemoveSpell(JArray.getForm(jMaintainedSpells, i) as Spell)
        i += 1
    endwhile
EndFunction