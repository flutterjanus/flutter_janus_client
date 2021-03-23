[![ko-fi](https://www.ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/U7U11OZL8)  

<a href="https://www.buymeacoffee.com/gr20hjk" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" style="height: 51px !important;width: 217px !important;" ></a>
# janus_client
This branch features brand new API(v2) which is more fun to work with since it uses Stream API for exposing plugin level messages and events.  
Definitely, It gonna be  easy to maintain and test.
As of now VideoRoom works flawlessly support for other plugin are work in progress. 

**all dependencies updated**  
official janus plugin for flutter, can be considered as port of janusJs . It can be used to bring WebRTC wonders to your flutter application, So Dive Straight in.


## what is janus?
The Janus WebRTC Server has been conceived as a general purpose server. As such, it doesn't provide any functionality per se other than implementing the means to set up a WebRTC media communication with a browser, exchanging JSON messages with it, and relaying RTP/RTCP and messages between browsers and the server-side application logic they're attached to. Any specific feature/application needs to be implemented in server side plugins, that browsers can then contact via the Janus core to take advantage of the functionality they provide. Example of such plugins can be implementations of applications like echo tests, conference bridges, media recorders, SIP gateways and the like.
For more info visit  
[Janus: the general purpose WebRTC server](https://janus.conf.meetecho.com/)



# Video Call Sample
<a href='https://youtu.be/wRo5nd7JnB4'><img src='https://github.com/shivanshtalwar0/flutter_janus_client/raw/master/samples/videocall_preview.jpg' 
                                            width='300' height='600'></a>

## News & Updates
- Audio Bridge example ready with V2 API
- Supports WEB aswell
- Video Room Example ready with V2  API

## status
| Feature           | Support | Well Tested | Unified Plan |
|-------------------|---------|-------------|--------------|
| WebSocket         | Yes     | Yes         | -            |
| Rest/Http API     | Yes     | Yes         | -            |
| Video Room Plugin | Yes     | wip         | wip          |
| Video Call Plugin | Yes     | No          | wip          |
| Streaming Plugin  | Yes     | No          | Yes          |
| Audio Room Plugin | Yes     | No          | wip          |
| Sip Plugin        | Yes     | No          | No           |
| Text Room Plugin  | wip     | No          | wip          |

# Getting Started
[VideoRoom_V2 Example](https://github.com/flutterjanus/flutter_janus_client/blob/v2/example/lib/VideoRoom_V2.dart)
[AudioRoom_V2 Example](https://github.com/flutterjanus/flutter_janus_client/blob/v2/example/lib/AudioRoom_V2.dart)  

