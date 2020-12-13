[![ko-fi](https://www.ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/U7U11OZL8)  

<a href="https://www.buymeacoffee.com/gr20hjk" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" style="height: 51px !important;width: 217px !important;" ></a>
# janus_client
**all dependencies updated**  
official janus plugin for flutter, can be considered as port of janusJs . It can be used to bring WebRTC wonders to your flutter application, So Dive Straight in.


## what is janus?
The Janus WebRTC Server has been conceived as a general purpose server. As such, it doesn't provide any functionality per se other than implementing the means to set up a WebRTC media communication with a browser, exchanging JSON messages with it, and relaying RTP/RTCP and messages between browsers and the server-side application logic they're attached to. Any specific feature/application needs to be implemented in server side plugins, that browsers can then contact via the Janus core to take advantage of the functionality they provide. Example of such plugins can be implementations of applications like echo tests, conference bridges, media recorders, SIP gateways and the like.
For more info visit  
[Janus: the general purpose WebRTC server](https://janus.conf.meetecho.com/)



**please note:-Although all features are working as expected but testing of api is still not complete please consider testing out this plugin so that this plugin can be production ready**

# Video Call Sample
<a href='https://youtu.be/wRo5nd7JnB4'><img src='https://github.com/shivanshtalwar0/flutter_janus_client/raw/master/samples/videocall_preview.jpg' 
                                            width='300' height='600'></a>

## News & Updates
**Audio Bridge tested with raw ui**
**Streaming plugin now supports unified plan a.k.a multi-streaming support**

## status
| Feature           | Support | Well Tested | Unified Plan |
|-------------------|---------|-------------|--------------|
| WebSocket         | Yes     | No          | -            |
| Rest/Http API     | Yes     | No          | -            |
| Video Room Plugin | Yes     | No          | wip          |
| Video Call Plugin | Yes     | No          | wip          |
| Streaming Plugin  | Yes     | No          | Yes          |
| Audio Room Plugin | Yes     | No          | wip          |
| Sip Plugin        | No      | No          | No           |
| Text Room Plugin  | wip     | No          | wip          |

# Getting Started
[VideoRoom Example](https://github.com/shivanshtalwar0/flutter_janus_client/blob/master/example/lib/VideoRoom.dart)  

[VideoCall Example](https://github.com/shivanshtalwar0/flutter_janus_client/blob/master/example/lib/videoCall.dart)  

[Streaming Example](https://github.com/shivanshtalwar0/flutter_janus_client/blob/master/example/lib/streaming.dart)
