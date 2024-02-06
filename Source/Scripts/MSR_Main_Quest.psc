Scriptname MSR_Main_Quest extends Quest
{The documentation string.}

import PO3_SKSEFunctions

Spell Property magickaDebuffSpell Auto
; 0 - Magicka Rate Mult
; 1 - Magicka
Spell[] Property mentalLoadDebuffs Auto
Perk Property spellManipulationPerk Auto
Keyword Property freeToggleOffKeyword Auto
Keyword Property toggleableKeyword Auto
Actor Property playerRef Auto

string dataDir = "Data/MSR/"
string userDir
string retainTag = "MaintainableSpellsReborn"
string supportedSpellsKey = ".MSR.supportedSpells"  ; JFormMap
string maintainedSpellsKey = ".MSR.maintainedSpells" ; JFormMap
string userConfiguredSpellsKey = ".MSR.userConfiguredSpells" ; JArray

; Available Configs
; bool debugLogging Whether logs should be written to file
; float perSpellDebuffAmount
; int perSpellThreshold
string configKey = ".MSR.Config."

int jSpellKeywordMap
int jSupportedSpells
int jMaintainedSpells

int spellDurationSeconds = 5962000 ; 69 Days. This is just an arbitrarily large number
float currentReservedMagicka = 0.0

Function Log(string msg)
    if JDB.solveInt(configKey + "debugLogging") as bool
        Debug.Trace("[MSR] " + msg)
    endif
EndFunction

Event OnInit()
    ; userDir = JContainers.userDirectory() + "MSR/"
    userDir = "Data/MSRUserData"

    JDB.solveIntSetter(configKey + "debugLogging", 1, true)
    JDB.solveFltSetter(configKey + "perSpellDebuffAmount", 1.0, true)
    JDB.solveIntSetter(configKey + "perSpellThreshold", 3, true)
    JDB.solveIntSetter(configKey + "perSpellDebuffType", 0, true)

    JDB.solveObjSetter(supportedSpellsKey, JFormMap.object(), true)
    JDB.solveObjSetter(maintainedSpellsKey, JFormMap.object(), true)
    JDB.solveObjSetter(userConfiguredSpellsKey, JArray.object(), true)
        
    jSpellKeywordMap = JMap.object()
    JValue.retain(jSpellKeywordMap, retainTag)
    Maintenance()
    ; SaveSupportedSpells()
EndEvent

Function Maintenance()
    Log("Maintenance Running")
    ReadDefaultSpells()
    ReadUserConfiguration()
    playerRef.AddPerk(spellManipulationPerk)
    jMaintainedSpells = JDB.solveObj(maintainedSpellsKey)
    jSupportedSpells = JDB.solveObj(supportedSpellsKey)
    Log("Maintenance Finished")
    ; SaveSupportedSpells()
EndFunction

Function Stop()
    Uninstall()
    parent.Stop()
EndFunction

Function Uninstall()
    Log("Beginning uninstall")
    ToggleAllSpellsOff(false)
    playerRef.RemoveSpell(magickaDebuffSpell)
    playerRef.RemoveSpell(mentalLoadDebuffs[0])
    playerRef.RemoveSpell(mentalLoadDebuffs[1])

    Spell currentSpell = JFormMap.nextKey(jSupportedSpells) as Spell
    while currentSpell != None
        if !currentSpell.HasKeyword(toggleableKeyword)
            RemoveKeywordOnForm(currentSpell.GetNthEffectMagicEffect(0), toggleableKeyword)
            RemoveKeywordOnForm(currentSpell.GetNthEffectMagicEffect(0), freeToggleOffKeyword)
            currentSpell = JFormMap.nextKey(jSupportedSpells, currentSpell) as Spell
        endif
    endwhile

    JDB.setObj(".MSR", 0)
    JValue.releaseObjectsWithTag(retainTag)
    Log("Uninstall Finished")
EndFunction

Function AddKeywordToSpells(int jNewSpells)
    Spell currentSpell = JFormMap.nextKey(jNewSpells) as Spell
    while currentSpell != None
        if !currentSpell.HasKeyword(toggleableKeyword)
            AddKeywordToForm(currentSpell.GetNthEffectMagicEffect(0), toggleableKeyword)
        endif
        currentSpell = JFormMap.nextKey(jNewSpells, currentSpell) as Spell
    endwhile
EndFunction

int Function ReadConfigDirectory(string dirPath)
    int jNewSpells = JFormMap.object()
    JValue.retain(jNewSpells)
    int jDir = JValue.readFromDirectory(dirPath)
    string currentFile = JMap.nextKey(jDir)
    while currentFile != ""
        Log("Reading File: " + currentFile)
        int jFileData = JMap.getObj(jDir, currentFile)
        JFormMap.addPairs(jNewSpells, jFileData, true)
        currentFile = JMap.nextKey(jDir, currentFile)
    endwhile
    AddKeywordToSpells(jNewSpells)
    return jNewSpells
EndFunction

