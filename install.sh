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
# installing dependencies (debian based distro)
sudo apt-get install build-essential scons pkg-config libx11-dev libxcursor-dev libxinerama-dev libgl1-mesa-dev libglu-dev libasound2-dev libpulse-dev libudev-dev libxi-dev libxrandr-dev yasm
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