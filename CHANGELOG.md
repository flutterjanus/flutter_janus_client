## 2.3.1
- dependency upgrade and improvements
## 2.3.0
- breaking changes in createOffer and createAnswer (removed dead code prepareTransReceiver)
- fixed audio and video mute events not working due to #120 raised by @liemfs 

## 2.2.15
- added support for simulcasting in `initMediaDevice`
- flutter webrtc 0.9.34
## 2.2.14
- fix Searching transceivers returns wrong result [#120](https://github.com/flutterjanus/flutter_janus_client/pull/120)
## 2.2.13

- support for custom logger

## 2.2.12

- version downgrade for flutter_webrtc:0.9.22
## 2.2.11

- version downgrade for flutter_webrtc:0.9.22

## 2.2.10

- version bump for flutter_webrtc:0.9.24
## 2.2.9

- type fix in AudioBridgeLeavingEvent (leaving)

## 2.2.8

- sip plugin fixes (decline)
- sip example incoming call feature tested and verified

## 2.2.7

- Upgraded flutter_webrtc to fix #41 => audio input issue in ios devices
- improved videocall and audiobridge example with newer audio I/O apis by flutter_webrtc

## 2.2.6

- fix stringIds issue for AudioBridge

## 2.2.5

- fixes

## 2.2.4

- Fixed bugs in videocall example

- upgraded dependency

- fixed switchCamera utility function for browsers

## 2.2.3

- Added SipPluginWrapper and sip working example

- peer dependencies updated

## 2.2.2

- fixes issues related to apiSecret thanks goes to @baihua666 for spotting and fixing it.
- updated readme.
- updated peer dependencies.
- enhanced errorHandling support for wrapper plugins including (
  VideoRoom,AudioBridge,Streaming,VideoCall)

## 2.2.1

- fixes issues related to roomId type by converting roomId type to String
- updated documentation and fixed some docstrings
- introduced ScreenSharing example using video-room
- fixed minor bugs in examples when running on macos,linux and windows
- used transrecievers to mute and unmute tracks

## 2.2.0

- All major plugins fully support unified plan
- Typed examples updated with null safety and latest dart constraints
- Introduced plugin specific wrapper classes with respective operation methods for rich development
  experience
- Introduced typed events (Class Based Events) for brilliant auto completion support for IDE
- Supports null-safety

## 2.1.1-beta

- fixes and improvements due to null safety
- web demo setup using github pages

## 2.1.0-beta

- supports null safety

## 2.0.1-beta

- fixed issue #37
- introduced logger support for better plugin level log control

## 2.0.0-beta

- features brand new api
- simplified development using stream api

## 0.0.4

- Streaming Support added
- bug in send method fixed for rest api

## 0.0.3

- Complete Instagram Like Videocall example
- better garbage collection api

## 0.0.2

- Added Videocall example
- Updated WebRTC dependencies
- bug fixes and improvements

## 0.0.1

- initial Release