Function ReadDefaultSpells()
    int jNewSpells = ReadConfigDirectory(dataDir)
    ; JFormMap.addPairs(jSupportedSpells, jNewSpells, false)
    JDB.solveObjSetter(supportedSpellsKey, jNewSpells, true)
    JValue.release(jNewSpells)
endFunction

Function ReadUserConfiguration()
    int jNewSpells = ReadConfigDirectory(userDir)
    JFormMap.addPairs(jSupportedSpells, jNewSpells, true)
    JValue.release(jNewSpells)
EndFunction

Function SaveSupportedSpells()
    Log("Saving")
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

    int thresholdCheck = JFormMap.count(JDB.solveObj(maintainedSpellsKey)) - perSpellThreshold
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
    ToggleAllSpellsOff(false)
EndFunction

Function ToggleSpellOn(Spell akSpell)
    GoToState("ProcessingSpell")
    __ToggleSpellOn(akSpell)
    GoToState("")
EndFunction

Function __ToggleSpellOn(Spell akSpell)
    int spellCost = akSPell.GetEffectiveMagickaCost(playerRef)
    Log("Toggle on spell Cost: " + spellCost)
    int spellData = JFormMap.getObj(JDB.solveObj(supportedSpellsKey), akSpell)
    int reserveMultiplier = JMap.getInt(spellData, "reserveMultiplier")
    bool blacklisted = JMap.getInt(spellData, "isBlacklisted") as bool
    Log("Reserve Multiplier: " + reserveMultiplier)

    if blacklisted
        Log("Spell is blacklisted")
        return
    endif

    ResolveKeywordedMagicEffect(akSpell, JMap.getStr(spellData, "Keyword"))

    if !UpdateReservedMagicka(spellCost, reserveMultiplier)
        Log("Backlash triggered")
        GoToState("")
        return
    endif

    playerRef.RestoreActorValue("Magicka", spellCost)
    JMap.setInt(spellData, "spellCost", spellCost)
    akSpell.Cast(playerRef)
    ; int jMaintainedSpells = JDB.solveObj(maintainedSpellsKey, JFormMap.object())
    JFormMap.setObj(jMaintainedSpells, akSpell, spellData)
    Log(JFormMap.allKeysPArray(jMaintainedSpells))
    ; JDB.solveObjSetter(maintainedSpellsKey, jMaintainedSpells, true)
    UpdateDebuff()
    AddKeywordToForm(akSpell.GetNthEffectMagicEffect(0), freeToggleOffKeyword)
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

    if jMaintainedSpells == 0
        Debug.Notification("$MSR_ERROR_JMAINTAINED_EMPTY")
    endif
    int spellData = JFormMap.getObj(jMaintainedSpells, akSpell)
    int spellCost = JMap.getInt(spellData, "spellCost")
    string spellKeyword = JMap.getStr(spellData, "Keyword")
    Log("Toggle Off Spell Cost: " + spellCost)
    Log("Toggle Off Spell Keyword: " + spellKeyword)
    if spellKeyword != "Generic"
        JMap.removeKey( jSpellKeywordMap, spellKeyword)
    Endif
    JMap.removeKey(jMaintainedSpells, akSpell)
    ; JDB.solveObjSetter(maintainedSpellsKey, jMaintainedSpells)
    
    int reserveMultiplier = JMap.getInt(JFormMap.getObj(JDB.solveObj(supportedSpellsKey), akSpell), "reserveMultiplier")
    UpdateReservedMagicka(spellCost * -1, reserveMultiplier)
    UpdateDebuff()
    RemoveKeywordOnForm(akSpell.GetNthEffectMagicEffect(0), freeToggleOffKeyword)

EndFunction

Function ToggleAllSpellsOff(bool utilityOnly)
    GoToState("ProcessingSpell")
    __ToggleAllSpellsOff(utilityOnly)
    GoToState("")
EndFunction

Function __ToggleAllSpellsOff(bool utilityOnly)
    
    JValue.retain(jMaintainedSpells)
    Spell currentSpell = JFormMap.nextKey(jMaintainedSpells) as Spell
    while currentSpell != None
        if utilityOnly
            if (JMap.getInt(JFormMap.getObj(jMaintainedSpells, currentSpell), "isUtilitySpell") as bool)
                __ToggleSpellOff(currentSpell)
            endif
        else
            __ToggleSpellOff(currentSpell)
        endif
        currentSpell = JFormMap.nextKey(jMaintainedSpells, currentSpell) as Spell
    endwhile
    JValue.release(jMaintainedSpells)
EndFunction

State ProcessingSpell
    Function ToggleSpellOn(Spell akSpell)
        Log("Already Procesing Spell")
        playerRef.DispelSpell(akSpell)
    EndFunction
    Function ToggleSpellOff(Spell akSpell)
        Log("Already Processing Spell")
        playerRef.DispelSpell(akSpell)
    EndFunction
    ; Function ToggleUtilitySpellsOff()
    ;     Log("Already Processing Spell")
    ; EndFunction
    Function ToggleAllSpellsOff(bool utilityOnly)
        Log("Already Processing Spell")
    EndFunction
EndState
