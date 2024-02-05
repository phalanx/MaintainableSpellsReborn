#!/bin/bash

function serialize(){
    spriggit serialize -i ./MaintainableSpellsReborn.esp -o ./ESP/MaintainableSpellsReborn -g SkyrimSE --PackageName Spriggit.Yaml &
}

function deserialize(){
    spriggit deserialize -o ./MaintainableSpellsReborn.esp -i ./ESP/MaintainableSpellsReborn --PackageName Spriggit.Yaml &
}

if [[ "$1" == "serialize" ]]; then
    serialize
elif [[ "$1" == "deserialize" ]]; then
    deserialize
fi

wait