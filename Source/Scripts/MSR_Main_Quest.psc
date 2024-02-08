Scriptname MSR_Main_Quest extends Quest
{The documentation string.}

import PO3_SKSEFunctions
import PO3_Events_AME
int expectedJContainersAPIVersion = 4
int expectedJContainersFeatureVersion = 2

string Property MSR_ERROR_JCONTAINERSMISSING = "JContainers appears to be missing. Proceed with Caution" Auto Hidden
string Property MSR_ERROR_JCONTAINERSAPIHIGH = "JContainers API Version is higher than expected. Notify the author of Maintainable Spells Reborn and proceed with caution" Auto Hidden
string Property MSR_ERROR_JCONTAINERSAPILOW = "JContainers API Version is lower than expected. Upgrade JContainers or proceed with caution" Auto Hidden

Spell Property magickaDebuffSpell Auto
; 0 - Magicka Rate Mult
; 1 - Magicka
Spell[] Property mentalLoadDebuffs Auto
; 0 - Magicka Rate Mult
; 1 - Magicka
Spell[] Property backlashDebuffs Auto
Perk Property spellManipulationPerk Auto
Keyword Property freeToggleOffKeyword Auto
Keyword Property toggleableKeyword Auto
Actor Property playerRef Auto
MagicEffect Property boundWeaponEffect Auto

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
; float dualCastMultiplier
; int backlashType ; 0 - DispelOnly, 1 - MagickaRate, 2 - Magicka, 3 - Both
; float backlashDuration
; float backlashMagickaRateMultMag
; float backlashMagickaMag
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

bool Function ValidateJContainers()
    Log("Validating JContainers")
    string errorMessage
    bool returnCode = true
    
    if !JContainers.isInstalled()
        errorMessage = MSR_ERROR_JCONTAINERSMISSING
        returnCode = false
    elseif JContainers.APIVersion() > expectedJContainersAPIVersion
        errorMessage = MSR_ERROR_JCONTAINERSAPIHIGH
        returnCode = false
    elseif JContainers.APIVersion() < expectedJContainersAPIVersion || JContainers.featureVersion() < expectedJContainersFeatureVersion
        errorMessage = MSR_ERROR_JCONTAINERSAPILOW
        returnCode = false
    endif

    if !returnCode
        Log("MSR ERR: " + errorMessage)
        Debug.MessageBox("MSR Err:\n" + errorMessage)
    endif
    return returnCode
EndFunction

Event OnInit()
    ValidateJContainers()
    userDir = JContainers.userDirectory() + "MSR/"

    JDB.solveIntSetter(configKey + "debugLogging", 1, true)
    JDB.solveFltSetter(configKey + "perSpellDebuffAmount", 1.0, true)
    JDB.solveIntSetter(configKey + "perSpellThreshold", 3, true)
    JDB.solveIntSetter(configKey + "perSpellDebuffType", 0, true)
    JDB.solveFltSetter(configKey + "dualCastMultiplier", 2.8, true)

    JDB.solveIntSetter(configKey + "backlashType", 3, true)
    JDB.solveIntSetter(configKey + "backlashDuration", 30, true)
    JDB.solveFltSetter(configKey + "backlashMagickaRateMult", 30, true)
    JDB.solveFltSetter(configKey + "backlashMagicka", 30, true)

    JDB.solveObjSetter(supportedSpellsKey, JFormMap.object(), true)
    JDB.solveObjSetter(maintainedSpellsKey, JFormMap.object(), true)
    JDB.solveObjSetter(userConfiguredSpellsKey, JArray.object(), true)
        
    jSpellKeywordMap = JMap.object()
    JValue.retain(jSpellKeywordMap, retainTag)
    Maintenance()
EndEvent

Function Maintenance()
    Log("Maintenance Running")
    ValidateJContainers()

    playerRef.AddPerk(spellManipulationPerk)
    jSupportedSpells = JDB.solveObj(supportedSpellsKey)
    jMaintainedSpells = JDB.solveObj(maintainedSpellsKey)

    ReadDefaultSpells()
    ReadUserConfiguration()

    Log("Maintenance Finished")
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
        if currentSpell.HasKeyword(toggleableKeyword)
            RemoveKeywordOnForm(currentSpell.GetNthEffectMagicEffect(0), toggleableKeyword)
            int iArchetype = GetEffectArchetypeAsInt(currentSpell.GetNthEffectMagicEffect(0))
            if iArchetype == 17 ; Bound Weapon
                Log("Bound Weapon configured")
                RemoveMagicEffectFromSpell(currentSpell, boundWeaponEffect, 0, 0, 1)
            endif
        endif
        if currentSpell.HasKeyword(freeToggleOffKeyword)
            RemoveKeywordOnForm(currentSpell.GetNthEffectMagicEffect(0), freeToggleOffKeyword)
        endif
        currentSpell = JFormMap.nextKey(jSupportedSpells, currentSpell) as Spell
    endwhile

    JDB.setObj(".MSR", 0)
    JValue.releaseObjectsWithTag(retainTag)
    Log("Uninstall Finished")
