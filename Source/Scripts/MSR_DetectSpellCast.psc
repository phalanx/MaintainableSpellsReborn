Scriptname MSR_DetectSpellCast extends ReferenceAlias
{Player Alias Script}

Spell Property oakFlesh Auto
Spell Property magickaDebuffSpell Auto
Float Property reserveMultiplier = 0.5 Auto

Actor myself
Form[] maintainedSpells
Form[] supportedSpells
int spellDurationSeconds = 5962000 ; 69 Days. This is just an arbitrarily large number

string jRoot = ".MSR"
string ReservedMagickaKey = ".CurrentReservedMagicka"
string SpellCostMapKey = ".SpellCosts"

Function Log(string msg)
    Debug.Trace("[MSR] " + msg)
EndFunction

Event OnInit()
    myself = self.GetReference() as Actor
    GetSupportedSpells()
EndEvent

Event OnPlayerLoadGame()
    GetSupportedSpells()
EndEvent

Event OnSpellCast(Form akSpell)
    Spell spellCast = akSpell as Spell
    if maintainedSpells.Find(akSpell) != -1
        RemoveSpell(spellCast)
    elseif supportedSpells.Find(akSpell) != -1
        AddSpell(spellCast)
    endif
    UpdateDebuff()
EndEvent

Function UpdateDebuff()
    int currentReservedMagicka = JDB.solveInt(jRoot+reservedMagickaKey)
    Log("Debuff Reserved magicka: " + currentReservedMagicka)
    magickaDebuffSpell.SetNthEffectMagnitude(0, currentReservedMagicka)
    myself.RemoveSpell(magickaDebuffSpell)
    myself.AddSpell(magickaDebuffSpell, false)
EndFunction

Function GetSupportedSpells()
    supportedSpells = PapyrusUtil.FormArray(0)
    supportedSpells = PapyrusUtil.PushForm(supportedSpells, oakFlesh)
EndFunction

Function UpdateReserveAmount(int amount)
    
    int currentReservedMagicka = JDB.solveInt(jRoot+reservedMagickaKey)
    Log("Current Reserved Magicka: " + currentReservedMagicka)
EndFunction

Function RemoveSpell(Spell akSpell)
    myself.DispelSpell(akSpell)
    maintainedSpells = PapyrusUtil.RemoveForm(maintainedSpells, akSpell)

    int jSpellCostMap = JDB.solveObj(jRoot+spellCostMapKey)
    if jSpellCostMap == 0
        jSpellCostMap = jFormMap.object()
    endif
    
    int spellCost = jFormMap.getInt(jSpellCostMap, akSpell)
    Log("Spell Cost: " + spellCost)
    
    int currentReservedMagicka = JDB.solveInt(jRoot+reservedMagickaKey)
    currentReservedMagicka -= Math.Floor(spellCost * reserveMultiplier)
    JDB.solveIntSetter(jRoot+reservedMagickaKey, currentReservedMagicka, true)
    Log("New Reserved Magicka: " + currentReservedMagicka)

    jFormMap.setInt(jSpellCostMap, akSpell, 0)
    jDB.solveObjSetter(jRoot+spellCostMapKey, 0)
EndFunction

Function AddSpell(Spell akSpell)
    int currentReservedMagicka = JDB.solveInt(jRoot+reservedMagickaKey)
    Log("Current Reserved Magicka: " + currentReservedMagicka)
    
    int spellCost = akSPell.GetEffectiveMagickaCost(myself)
    Log("Spell Cost: " + spellCost)
   
    currentReservedMagicka += Math.Floor(spellCost * reserveMultiplier)
    myself.RestoreActorValue("Magicka", spellCost)
    JDB.solveIntSetter(jRoot+reservedMagickaKey, currentReservedMagicka, true)
    Log("New Reserved Magicka: " + currentReservedMagicka)

    int jSpellCostMap = JDB.solveObj(jRoot+spellCostMapKey)
    if jSpellCostMap == 0
        jSpellCostMap = jFormMap.object()
    endif
    jFormMap.setInt(jSpellCostMap, akSpell, spellCost)
    jDB.solveObjSetter(jRoot+spellCostMapKey, jSpellCostMap, true)

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
    maintainedSpells = PapyrusUtil.PushForm(maintainedSpells, akSpell)
EndFunction