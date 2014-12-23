
rm -rf Resources
cp -R RawResources/ Resouces/
ibtool --compile ./Resources/Main.storyboardc ../Anime/Base.lproj/Main.storyboard
ibtool --compile ./Resources/LaunchScreen.nib ../Anime/Base.lproj/LaunchScreen.xib
