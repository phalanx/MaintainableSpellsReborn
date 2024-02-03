Scriptname MSR_DetectSpellCast extends ReferenceAlias
{Player Alias Script}

Spell Property magickaDebuffSpell Auto
Spell Property removeAllPower Auto
Float Property reserveMultiplier = 0.5 Auto

Actor myself

string retainTag = "MaintainableSpellsReborn"
string dataDir = "Data/MSR"
int jSupportedSpells
int jMaintainedSpells
int jSpellCostMap

int spellDurationSeconds = 5962000 ; 69 Days. This is just an arbitrarily large number
float currentReservedMagicka = 0.0

Function Log(string msg)
    Debug.Trace("[MSR] " + msg)
EndFunction

Event OnInit()
    myself = self.GetReference() as Actor
    
    jSupportedSpells = JArray.object()
    JValue.retain(jSupportedSpells, retainTag)
    jMaintainedSpells = JArray.object()
    JValue.retain(jMaintainedSpells, retainTag)
    jSpellCostMap = JFormMap.object()
    JValue.retain(jSpellCostMap, retainTag)

    GetSupportedSpells()
    ; SaveSupportedSpells()
EndEvent

Event OnPlayerLoadGame()
    GetSupportedSpells()
EndEvent

Event OnSpellCast(Form akSpell)
    Log(akSpell + " cast")
    Spell spellCast = akSpell as Spell
    if spellCast == removeAllPower
        RemoveAllSpells()
    elseif JArray.findForm(jMaintainedSpells, akSpell) != -1
        Log("Maintained spell detected")
        RemoveSpell(spellCast)
    elseif JArray.findForm(jSupportedSpells, akSpell) != -1
        Log("Supported spell detected")
        AddSpell(spellCast)
    else
        Log("Spell not supported")
    endif
EndEvent

Function UpdateDebuff()
    Log("Debuff reserved magicka: " + currentReservedMagicka)
    magickaDebuffSpell.SetNthEffectMagnitude(0, currentReservedMagicka)
    myself.RemoveSpell(magickaDebuffSpell)
    myself.AddSpell(magickaDebuffSpell, false)
EndFunction

Function SaveSupportedSpells()
    Log("Saving")
    int dataMap = JMap.object()
    JMap.setObj(dataMap, "supportedSpells", jSupportedSpells)
    JValue.writeToFile(dataMap, "Data/MSR/Vanilla.json")
EndFunction

Function GetSupportedSpells()

    JArray.clear(jSupportedSpells)
    ; JArray.addForm(jSupportedSpells, sSpells[0])
    ; JArray.addForm(jSupportedSpells, sSpells[1])
    ; JArray.addForm(jSupportedSpells, oakFlesh)
    int jDir = JValue.readFromDirectory(dataDir)
    string[] jFileNameArray = JMap.allKeysPArray(jDir)
    int i = 0
    while i < jFileNameArray.Length
        Log("Reading File " + jFileNameArray[i])
        int jFileData = JMap.getObj(jDir, jFileNameArray[i])
        JArray.addFromArray(jSupportedSpells, JMap.getObj(jFileData, "supportedSpells"))
        i += 1
    endwhile
EndFunction

Function UpdateReservedMagicka(int amount)
    Log("Current reserved magicka: " + currentReservedMagicka)
    currentReservedMagicka += amount * reserveMultiplier
    if currentReservedMagicka < 1 && currentReservedMagicka > -1
        currentReservedMagicka = 0
    endif
    currentReservedMagicka = Math.Floor(currentReservedMagicka)
EndFunction

Function RemoveSpell(Spell akSpell)
    myself.DispelSpell(akSpell)
    jArray.eraseForm(jMaintainedSpells, akSpell)
    
    int spellCost = jFormMap.getInt(jSpellCostMap, akSpell)
    Log("Removal spell cost: " + spellCost)
    UpdateReservedMagicka(spellCost * -1)
    myself.RestoreActorValue("Magicka", spellCost)
    
    JFormMap.removeKey(jSpellCostMap, akSpell)
    UpdateDebuff()
EndFunction

Function AddSpell(Spell akSpell)
    int spellCost = akSPell.GetEffectiveMagickaCost(myself)
    Log("Spell cost: " + spellCost)
   
    UpdateReservedMagicka(spellCost)
    myself.RestoreActorValue("Magicka", spellCost)

    jFormMap.setInt(jSpellCostMap, akSpell, spellCost)

    int i = 0
    MagicEffect[] spellEffects = akSpell.GetMagicEffects()
    while i < spellEffects.Length
        Log("Setting Effect " + i + " Duration")
        akSpell.SetNthEffectDuration(i, spellDurationSeconds)
        i += 1
    endwhile
    myself.DispelSpell(akSpell)
    Utility.Wait(0.1)
    akSpell.Cast(myself)
    JArray.addForm(jMaintainedSpells, akSpell)
    UpdateDebuff()
EndFunction

Function RemoveAllSpells()
    int i = 0
    while i < JArray.count(jMaintainedSpells)
        RemoveSpell(JArray.getForm(jMaintainedSpells, i) as Spell)
        i += 1
    endwhile
EndFunction