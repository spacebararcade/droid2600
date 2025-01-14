#!/bin/bash

# build.sh
#
# Build script. Options: 
#     r build a release (clean, compile, sign)
#     cc only compile c sources
#     cj only compile java sources
#     t test build (compile, sign, install)
#     i install only
#     clean

export PATH=$PATH:~/soft/android-ndk
export PATH=$PATH:/home/trent/soft/android-sdk/build-tools/25.0.2/
DROIDSDL_DIR=../droidSDL
KEYSTORE=droid2600.keystore

function checkDroidSDLVersion() {
    REQUIRED_VERSION=`cat ./droidsdl.version`
    CHECK_STRING="android:versionName=\"$REQUIRED_VERSION\""
    OUTPUT=`grep "$CHECK_STRING" ../droidSDL/AndroidManifest.xml`
    if [ "$OUTPUT" == "" ]; then
        echo "Requires DroidSDL v$REQUIRED_VERSION"
        echo "Check that ./droidsdl.version and ../droidSDL/AndroidManifest.xml are set correctly"
        exit 1
    fi
}

function cleanProject() {
    rm -rf ../droidSDL/bin/ ../droidSDL/gen/ 
    rm -rf bin gen obj libs
}

function checkSdlLinks {
    # if the symlinks already exist then we are done
    if [ -h "./jni/sdl" ] \
            && [ -h "./jni/sdl_main" ] \
            && [ -h "./jni/sdl_blitpool" ] \
            && [ -h "./jni/stlport" ]; then
        echo "DroidSDL native sources already linked"
        return;
    fi 

    # test if the source files are where we expect them to be 
    # if not, we will print an error and exit
    if [ -d "$DROIDSDL_DIR/jni/sdl" ] \
            && [ -d "$DROIDSDL_DIR/jni/sdl_main" ] \
            && [ -d "$DROIDSDL_DIR/jni/sdl_blitpool" ] \
            && [ -d "$DROIDSDL_DIR/jni/stlport" ]; then
        ln -s "../$DROIDSDL_DIR/jni/sdl" ./jni/sdl
        ln -s "../$DROIDSDL_DIR/jni/sdl_main" ./jni/sdl_main
        ln -s "../$DROIDSDL_DIR/jni/sdl_blitpool" ./jni/sdl_blitpool
        ln -s "../$DROIDSDL_DIR/jni/stlport" ./jni/stlport
        echo "Created links to DroidSDL native sources"
    else
        echo "Cannot find droidSDL sources.. exit"
        exit -1
    fi
}

function ccompile {
    checkSdlLinks;
    ndk-build V=1
}

function jcompile {
    # work-around for bug in android development chain where the "libs" directory 
    # must exist in a library project folder.
    mkdir -p $DROIDSDL_DIR/libs
    ant release 
}

function signApp {
    rm bin/Droid2600.apk
    jarsigner -verbose -keystore $KEYSTORE bin/Droid2600-release-unsigned.apk droid2600
    jarsigner -verify bin/Droid2600-release-unsigned.apk
    zipalign -v 4 bin/Droid2600-release-unsigned.apk bin/Droid2600.apk
}

function installApp {
    #adb -d uninstall com.droid2600
    adb -d install  -r bin/Droid2600.apk
}

function showHelp {
    echo "usage: build.sh <arg>, where <arg> is one of:"
    echo "    clean : clean all objects"
    echo "    r     : build a release (clean, compile, sign)"
    echo "    cc    : compile c sources"
    echo "    j     : compile java sources"
    echo "    t     : test build (clean, compile, sign, install)"
    echo "    i     : install apk"
    echo "    h     : show this message"
    echo "    s     : sign app"
}

checkDroidSDLVersion;

case "$1" in
    clean)
        cleanProject;
        ;;
    r)
        cleanProject;
        ccompile;
        jcompile;
        signApp;
        ;;
    cc)
        ccompile;
        ;;
    j)
        jcompile;
        ;;
    t)
        ccompile;
        jcompile;
        signApp;
        installApp;
        ;;
    i)
        installApp;
        ;;
    s)
        signApp;
        ;;
    *)
        showHelp;
        ;;
esac

