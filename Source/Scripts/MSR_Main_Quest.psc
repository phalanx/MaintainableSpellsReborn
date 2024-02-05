Scriptname MSR_Main_Quest extends Quest
{The documentation string.}

import PO3_SKSEFunctions

Spell Property magickaDebuffSpell Auto
; 0 - Magicka Rate Mult
; 1 - Magicka
Spell[] Property mentalLoadDebuffs Auto
Perk Property freeToggleOffPerk Auto
Keyword Property freeToggleOffKeyword Auto
Spell Property removeAllPower Auto
Actor Property playerRef Auto

string dataDir = "Data/MSR/"
string userDir
string retainTag = "MaintainableSpellsReborn"
string supportedSpellsKey = ".MSR.supportedSpells"  ; JFormMap
string maintainedSpellsKey = ".MSR.maintainedSpells" ; JArray
string userConfiguredSpellsKey = ".MSR.userConfiguredSpells" ; JArray

; Available Configs
; bool debugLogging Whether logs should be written to file
; float reserveMultiplier
; float perSpellDebuffAmount
; int perSpellThreshold
string configKey = ".MSR.Config."

int jSpellCostMap
int jSpellKeywordMap

int spellDurationSeconds = 5962000 ; 69 Days. This is just an arbitrarily large number
float currentReservedMagicka = 0.0

Function Log(string msg)
    if JDB.solveInt(configKey + "debugLogging") as bool
        Debug.Trace("[MSR] " + msg)
    endif
EndFunction

Event OnInit()
    userDir = JContainers.userDirectory() + "MSR/"

    JDB.solveIntSetter(configKey + "debugLogging", 1, true)
    JDB.solveFltSetter(configKey + "perSpellDebuffAmount", 1.0, true)
    JDB.solveIntSetter(configKey + "perSpellThreshold", 3, true)
    JDB.solveIntSetter(configKey + "perSpellDebuffType", 0, true)
    
    JDB.solveObjSetter(userConfiguredSpellsKey, JArray.object(), true)
        
    jSpellCostMap = JFormMap.object()
    jSpellKeywordMap = JMap.object()
    JValue.retain(jSpellCostMap, retainTag)
    JValue.retain(jSpellKeywordMap, retainTag)
    Maintenance()
    ; SaveSupportedSpells()
EndEvent

Function Maintenance()
    Log("Maintenance Running")
    ReadDefaultSpells()
    playerRef.AddPerk(freeToggleOffPerk)
    Log("Maintenance Finished")
    ; SaveSupportedSpells()
EndFunction

Function Uninstall()
    ToggleAllSpellsOff()
    playerRef.RemoveSpell(magickaDebuffSpell)
    playerRef.RemoveSpell(mentalLoadDebuffs[0])
    playerRef.RemoveSpell(mentalLoadDebuffs[1])
    playerRef.RemoveSpell(removeAllPower)
    JValue.releaseObjectsWithTag(retainTag)
EndFunction

Function ReadDefaultSpells()
    int jNewSpells = ReadConfigDirectory(dataDir)
    JDB.solveObjSetter(supportedSpellsKey, jNewSpells, true)
    JValue.release(jNewSpells)
endFunction

Function ReadUserConfiguration()
    int jNewSpells = ReadConfigDirectory(userDir)
    int jOldSpells = JDB.solveObj(supportedSpellsKey)
    JFormMap.addPairs(jNewSpells, jOldSpells, true)
    JDB.solveObjSetter(supportedSpellsKey, jNewSpells, true)
    JDB.solveObjSetter(userConfiguredSpellsKey, JFormMap.AllKeys(jNewSpells))
    JValue.release(jNewSpells)
EndFunction

int Function ReadConfigDirectory(string dirPath)
    int jNewSpells = JFormMap.object()
    JValue.retain(jNewSpells)
    int jDir = JValue.readFromDirectory(dataDir)
    string currentFile = JMap.nextKey(jDir)
    while currentFile != ""
        Log("Reading File: " + currentFile)
        int jFileData = JMap.getObj(jDir, currentFile)
        JFormMap.addPairs(jNewSpells, jFileData, true)
        currentFile = JMap.nextKey(jDir,currentFile)
        Log("Current Keys: " + JFormMap.allKeysPArray(jNewSpells))
    endwhile
    return jNewSpells
EndFunction

