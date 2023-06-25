# Check initial conditions
if [[ $EUID -eq 0 ]]; then
  echo "[!] Please don't run this script as root!"
  exit
fi
if [[ $(command -v sudo -u brew) == "" ]]; then
    echo "[!] Hombrew not installed!"
    echo "[!] Please run the following command!"
    echo '[!] /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"'
    exit
else
    echo "[§] Found Homebrew"
    if brew ls --versions ldid > /dev/null; then
      echo "[§] Found ldid"
    else
      echo "[!] ldid not found!"
      echo "[!] Please install ldid with the following command"
      echo "[!] brew install ldid"
    fi
fi

# Prepare payload directory
SCRIPT_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
rm -rf $SCRIPT_DIR/../CyberKit/CyberKitBuild/Fennec-iphoneos/Payload
ipa=$SCRIPT_DIR/../CyberKit/CyberKitBuild/Fennec-iphoneos/Client.app
if [[ $ipa == *.ipa ]]; then
echo [*] unpacking..
cd $(dirname $ipa)
unzip "$ipa"
cd Payload
app=$(ls -1 -d *.app)
elif [[ $ipa == *.app ]]; then
cd $(dirname $ipa)
mkdir Payload
cp -R $ipa $(dirname $ipa)/Payload
app=$(ls -1 -d *.app)
cd Payload
rm -rf $app/Frameworks/CyberKit.framework/XPCServices && mkdir $app/Frameworks/CyberKit.framework/XPCServices
rm -rf $app/Frameworks/CyberKit.framework/Daemons && mkdir $app/Frameworks/CyberKit.framework/Daemons
cp -R ../../Debug-iphoneos/*.xpc $app/Frameworks/CyberKit.framework/XPCServices
cp ../../Debug-iphoneos/adattributiond $app/Frameworks/CyberKit.framework/Daemons
cp ../../Debug-iphoneos/webpushd $app/Frameworks/CyberKit.framework/Daemons
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
echo "[1/19] Fakesigning com.matthewbenedict.CyberKit.GPU.xpc"
ldid -S"script_fakesigner.entitlements" "$app/Frameworks/CyberKit.framework/XPCServices/com.matthewbenedict.CyberKit.GPU.xpc"
echo "[2/19] Fakesigning com.matthewbenedict.CyberKit.Networking.xpc"
ldid -S"script_fakesigner.entitlements" "$app/Frameworks/CyberKit.framework/XPCServices/com.matthewbenedict.CyberKit.Networking.xpc"
echo "[3/19] Fakesigning com.matthewbenedict.CyberKit.WebContent.CaptivePortal.xpc"
ldid -S"script_fakesigner.entitlements" "$app/Frameworks/CyberKit.framework/XPCServices/com.matthewbenedict.CyberKit.WebContent.CaptivePortal.xpc"
echo "[4/19] Fakesigning com.matthewbenedict.CyberKit.WebContent.Crashy.xpc"
ldid -S"script_fakesigner.entitlements" "$app/Frameworks/CyberKit.framework/XPCServices/com.matthewbenedict.CyberKit.WebContent.Crashy.xpc"
echo "[5/19] Fakesigning com.matthewbenedict.CyberKit.WebContent.Development.xpc"
ldid -S"script_fakesigner.entitlements" "$app/Frameworks/CyberKit.framework/XPCServices/com.matthewbenedict.CyberKit.WebContent.Development.xpc"
echo "[6/19] Fakesigning com.matthewbenedict.CyberKit.WebContent.xpc"
ldid -S"script_fakesigner.entitlements" "$app/Frameworks/CyberKit.framework/XPCServices/com.matthewbenedict.CyberKit.WebContent.xpc"
echo "[7/19] Fakesigning libANGLE-shared.dylib"
ldid -S"script_fakesigner.entitlements" "$app/Frameworks/libANGLE-shared.dylib"
echo "[8/19] Fakesigning libwebrtc.dylib"
ldid -S"script_fakesigner.entitlements" "$app/Frameworks/libwebrtc.dylib"

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
rm *.deb
DIR_NAME=$1
DEBIAN_FILES=$SCRIPT_DIR/resources/$DIR_NAME
if [[ "$DIR_NAME" == *"+"* ]]; then
    APPLICATION_PATH=$DIR_NAME/Applications
else
    APPLICATION_PATH=$DIR_NAME/var/jb/Applications
fi

# Package into DEB
echo "[*] Creating DEB..."
mkdir $DIR_NAME
if [[ "$DIR_NAME" != *"+"* ]]; then
    mkdir $DIR_NAME/var
    mkdir $DIR_NAME/var/jb
fi
mv Payload $APPLICATION_PATH
mkdir $DIR_NAME/DEBIAN
cp $DEBIAN_FILES/control $DIR_NAME/DEBIAN
cp $DEBIAN_FILES/postinst $DIR_NAME/DEBIAN
find . -name ".DS_Store" -delete && \
dpkg-deb -b $DIR_NAME && dpkg-name $DIR_NAME.deb
mv $APPLICATION_PATH Payload
rm -rf $DIR_NAME

# Package into IPA
echo "[*] Creating IPA..."
rm -f "$ipa.ipa" || true
zip -r -y "$ipa.ipa" Payload
echo "[*] Created $ipa.ipa"
