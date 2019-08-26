#!/bin/bash

# preparation of godot engine recompilation
cd ~
mkdir forge.godot
cd forge.godot
# getting godot engine
git clone git@github.com:godotengine/godot.git godot
# getting gosc module
cd godot/modules
git clone git@gitlab.com:frankiezafe/gosc.git gsoc
# running the installation of gosc
cd gosc
python3 install.py
# back to godot
cd ~/forge.godot/godot
# installing dependencies (debian based distro)
sudo apt-get install build-essential scons pkg-config libx11-dev libxcursor-dev libxinerama-dev libgl1-mesa-dev libglu-dev libasound2-dev libpulse-dev libudev-dev libxi-dev libxrandr-dev yasm
# compilation
scons platform=x11
# engine is recompiled with gsoc module

# getting the lavatar project
cd ~/forge.godot/
git clone git@gitlab.com:polymorphcool/lavatar.git
# launching lavatar
cd lavatar
chmod +x launch.sh
./launch.sh