Function SaveSupportedSpells()
    Log("Saving")
    int jSupportedSpells = JDB.solveObj(supportedSpellsKey)
    JValue.retain(jSupportedSpells)

    int jConvertedSpells = JFormMap.object()
    JValue.retain(jConvertedSpells)
    int i = 0
    while i < jArray.count(jSupportedSpells)
        Log("Converting")
        int jSpellMap = JMap.object()
        JMap.clear(jSpellMap)

        JMap.setInt(jSpellMap, "reserveMultiplier", 50)
        MagicEffect me = (JArray.getForm(jSupportedSpells, i) as Spell).GetNthEffectMagicEffect(0)

        if me.HasKeywordString("MagicArmorSpell")
            JMap.setStr(jSpellMap, "Keyword", "MagicArmorSpell")
        elseif me.HasKeywordString("MagicCloak")
            JMap.setStr(jSpellMap, "Keyword", "MagicCloak")
        else
            JMap.setStr(jSpellMap, "Keyword", "Generic")
        endif

        JFormMap.setObj(jConvertedSpells, JArray.getForm(jSupportedSpells, i), jSpellMap)
        i += 1
    endwhile

    JValue.writeToFile(jConvertedSpells, dataDir + "Vanilla2.json")

    JValue.release(jConvertedSpells)
EndFunction

Function UpdateDebuff()
    Log("Debuff reserved magicka: " + currentReservedMagicka)
    magickaDebuffSpell.SetNthEffectMagnitude(0, currentReservedMagicka)
    playerRef.RemoveSpell(magickaDebuffSpell)
    playerRef.AddSpell(magickaDebuffSpell, false)

    playerRef.RemoveSpell(mentalLoadDebuffs[0])
    playerRef.RemoveSpell(mentalLoadDebuffs[1])
    
    int perSpellThreshold = JDB.solveInt(configKey + "perSpellThreshold")
    if perSpellThreshold == -1
        return
    endif
    int thresholdCheck = JArray.count(JDB.solveObj(maintainedSpellsKey)) - perSpellThreshold
    if thresholdCheck < 0
        thresholdCheck = 0       
    endif

    int debuffIndex = JDB.solveInt(configKey + "perSpellDebuffType")
    mentalLoadDebuffs[debuffIndex].SetNthEffectMagnitude(0, JDB.solveFlt(configKey + "perSPellDebuffAmount") * thresholdCheck)
    playerRef.AddSpell(mentalLoadDebuffs[debuffIndex], false)
EndFunction

bool Function UpdateReservedMagicka(int amount, float multiplier)
    Log("Current reserved magicka: " + currentReservedMagicka)
    float newReserveAmount = amount * (multiplier/100)
    if newReserveAmount > playerRef.GetActorValueMax("Magicka")
        Backlash()
        return false
    endif
    currentReservedMagicka += newReserveAmount
    if currentReservedMagicka < 1 && currentReservedMagicka > -1
        currentReservedMagicka = 0
    elseif currentReservedMagicka < 0
        currentReservedMagicka = 0
    endif
    currentReservedMagicka = Math.Floor(currentReservedMagicka)
    return true
EndFunction

Function Backlash()
    Debug.Notification("Spells Backlash")
    ToggleAllSpellsOff()
EndFunction

Function ToggleSpellOn(Spell akSpell)
    GoToState("ProcessingSpell")
    __ToggleSpellOn(akSpell)
    GoToState("")
EndFunction

Function __ToggleSpellOn(Spell akSpell)
    GoToState("ProcessingSpell")
    int spellCost = akSPell.GetEffectiveMagickaCost(playerRef)
    int spellData = JFormMap.getObj(JDB.solveObj(supportedSpellsKey), akSpell)
    int reserveMultiplier = JMap.getInt(spellData, "reserveMultiplier")
    bool blacklisted = JMap.getInt(spellData, "isBlacklisted") as bool
    Log("Reserve Multiplier: " + reserveMultiplier)

    if blacklisted
        Log("Spell is blacklisted")
        return
    endif

    ResolveKeywordedMagicEffect(akSpell, JMap.getStr(spellData, "Keyword"))

    int i = 0
    MagicEffect[] spellEffects = akSpell.GetMagicEffects()
    while i < spellEffects.Length
        Log("Setting Effect " + i + " Duration")
        akSpell.SetNthEffectDuration(i, spellDurationSeconds)
        i += 1
    endwhile
    
    playerRef.DispelSpell(akSpell)
    Utility.Wait(0.1)
   
    if !UpdateReservedMagicka(spellCost, reserveMultiplier)
        Log("Backlash triggered")
        GoToState("")
        return
    endif

    playerRef.RestoreActorValue("Magicka", spellCost)
    jFormMap.setInt(jSpellCostMap, akSpell, spellCost)
    akSpell.Cast(playerRef)
    int jMaintainedSpells = JDB.solveObj(maintainedSpellsKey, JArray.object())
    JArray.addForm(jMaintainedSpells, akSpell)
    JDB.solveObjSetter(maintainedSpellsKey, jMaintainedSpells, true)
    UpdateDebuff()
    AddKeywordToForm(akSpell.GetNthEffectMagicEffect(0), freeToggleOffKeyword)
    GoToState("")