EndFunction

Function SpellConsistencyCheck(int jNewSpells)
    Spell currentSpell = JFormMap.nextKey(jNewSpells) as Spell
    while currentSpell != None
        if !currentSpell.HasKeyword(toggleableKeyword)
            AddKeywordToForm(currentSpell.GetNthEffectMagicEffect(0), toggleableKeyword)
            int iArchetype = GetEffectArchetypeAsInt(currentSpell.GetNthEffectMagicEffect(0))
            if iArchetype == 17 ; Bound Weapon
                AddMagicEffectToSpell(currentSpell, boundWeaponEffect, 0, 0, 1, asConditionList=new string[1])
            endif
        endif
        if JFormMap.hasKey(jMaintainedSpells, currentSpell)
            if !currentSpell.HasKeyword(freeToggleOffKeyword)
               AddKeywordToForm(currentSpell.GetNthEffectMagicEffect(0), freeToggleOffKeyword)
            endif
        elseif currentSpell.HasKeyword(freeToggleOffKeyword)
            RemoveKeywordOnForm(currentSpell.GetNthEffectMagicEffect(0), freeToggleOffKeyword)
        endif
        currentSpell = JFormMap.nextKey(jNewSpells, currentSpell) as Spell
    endwhile
EndFunction

Function AddBoundWeaponEffectToSpells(int jNewSpells)
EndFunction

int Function ReadConfigDirectory(string dirPath)
    int jNewSpells = JFormMap.object()
    JValue.retain(jNewSpells)
    int jDir
	if JContainers.fileExistsAtPath(dirPath)
		jDir = JValue.readFromDirectory(dirPath)
    else
        return jNewSpells
	endif
    string currentFile = JMap.nextKey(jDir)
    while currentFile != ""
        Log("Reading File: " + currentFile)
        int jFileData = JMap.getObj(jDir, currentFile)
        JFormMap.addPairs(jNewSpells, jFileData, true)
        currentFile = JMap.nextKey(jDir, currentFile)
    endwhile
    SpellConsistencyCheck(jNewSpells)
    return jNewSpells
EndFunction

Function ReadDefaultSpells()
    Log("Reading default configurations")
    int jNewSpells = ReadConfigDirectory(dataDir)
    jSupportedSpells = jNewSpells
    JDB.solveObjSetter(supportedSpellsKey, jSupportedSpells, true)
    JValue.release(jNewSpells)
endFunction

Function ReadUserConfiguration()
    Log("Reading user configurations")
    int jNewSpells = ReadConfigDirectory(userDir)
    JFormMap.addPairs(jSupportedSpells, jNewSpells, true)
    JDB.solveObjSetter(userConfiguredSpellsKey, jNewSpells)
    JDB.solveObjSetter(supportedSpellsKey, jSupportedSpells, true)
    JValue.release(jNewSpells)
EndFunction

Function SaveSupportedSpells()
    Log("Saving")
    int jUserConfiguredSpells = JDB.solveObj(userConfiguredSpellsKey)
    
    if JFormMap.count(jUserConfiguredSpells) != 0    
        JValue.writeToFile(jUserConfiguredSpells, userDir + "UserConfiguration.json")
        Log("Done saving")
    Else
        Log("Nothing to save")
    endif
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

bool Function UpdateReservedMagicka(float amount, float multiplier)
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

    return true
EndFunction

Function Backlash()
    Debug.Notification("Spells Backlash")
    __ToggleAllSpellsOff(false)
    backlashDebuffs[0].SetNthEffectDuration(0, JDB.solveInt(configKey + "backlashDuration"))
    backlashDebuffs[1].SetNthEffectDuration(0, JDB.solveInt(configKey + "backlashDuration"))
    backlashDebuffs[0].SetNthEffectMagnitude(0, JDB.solveFlt(configKey + "backlashMagickaRateMult"))
    backlashDebuffs[1].SetNthEffectMagnitude(0, JDB.solveFlt(configKey + "backlashMagicka"))
    backlashDebuffs[0].Cast(playerRef)
    backlashDebuffs[1].Cast(playerRef)
