#! /bin/bash
declare -a langs=("CHINESE" "FRENCH" "GERMAN" "ITALIAN" "JAPANESE" "POLISH" "RUSSIAN" "SPANISH")
if [[ "$1" == "create" ]]; then
    for lang in "${langs[@]}"; do
        cp Interface/Translations/MaintainableSpellsReborn_ENGLISH.txt Interface/Translations/MaintainableSpellsReborn_$lang.txt
    done
fi

if [[ "$1" == "remove" ]]; then
    for lang in "${langs[@]}"; do
        rm -f Interface/Translations/MaintainableSpellsReborn_$lang.txt
    done
fi