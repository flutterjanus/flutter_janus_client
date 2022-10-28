pwd=`pwd`
cd example/
flutter build web --base-href "/flutter_janus_client/example/build/web/#/"
dart doc .
cd $pwd