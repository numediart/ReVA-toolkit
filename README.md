# ReVA-toolkit

Open-source avatar for real-time
human-agent interaction applications.

This is an attempt to respond to the need of the scientific community for an open-source, free of use, efficient virtual agent flexible enough to be used in projects varying from rapid prototyping and system testing to entire HAI applications and experiments.

## Installation

This project is using python3 (pre-processing of motion-capture) and [godot engine](http://godotengine.org).

### Python dependencies

```python
$ pip install numpy
$ pip install pyosc
```
### Godot installation

To edit the avatar, you need to recompile godot engine with an extra module for OSC.

On **Linux**, first install [godot dependencies](https://docs.godotengine.org/en/latest/development/compiling/) and run `install.sh` to install and compile godot. The bash file already contains all the command lines here below. The script will create a *forge.godot* folder in your user home directory, download, compile and run the godot project.

For Windows & OSX, you will need to:

- download source code of godot from github

```bash
$ git clone git@github.com:godotengine/godot.git godot
```
- download source code of OSC module for godot in *modules* folder and run install script

```bash
$ cd godot/modules/
$ git clone git@gitlab.com:frankiezafe/gosc.git gsoc
$ cd gsoc
$ python install.py
```

- install dependencies of godot, see [official docs](https://docs.godotengine.org/en/latest/development/compiling/)
- recompile godot

```bash
$ cd ../../
$ scons platform=[your OS: win, x11 or osx]
```

This will generate an executable in the folder *bin*. It will be name *godot.[your OS].tools.[your OS bites]*, typically *godot.x11.tools.64* for linux.

Now you can download the source of this repository.

```bash
$ cd ~
$ cd git clone git@github.com:numediart/ReVA-toolkit.git
```

Once done, run your local version of godot, import *project.godot* and run it.

## OpenFace Python

To control the avatar in realtime with OpenFace, clone this [repository](https://github.com/numediart/OpenFace) and follow the instructions at the top of the readme.

### how to record files for ReVA

After compilation of Openface, launch **FeatureExtraction**, located in folder build/bin, with these arguments

```bash
./FeatureExtraction -2Dfp -3Dfp -pose -gaze -aus -device 0
```

This will generate a csv in the folder **processed** next to the application.

Once generated, edit **python/openface_json.py** in this repository and adapt these variables:

```python
CSV_PATH = [path to the csv generated by FeatureExtraction]
JSON_PATH = [path of the json that will be generated by the script]
```

For consitency, set the json to **godot/assets/json/[name].json**. It already contains openface json's.

Repeat these steps for each csv generated.

To load the files in godot, use:

```bash
./launch
```

to open the project in godot. Play the project ( 'play' icon at the top right of the interface ), and use **load** button in the main panel.

You can keep the application running while you generate files.