EndFunction

Function ResolveKeywordedMagicEffect(Spell akSpell, string spellKeyword)
        Log("Checking Keyword: " + spellKeyword)   
        if spellKeyword == "Generic"
            return
        endif
        
        int keyArray = JMap.allKeys(jSpellKeywordMap)
        if JArray.findStr(keyArray, spellKeyword) != -1
            Log("Registered Keyword Found")
            Form checkSpellForm = JMap.getForm(jSpellKeywordMap, spellKeyword)
            if checkSpellForm != None
                __ToggleSpellOff(checkSpellForm as Spell)
            endif
        endif
        JMap.setForm(jSpellKeywordMap, spellKeyword, akSpell)
EndFunction

Function ToggleSpellOff(Spell akSpell)
    GoToState("ProcessingSpell")
    __ToggleSpellOff(akSpell)
    GoToState("")
EndFunction

Function __ToggleSpellOff(Spell akSpell)
    
    Log("Toggling Spell Off: " + akSPell)
    playerRef.DispelSpell(akSpell)
    int jMaintainedSpells = JDB.solveObj(maintainedSpellsKey)
    if jMaintainedSpells == 0
        Log("Err: Removing spell but jMaintainedSpells is empty")
    endif
    jArray.eraseForm(jMaintainedSpells, akSpell)
    JDB.solveObjSetter(maintainedSpellsKey, jMaintainedSpells)
    
    int spellCost = jFormMap.getInt(jSpellCostMap, akSpell)
    int reserveMultiplier = JMap.getInt(JFormMap.getObj(JDB.solveObj(supportedSpellsKey), akSpell), "reserveMultiplier")
    UpdateReservedMagicka(spellCost * -1, reserveMultiplier)
    
    JFormMap.removeKey(jSpellCostMap, akSpell)
    UpdateDebuff()
    RemoveKeywordOnForm(akSpell.GetNthEffectMagicEffect(0), freeToggleOffKeyword)

EndFunction

Function ToggleAllSpellsOff()
    GoToState("ProcessingSpell")
    int jMaintainedSpells = JDB.solveObj(maintainedSpellsKey)
    JValue.retain(jMaintainedSpells)
    while JArray.count(jMaintainedSpells) > 0
         __ToggleSpellOff(JArray.getForm(jMaintainedSpells, 0) as Spell)
    endwhile
    JValue.release(jMaintainedSpells)
    GoToState("")
EndFunction

Function ToggleUtilitySpellsOff()
    GoToState("ProcessingSpell")

    int jMaintainedSpells = JArray.object()
    JArray.addFromArray(jMaintainedSpells, JDB.solveObj(maintainedSpellsKey))
    int jSupportedSpells = JDB.solveObj(supportedSpellsKey)
    JValue.retain(jMaintainedSpells)
    JValue.retain(jSupportedSpells)
    
    int spellData
    int i = 0
    while i < JArray.count(jMaintainedSpells)
        spellData = JFormMap.getObj(jSupportedSpells, JArray.getForm(jMaintainedSpells, i))
        if JMap.GetInt(spellData, "isUtilitySpell") as bool
            __ToggleSpellOff(JArray.getForm(jMaintainedSpells, i) as Spell)
        endif
        i += 1
    endwhile
    
    JValue.release(jMaintainedSpells)
    JValue.release(jSupportedSpells)
    GoToState("")
EndFunction

State ProcessingSpell
    Function ToggleSpellOn(Spell akSpell)
        Log("Already Procesing Spell")
    EndFunction
    Function ToggleSpellOff(Spell akSpell)
        Log("Already Processing Spell")
    EndFunction
EndState