EndFunction

Function ToggleSpellOn(Spell akSpell, bool wasDualCast)
    GoToState("ProcessingSpell")
    __ToggleSpellOn(akSpell, wasDualCast)
    GoToState("")
EndFunction

Function __ToggleSpellOn(Spell akSpell, bool wasDualCast)
    float spellCost = akSPell.GetEffectiveMagickaCost(playerRef)
    if wasDualCast
        spellCost = spellCost * JDB.solveFlt(configKey + "dualCastMultiplier")
    endif
    Log("Toggle on spell Cost: " + spellCost)
    int spellData = JFormMap.getObj(JDB.solveObj(supportedSpellsKey), akSpell)
    int reserveMultiplier = JMap.getInt(spellData, "reserveMultiplier")
    bool blacklisted = JMap.getInt(spellData, "isBlacklisted") as bool
    Log("Reserve Multiplier: " + reserveMultiplier)

    if blacklisted
        Log("Spell is blacklisted")
        return
    endif

    int spellArchetype = GetEffectArchetypeAsInt(akSpell.GetNthEffectMagicEffect(0))
    if spellArchetype == 22 || spellArchetype == 18 ; 22 for reanimate/18 for summon
        int handler = ModEvent.Create("MSR_SummonSpellCast")
        if handler
            ModEvent.Send(handler)
        else
            Debug.Notification("MSR ERR: Could not send SummonSpell Event")
        endif
    endif

    ResolveKeywordedMagicEffect(akSpell, JMap.getStr(spellData, "Keyword"))

    if !UpdateReservedMagicka(spellCost, reserveMultiplier)
        Log("Backlash triggered")
        playerRef.DispelSpell(akSpell)
        GoToState("")
        return
    endif

    playerRef.RestoreActorValue("Magicka", spellCost)
    JMap.setFlt(spellData, "spellCost", spellCost)
    JFormMap.setObj(jMaintainedSpells, akSpell, spellData)
    Log(JFormMap.allKeysPArray(jMaintainedSpells))
    JDB.solveObjSetter(maintainedSpellsKey, jMaintainedSpells, true)
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

Function RemoveConjuration(string asKeyword)
    GoToState("ProcessingSpell")
    Spell currentBoundSpell = Jmap.getForm(jSpellKeywordMap, asKeyword) as Spell
    __ToggleSpellOff(currentBoundSpell)
    GoToState("")
EndFunction

Function __ToggleSpellOff(Spell akSpell)
    
    Log("Toggling Spell Off: " + akSPell)
    playerRef.DispelSpell(akSpell)

    if JFormMap.count(jMaintainedSpells) == 0
        Debug.Notification("$MSR_ERROR_JMAINTAINED_EMPTY")
    endif
    int spellData = JFormMap.getObj(jMaintainedSpells, akSpell)
    float spellCost = JMap.getFlt(spellData, "spellCost")
    int reserveMultiplier = JMap.getInt(spellData, "reserveMultiplier")
    string spellKeyword = JMap.getStr(spellData, "Keyword")
    Log("Toggle Off Spell Cost: " + spellCost)
    Log("Toggle Off Spell Keyword: " + spellKeyword)
    if spellKeyword != "Generic"
        Log("Removing keyworded spell")
        JMap.removeKey( jSpellKeywordMap, spellKeyword)
    Endif
    JFormMap.removeKey(jMaintainedSpells, akSpell)
    JDB.solveObjSetter(maintainedSpellsKey, jMaintainedSpells, true)
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
EndFunction

State ProcessingSpell
    Function ToggleSpellOn(Spell akSpell, bool wasDualCast)
        Log("Already Procesing Spell")
        playerRef.DispelSpell(akSpell)
    EndFunction
    Function ToggleSpellOff(Spell akSpell)
        Log("Already Processing Spell")
        playerRef.DispelSpell(akSpell)
    EndFunction
    Function ToggleAllSpellsOff(bool utilityOnly)
        Log("Already Processing Spell")
    EndFunction
    Function RemoveConjuration(string asKeyword)
        Log("Already Processing Spell")
    EndFunction
EndState
