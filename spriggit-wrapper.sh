#!/bin/bash

function serialize(){
    spriggit serialize -i ./ChildrenOfLilith.esp -o ./ESP/ChildrenOfLilith -g SkyrimSE --PackageName Spriggit.Yaml &
}

function deserialize(){
    spriggit deserialize -o ./ChildrenOfLilith.esp -i ./ESP/ChildrenOfLilith --PackageName Spriggit.Yaml &
}

if [[ "$1" == "serialize" ]]; then
    serialize
elif [[ "$1" == "deserialize" ]]; then
    deserialize
fi

wait