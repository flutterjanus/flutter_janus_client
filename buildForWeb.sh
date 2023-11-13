pwd=`pwd`
cd example/
flutter build web --base-href "/flutter_janus_client/example/build/web/#/"
cd $pwd
dart doc .
