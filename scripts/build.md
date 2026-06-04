Build instructions for producing packages that can be deployed.

Most of the process is described in detail in [official Krita docs](https://docs.krita.org/sl/untranslatable_pages/building_krita.html). This is a condensed version with some hints to resolved common issues, and the extra steps to package the plugin.

## Linux

Follow guide or the readme at https://invent.kde.org/dkazakov/krita-docker-env

For Qt6 build, make sure to use the Qt6 deps branch:
```sh
./bin/bootstrap-deps.sh -b transition.now/qt6
```

Prepare docker environment:

```sh
KRITA_DIR=~/krita-auto-1

# update krita repo in persistent
cd $KRITA_DIR/persistent/krita
git fetch origin
git stash save
git checkout RELEASETAG
git stash pop

# patch lut.h if needed
# https://invent.kde.org/graphics/krita/-/merge_requests/2296

# update plugin repo
cd $KRITA_DIR/persistent/krita/plugins/krita-vision-tools
git pull

# update docker image repo
cd $KRITA_DIR
git fetch origin
git stash save
git pull
git stash pop

# build image
./bin/build_image krita-deps

# if XAUTHORITY or PulseAudio hang/errors:
#   comment out related lines in scripts

# run container
./bin/run_container krita-deps krita

# if error gathering device information while adding custom device "/dev/dri": no such file or directory:
sudo modprobe vgem

# enter docker
./bin/enter
```

Prepare build inside docker:
```sh
# build vulkan
source ~/persistent/krita/plugins/krita-vision-tools/scripts/build-vulkan.sh

# configure Krita
cd appimage-workspace/krita-build/

# clean
rm -r ../krita.appdir
rm -r $KRITADIR/krita-vision-tools

# debug build (for development only)
run_cmake.sh ~/persistent/krita

# release build (use this for packages)
# .. for Krita 5.3.x (Qt5)
cmake ~/persistent/krita -DCMAKE_INSTALL_PREFIX=$KRITADIR -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=~/appimage-workspace/deps/usr/share/sip 
# .. for Krita 6.x (Qt6)
cmake ~/persistent/krita -DCMAKE_INSTALL_PREFIX=$KRITADIR -DCMAKE_BUILD_TYPE=Release -DBUILD_WITH_QT6=ON -DALLOW_UNSTABLE=QT6
```

Build & test:
```sh
# build
make -j8 install

# copy plugin binaries out of docker environment
# from there they can be symlinked to ~/.local/share/krita/pykrita and tested with official AppImage
cp -R ../krita.appdir/usr/krita-vision-tools ~/persistent/

# (optional) start the custom built Krita from inside docker
../krita.appdir/usr/bin/krita
```

Link as user plugin outside of docker so it can be tested with official AppImage
```sh
cd ~/.local/share/krita/pykrita
rm vision_tools*
ln -s $KRITA_DIR/persistent/krita-vision-tools/vision_tools
ln -s $KRITA_DIR/persistent/krita-vision-tools/vision_tools.desktop
```

Package outside of docker:
```sh
cd $KRITA_DIR/persistent/krita-vision-tools
../krita/plugins/krita-vision-tools/scripts/package.sh X.Y.Z
```


## Windows

Follow https://docs.krita.org/en/untranslatable_pages/building_krita.html#building-on-windows

### Dependencies for Qt6

After cloning `krita-deps-management`, switch it to the Qt6 branch (or do it during the clone).
Also supply the branch name to the dependency python script.

```sh
cd krita-deps-management
git checkout transition.now/qt6

cd ..
python krita-deps-management\tools\setup-env.py -b transition.now/qt6 --full-krita-env -v PythonEnv -p C:\dev\llvm-mingw\bin -p C:\dev\llvm-mingw\x86_64-w64-mingw32\bin -p C:\dev\tools
```

### Configure

```sh
cd b_krita

# .. for Krita 5.3 (Qt5)
cmake ../krita -DCMAKE_INSTALL_PREFIX=C:/dev/krita/_install -G Ninja -DCMAKE_BUILD_TYPE=Release

# .. for Krita 6 (Qt6)
cmake ../krita -DCMAKE_INSTALL_PREFIX=C:/dev/krita/_install -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_WITH_QT6=ON -DALLOW_UNSTABLE=QT6
```

If there are issues with SIP project version: exclude SIP generation in `plugins/extensions/pykrita/sip/CMakeLists.txt`:
```cmake
# add_sip_python_module_v5(PyKrita.krita ./krita/kritamod.sip kritalibkis kritaui kritaimage kritalibbrush)
```

### Test & Package

Link:
```ps1
cd $ENV:APPDATA\krita\pykrita
New-Item -Value $ENV:KRITA_DIR\_install\krita-vision-tools\vision_tools -ItemType SymbolicLink -Path vision_tools
New-Item -Value $ENV:KRITA_DIR\_install\krita-vision-tools\vision_tools.desktop -ItemType SymbolicLink -Path vision_tools.desktop
```

Package:
```sh
cd _install\krita-vision-tools
..\..\krita\plugins\krita-vision-tools\scripts\package.ps1 X.Y.Z
```