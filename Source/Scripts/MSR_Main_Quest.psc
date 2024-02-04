Scriptname MSR_Main_Quest extends Quest
{The documentation string.}

Spell Property magickaDebuffSpell Auto
; 0 - Magicka Rate Mult
; 1 - Magicka
Spell[] Property mentalLoadDebuffs Auto
Spell Property removeAllPower Auto
Actor Property playerRef Auto

string dataDir = "Data/MSR"
string retainTag = "MaintainableSpellsReborn"
string supportedSpellsKey = ".MSR.supportedSpells"
string maintainedSpellsKey = ".MSR.maintainedSpells"
string genericKeyword = "Generic" ; Used for spells that don't use keywords to dispel effects

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
    JDB.solveIntSetter(configKey + "debugLogging", 1, true)
    JDB.solveFltSetter(configKey + "reserveMultiplier", 50, true)
    JDB.solveFltSetter(configKey + "perSpellDebuffAmount", 1.0, true)
    JDB.solveIntSetter(configKey + "perSpellThreshold", 3, true)
    JDB.solveIntSetter(configKey + "perSpellDebuffType", 0, true)
        
    jSpellCostMap = JFormMap.object()
    jSpellKeywordMap = JMap.object()
    JValue.retain(jSpellCostMap, retainTag)
    JValue.retain(jSpellKeywordMap, retainTag)
    Maintenance()
EndEvent

Function Maintenance()
    Log("Maintenance Running")
    GetSupportedSpells()
    Log("Maintenance Finished")
    ; SaveSupportedSpells()
EndFunction

Function Uninstall()
    RemoveAllSpells()
    playerRef.RemoveSpell(magickaDebuffSpell)
    playerRef.RemoveSpell(mentalLoadDebuffs[0])
    playerRef.RemoveSpell(mentalLoadDebuffs[1])
    playerRef.RemoveSpell(removeAllPower)
    JValue.releaseObjectsWithTag(retainTag)
EndFunction

Function GetSupportedSpells()
    int jSupportedSpells = JArray.object()
    JValue.retain(jSupportedSpells)
    int jDir = JValue.readFromDirectory(dataDir)
    string[] jFileNameArray = JMap.allKeysPArray(jDir)
    int i = 0
    while i < jFileNameArray.Length
        Log("Reading File " + jFileNameArray[i])
        int jFileData = JMap.getObj(jDir, jFileNameArray[i])
        int jKeywordMap = JMap.getObj(jFileData,".supportedSpells")
        string currentKeyword = jMap.nextKey(jKeywordMap)
        while currentKeyword != ""
            Form currentKeywordForm = Keyword.GetKeyword(currentKeyword)
            Log(currentKeywordForm)
            Log(currentKeyword)
            if currentKeyword != genericKeyword
                Form filledSpell = JMap.getForm(jSpellKeywordMap, currentKeyword)
                int keywordSpells = JMap.getObj(jKeywordMap, currentKeyword)
                JMap.setForm(jSpellKeywordMap, currentKeyword, filledSpell)
                JArray.addFromArray(jSupportedSpells, keywordSpells)
            endif
            currentKeyword = jMap.nextKey(jKeywordMap, currentKeyword)
        endwhile
        JArray.addFromArray(jSupportedSpells, JMap.getObj(jKeywordMap, genericKeyword))
        i += 1
    endwhile
    JDB.solveObjSetter(supportedSpellsKey, jSupportedSpells, true)
    JValue.release(jSupportedSpells)
EndFunction

Function SaveSupportedSpells()
    Log("Saving")
    int dataMap = JMap.object()
    int jSupportedSpells = JDB.solveObj(supportedSpellsKey)
    int keywordMap = JMap.object()
    JMap.setObj(keywordMap, "armorSpellKeyword", jSupportedSpells)
    JMap.setObj(dataMap, ".supportedSpells", keywordMap)
    ; JMap.setObj(dataMap, ".supportedSpells", jSupportedSpells)
    JValue.writeToFile(dataMap, "Data/MSR/Vanilla3.json")
EndFunction

