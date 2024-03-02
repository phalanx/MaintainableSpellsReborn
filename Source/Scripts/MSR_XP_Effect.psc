Scriptname MSR_XP_Effect extends ActiveMagicEffect

int jMaintainedSpells = 0
int jMaintainedConjurationSpells = 0
MSR_Main_Quest Property MSR_Main Auto
GlobalVariable Property GameDaysPassed Auto

Function Log(string msg)
    MSR_Main.Log("XP Effect - " + msg)
EndFunction

Event OnEffectStart(Actor akTarget, Actor akCaster)
    Log("Started")
    float lastXPGain = JDB.solveFlt(".MSR.lastXPGain", -1)
    float currentGameDaysPassed = GameDaysPassed.GetValue()
    float xpGainDelay = JDB.solveFlt(".MSR.Config.xpGainDelay", 1.0)
    Log("XP Gain Delay: " + xpGainDelay)
    Log("Last XP Gain Time: " + lastXPGain)
    Log("Current Game Days Passed: " + currentGameDaysPassed)

    if (currentGameDaysPassed - lastXPGain) > xpGainDelay
        ProcessMaintainedSpells()
        ProcessConjurationSpells()
        JDB.solveFltSetter(".MSR.lastXPGain", currentGameDaysPassed, true)
    endif
EndEvent

Function ProcessMaintainedSpells()
    jMaintainedSpells = JDB.solveObj(".MSR.maintainedSpells")
    if jMaintainedSpells != 0 && JFormMap.count(jMaintainedSpells) > 0
        Spell nextKey = JFormMap.nextKey(jMaintainedSpells) as Spell
        while nextKey != None
            Log("Processing " + nextKey.GetName())
            int jSpellData = JFormMap.getObj(jMaintainedSpells, nextKey)
            String school = nextKey.GetNthEffectMagicEffect(0).GetAssociatedSkill()
            Log("    Associated Skill: " + school )
            float xpToGain = (JMap.GetFlt(jSpellData, "SpellCost") * JDB.solveFlt(".MSR.Config.xpMultiplier", 1.0))
            Log("    XP To Gain: " + xpToGain)
            Game.AdvanceSkill(school, xpToGain)
            nextKey = JFormMap.nextKey(jMaintainedSpells, nextKey) as Spell
        endwhile
    endif
EndFunction

Function ProcessConjurationSpells()
    jMaintainedConjurationSpells = JDB.solveObj(".MSR.MaintainedConjurationsKey")
    if jMaintainedConjurationSpells != 0 && JFormMap.count(jMaintainedConjurationSpells) > 0
        Form nextKey = JFormMap.nextKey(jMaintainedConjurationSpells)
        while nextKey != None
            int jSpellData = JFormMap.getObj(jMaintainedConjurationSpells, nextKey)
            Spell conjuringSpell = JMap.getForm(jSpellData, "conjuringSpell") as Spell
            Log("Processing " + conjuringSpell.GetName())
            String school = conjuringSpell.GetNthEffectMagicEffect(0).GetAssociatedSkill()
            Log("    Associated Skill: " + school )
            float xpToGain = (JMap.GetFlt(jSpellData, "SpellCost") * JDB.solveFlt(".MSR.Config.xpMultiplier", 1.0))
            Log("    XP To Gain: " + xpToGain)
            Game.AdvanceSkill(school, xpToGain)
            nextKey = JFormMap.nextKey(jMaintainedConjurationSpells, nextKey)
        endwhile
    endif
EndFunction