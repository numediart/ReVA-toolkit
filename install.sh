#!/bin/bash

# removal of previous installation
rm -rf forge.godot
# preparation of godot engine recompilation
mkdir forge.godot
cd forge.godot
# getting godot engine
git clone git@github.com:godotengine/godot.git godot
# getting gosc module
cd godot/modules
git clone git@gitlab.com:frankiezafe/gosc.git gosc
# running the installation of gosc
cd gosc
python install.py
# back to godot
cd ../../
# compilation
scons platform=x11 -j4
# engine is recompiled with gsoc module

# getting the lavatar project
cd ../
git clone git@gitlab.com:polymorphcool/lavatar.git
# launching lavatar
cd lavatar
chmod +x launch.sh
./launch.sh