Function UpdateDebuff()
    Log("Debuff reserved magicka: " + currentReservedMagicka)
    magickaDebuffSpell.SetNthEffectMagnitude(0, currentReservedMagicka)
    playerRef.RemoveSpell(magickaDebuffSpell)
    playerRef.AddSpell(magickaDebuffSpell, false)
    
    int thresholdCheck = JArray.count(JDB.solveObj(maintainedSpellsKey)) - JDB.solveInt(configKey + "perSpellThreshold")
    if thresholdCheck < 0
        thresholdCheck = 0       
    endif
    playerRef.RemoveSpell(mentalLoadDebuffs[0])
    playerRef.RemoveSpell(mentalLoadDebuffs[1])
    int debuffIndex = JDB.solveInt(configKey + "perSpellDebuffType")
    mentalLoadDebuffs[debuffIndex].SetNthEffectMagnitude(0, JDB.solveFlt(configKey + "perSPellDebuffAmount") * thresholdCheck)
    playerRef.AddSpell(mentalLoadDebuffs[debuffIndex])
EndFunction

Function UpdateReservedMagicka(int amount)
    Log("Current reserved magicka: " + currentReservedMagicka)
    currentReservedMagicka += amount * (JDB.solveFlt(configKey + "reserveMultiplier")/100)
    if currentReservedMagicka < 1 && currentReservedMagicka > -1
        currentReservedMagicka = 0
    elseif currentReservedMagicka < 0
        currentReservedMagicka = 0
    endif
    currentReservedMagicka = Math.Floor(currentReservedMagicka)
EndFunction

Function ToggleSpellOn(Spell akSpell)
    __ToggleSpellOn(akSpell)
EndFunction

Function __ToggleSpellOn(Spell akSpell)
    GoToState("ProcessingSpell")
    int spellCost = akSPell.GetEffectiveMagickaCost(playerRef)
    Log("Spell cost: " + spellCost)
    
    int i = 0
    MagicEffect[] spellEffects = akSpell.GetMagicEffects()
    while i < spellEffects.Length
        Log("Setting Effect " + i + " Duration")
        ResolveKeywordedMagicEffect(akSpell.GetNthEffectMagicEffect(i), akSpell)
        akSpell.SetNthEffectDuration(i, spellDurationSeconds)
        i += 1
    endwhile

    UpdateReservedMagicka(spellCost)
    playerRef.RestoreActorValue("Magicka", spellCost)
    jFormMap.setInt(jSpellCostMap, akSpell, spellCost)

    playerRef.DispelSpell(akSpell)
    Utility.Wait(0.1)
    akSpell.Cast(playerRef)
    int jMaintainedSpells = JDB.solveObj(maintainedSpellsKey, JArray.object())
    JArray.addForm(jMaintainedSpells, akSpell)
    JDB.solveObjSetter(maintainedSpellsKey, jMaintainedSpells, true)
    UpdateDebuff()
    GoToState("")
EndFunction

Function ResolveKeywordedMagicEffect(MagicEffect akEffect, Spell akSpell)
    int i = 0
    while i < akEffect.GetNumKeywords()
        string effectKeyword = akEffect.GetNthKeyword(i).GetString()
        Log("Checking Keyword: " + effectKeyword)
        int keyArray = JMap.allKeys(jSpellKeywordMap)
        if JArray.findStr(keyArray, effectKeyword) != -1
            Log("Supported Keyword Found")
            Form checkSpellForm = JMap.getForm(jSpellKeywordMap, effectKeyword)
            if checkSpellForm != None
                __ToggleSpellOff(checkSpellForm as Spell)
            endif
            JMap.setForm(jSpellKeywordMap, effectKeyword, akSpell)
        endif
        i += 1
    endwhile
EndFunction

Function ToggleSpellOff(Spell akSpell)
    __ToggleSpellOff(akSpell)
EndFunction

Function __ToggleSpellOff(Spell akSpell)
    GoToState("ProcessingSpell")
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
    GoToState("")
EndFunction

Function RemoveAllSpells()
    int jMaintainedSpells = JDB.solveObj(maintainedSpellsKey)
    JValue.retain(jMaintainedSpells)
    int i = 0
    while i < JArray.count(jMaintainedSpells)
        __ToggleSpellOff(JArray.getForm(jMaintainedSpells, i) as Spell)
        i += 1
    endwhile
    jValue.release(jMaintainedSpells)
EndFunction

State ProcessingSpell
    Function ToggleSpellOn(Spell akSpell)
        Log("Already Procesing Spell")
    EndFunction
    Function ToggleSpellOff(Spell akSpell)
        Log("Already Processing Spell")
    EndFunction
EndState