# Check initial conditions
if [[ $EUID -eq 0 ]]; then
    echo "[!] Please don't run this script as root!"
    exit
fi
if [[ $(command -v sudo -u brew) == "" ]]; then
    echo "[!] Homebrew not installed!"
    echo "[!] Please run the following command!"
    echo '[!] /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"'
    exit
else
    echo "[§] Found Homebrew"
    if brew ls --versions ldid >/dev/null; then
        echo "[§] Found ldid"
    else
        echo "[§] Attempting to install script dependencies"
        brew install ldid gnu-sed dpkg
    fi
fi

# Prepare payload directory
SCRIPT_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
rm -rf $SCRIPT_DIR/../CyberKit/CyberKitBuild/Fennec-iphoneos/Payload
ipa=$SCRIPT_DIR/../CyberKit/CyberKitBuild/Fennec-iphoneos/Client.app
if [[ $ipa == *.ipa ]]; then
    echo [*] unpacking..
    cd $(dirname $ipa) || exit 1
    unzip "$ipa"
    cd Payload
    app=$(ls -1 -d *.app)
elif [[ $ipa == *.app ]]; then
    cd $(dirname $ipa) || exit 1
    mkdir Payload
    cp -R $ipa $(dirname $ipa)/Payload
    app=$(ls -1 -d *.app)
    cd Payload
    rm -rf $app/Frameworks/CyberKit.framework/XPCServices && mkdir $app/Frameworks/CyberKit.framework/XPCServices
    rm -rf $app/Frameworks/CyberKit.framework/Daemons && mkdir $app/Frameworks/CyberKit.framework/Daemons
    cp -R ../../Production-iphoneos/*.xpc $app/Frameworks/CyberKit.framework/XPCServices
    cp ../../Production-iphoneos/adattributiond $app/Frameworks/CyberKit.framework/Daemons
    cp ../../Production-iphoneos/webpushd $app/Frameworks/CyberKit.framework/Daemons
    cp ../../../Source/WTF/icu/unicode/data/out/*.dat $app/Frameworks/CyberKit.framework/XPCServices
    ln -s ../../Frameworks $app/Plugins/CredentialProvider.appex
    ln -s ../../Frameworks $app/Plugins/NotificationService.appex
    ln -s ../../Frameworks $app/Plugins/ShareTo.appex
    ln -s ../../Frameworks $app/Plugins/WidgetKitExtension.appex
    ln -s ../../../../Frameworks $app/Frameworks/CyberKit.framework/XPCServices/com.matthewbenedict.CyberKit.GPU.xpc
    ln -s ../../../../Frameworks $app/Frameworks/CyberKit.framework/XPCServices/com.matthewbenedict.CyberKit.Networking.xpc
    ln -s ../../../../Frameworks $app/Frameworks/CyberKit.framework/XPCServices/com.matthewbenedict.CyberKit.WebContent.CaptivePortal.xpc
    ln -s ../../../../Frameworks $app/Frameworks/CyberKit.framework/XPCServices/com.matthewbenedict.CyberKit.WebContent.Crashy.xpc
    ln -s ../../../../Frameworks $app/Frameworks/CyberKit.framework/XPCServices/com.matthewbenedict.CyberKit.WebContent.Development.xpc
    ln -s ../../../../Frameworks $app/Frameworks/CyberKit.framework/XPCServices/com.matthewbenedict.CyberKit.WebContent.xpc
else
    echo "[!] No .ipa file supplied!"
fi
cp $SCRIPT_DIR/script_fakesigner.entitlements .

# Fakesign
echo "[1/19] Fakesigning libANGLE-shared.dylib"
ldid -S"script_fakesigner.entitlements" "$app/Frameworks/libANGLE-shared.dylib"
echo "[2/19] Fakesigning libwebrtc.dylib"
ldid -S"script_fakesigner.entitlements" "$app/Frameworks/libwebrtc.dylib"

echo "[3/19] Fakesigning com.matthewbenedict.CyberKit.GPU.xpc"
ldid -S"script_fakesigner.entitlements" "$app/Frameworks/CyberKit.framework/XPCServices/com.matthewbenedict.CyberKit.GPU.xpc"
echo "[4/19] Fakesigning com.matthewbenedict.CyberKit.Networking.xpc"
ldid -S"script_fakesigner.entitlements" "$app/Frameworks/CyberKit.framework/XPCServices/com.matthewbenedict.CyberKit.Networking.xpc"
echo "[5/19] Fakesigning com.matthewbenedict.CyberKit.WebContent.CaptivePortal.xpc"
ldid -S"script_fakesigner.entitlements" "$app/Frameworks/CyberKit.framework/XPCServices/com.matthewbenedict.CyberKit.WebContent.CaptivePortal.xpc"
echo "[6/19] Fakesigning com.matthewbenedict.CyberKit.WebContent.Crashy.xpc"
ldid -S"script_fakesigner.entitlements" "$app/Frameworks/CyberKit.framework/XPCServices/com.matthewbenedict.CyberKit.WebContent.Crashy.xpc"
echo "[7/19] Fakesigning com.matthewbenedict.CyberKit.WebContent.Development.xpc"
ldid -S"script_fakesigner.entitlements" "$app/Frameworks/CyberKit.framework/XPCServices/com.matthewbenedict.CyberKit.WebContent.Development.xpc"
echo "[8/19] Fakesigning com.matthewbenedict.CyberKit.WebContent.xpc"
ldid -S"script_fakesigner.entitlements" "$app/Frameworks/CyberKit.framework/XPCServices/com.matthewbenedict.CyberKit.WebContent.xpc"

echo "[9/19] Fakesigning CyberCore.framework"
ldid -S"script_fakesigner.entitlements" "$app/Frameworks/CyberCore.framework/CyberCore"
echo "[10/19] Fakesigning CyberKit.framework"
ldid -S"script_fakesigner.entitlements" "$app/Frameworks/CyberKit.framework/CyberKit"
echo "[11/19] Fakesigning CyberKitLegacy.framework"
ldid -S"script_fakesigner.entitlements" "$app/Frameworks/CyberKitLegacy.framework/CyberKitLegacy"
echo "[12/19] Fakesigning CyberScriptCore.framework"
ldid -S"script_fakesigner.entitlements" "$app/Frameworks/CyberScriptCore.framework/CyberScriptCore"
echo "[13/19] Fakesigning RustMozillaAppServices.framework"
ldid -S"script_fakesigner.entitlements" "$app/Frameworks/RustMozillaAppServices.framework/RustMozillaAppServices"
echo "[14/19] Fakesigning WebGPU.framework"
ldid -S"script_fakesigner.entitlements" "$app/Frameworks/WebGPU.framework/WebGPU"

echo "[15/19] Fakesigning CredentialProvider.appex"
ldid -S"script_fakesigner.entitlements" "$app/Plugins/CredentialProvider.appex/CredentialProvider"
echo "[16/19] Fakesigning NotificationService.appex"
ldid -S"script_fakesigner.entitlements" "$app/Plugins/NotificationService.appex/NotificationService"
echo "[17/19] Fakesigning ShareTo.appex"
ldid -S"script_fakesigner.entitlements" "$app/Plugins/ShareTo.appex/ShareTo"
echo "[18/19] Fakesigning WidgetKitExtension.appex"
ldid -S"script_fakesigner.entitlements" "$app/Plugins/WidgetKitExtension.appex/WidgetKitExtension"
echo "[19/19] Fakesigning Client"
ldid -S"script_fakesigner.entitlements" "$app/${app:0:${#app}-4}"
rm script_fakesigner.entitlements

# Setup for DEB packaging
cd ..
rm -f *.deb || true
DIR_NAME=$1
if [[ "$DIR_NAME" == *"+"* ]]; then
    if [[ ${DIR_NAME#*+} -le 10 ]]; then
        # We manually stash CyberKit on legacy iOS because it doesn't fit in the root partition
        echo "[*] Using stashed application path"
        APPLICATION_PATH=$DIR_NAME/private/var/containers/Bundle/Application/DEADBEEF-DEAD-BEEF-DEAD-BEEFC1B34800
    else
        # Put CyberKit in the rootful application path
        echo "[*] Using rootful application path"
        APPLICATION_PATH=$DIR_NAME/Applications
    fi
else
    echo "[*] Using rootless application path"
    APPLICATION_PATH=$DIR_NAME/private/var/jb/Applications
fi

# Package into DEB
echo "[*] Creating DEB..."
DEBIAN_FILES=$SCRIPT_DIR/resources/$DIR_NAME
mkdir $DIR_NAME
if [[ "$DIR_NAME" == *"+"* ]] && [[ ${DIR_NAME#*+} -le 10 ]]; then
    mkdir $DIR_NAME/private
    mkdir $DIR_NAME/private/var
    mkdir $DIR_NAME/private/var/containers
    mkdir $DIR_NAME/private/var/containers/Bundle
    mkdir $DIR_NAME/private/var/containers/Bundle/Application
elif [[ "$DIR_NAME" != *"+"* ]]; then
    mkdir $DIR_NAME/private
    mkdir $DIR_NAME/private/var
    mkdir $DIR_NAME/private/var/jb
fi

mv Payload $APPLICATION_PATH
mkdir $DIR_NAME/DEBIAN
cp -R $DEBIAN_FILES/* $DIR_NAME/DEBIAN
find . -name ".DS_Store" -delete

if [[ "$DIR_NAME" == *"+"* ]] && [[ ${DIR_NAME#* } -le 10 ]]; then
    cp $SCRIPT_DIR/uicache/cyberuicache $APPLICATION_PATH
    cp $SCRIPT_DIR/uicache/.com.apple.mobile_container_manager.metadata.plist $APPLICATION_PATH
    echo "[*] Forcing gzip compression for legacy iOS"
    dpkg-deb -Zgzip --build $DIR_NAME && dpkg-name $DIR_NAME.deb
else
    echo "[*] Using default compression for non-legacy iOS"
    dpkg-deb -b $DIR_NAME && dpkg-name $DIR_NAME.deb
fi
mv $APPLICATION_PATH Payload
rm -rf $DIR_NAME

# Package into IPA
IPA_NAME=$(echo *.deb | sed 's/_[a-z].*//' | sed 's/\+\([0-9]\)/\1/' | sed 's/-\([0-9]\)/\1/')
echo "[*] Creating IPA..."
rm -f *.tipa || true
zip -r -y "$IPA_NAME.tipa" Payload
echo "[*] Created $IPA_NAME.tipa"
