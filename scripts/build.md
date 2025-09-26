Build instructions for producing packages that can be deployed.

Most of the process is described in detail in [official Krita docs](https://docs.krita.org/sl/untranslatable_pages/building_krita.html). This is a condensed version with some hints to resolved common issues, and the extra steps to package the plugin.

## Linux

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
./bin/run_container krita-deps krita-auto-1

# if error gathering device information while adding custom device "/dev/dri": no such file or directory:
sudo modprobe vgem

# enter docker
./bin/enter
```

Prepare build inside docker:
```sh
# build vulkan
source ~/persistent/krita/plugins/krita-ai-tools/scripts/build-vulkan.sh

# configure Krita
cd appimage-workspace/krita-build/

# clean
rm -r ../krita.appdir

# debug build (for development only)
run_cmake.sh ~/persistent/krita

# release build (use this for packages)
cmake ~/persistent/krita -DCMAKE_INSTALL_PREFIX=$KRITADIR -DCMAKE_BUILD_TYPE=Release -DPYQT_SIP_DIR_OVERRIDE=~/appimage-workspace/deps/usr/share/sip
```

Build & test:
```sh
# build
make -j8 install

# copy plugin binaries out of docker environment
# from there they can be symlinked to ~/.local/krita/pykrita and tested with official AppImage
cp -R ../krita.appdir/usr/krita-vision-tools ~/persistent/

# (optional) start the custom built Krita from inside docker
../krita.appdir/usr/bin/krita
```

Package outside of docker:
```sh
cd $KRITA_DIR/persistent/krita-ai-tools
./../../krita/plugins/krita-vision-tools/scripts/package.sh X.Y.Z
```