# Lavatar

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

On **Linux**, run `install.sh` to install and compile godot. The bash file already contains all the command lines here below. The script will create a *forge.godot* folder in your user home directory, download, compile and run the godot project.

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
$ cd git clone git@gitlab.com:polymorphcool/lavatar.git
```

Once done, run your local version of godot, import *project.godot* and run it.