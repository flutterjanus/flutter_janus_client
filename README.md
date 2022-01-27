[![ko-fi](https://www.ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/U7U11OZL8)  
<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->
[![All Contributors](https://img.shields.io/badge/all_contributors-5-orange.svg?style=flat-square)](#contributors-)
<!-- ALL-CONTRIBUTORS-BADGE:END -->

<a href="https://www.buymeacoffee.com/gr20hjk" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" style="height: 51px !important;width: 217px !important;" ></a>
# janus_client
This branch features  brand new API(v2) which is more fun to work with since it uses Stream API for exposing plugin level messages and events therefore it is easy
to work with and test.

##About  

It is feature rich flutter package, which offers all webrtc operations supported by [Janus: the general purpose WebRTC server](https://janus.conf.meetecho.com/),
it easily integrates into your flutter application and allows you to build webrtc features and functionality with clean and maintainable code.

# [Demo of JanusClient](https://flutterjanus.github.io/flutter_janus_client/example/build/web/#/)
coz, "we believe in what we can see" and nothing brings more satisfaction as working demo of the project.  


## what is janus?
The Janus WebRTC Server has been conceived as a general purpose server. As such, it doesn't provide any functionality per se other than implementing the means to set up a WebRTC media communication with a browser, exchanging JSON messages with it, and relaying RTP/RTCP and messages between browsers and the server-side application logic they're attached to. Any specific feature/application needs to be implemented in server side plugins, that browsers can then contact via the Janus core to take advantage of the functionality they provide. Example of such plugins can be implementations of applications like echo tests, conference bridges, media recorders, SIP gateways and the like.
For more info visit  
[Janus: the general purpose WebRTC server](https://janus.conf.meetecho.com/)



# Video Call Sample
<a href='https://youtu.be/wRo5nd7JnB4'><img src='https://github.com/shivanshtalwar0/flutter_janus_client/raw/master/samples/videocall_preview.jpg' 


## News & Updates
- typed examples updated with null safety and latest dart constraints
- introduced plugin specific wrapper classes with respective operation methods for rich development experience 
- introduced typed events (Class Based Events) for brilliant auto completion support for IDE  
- Supports null-safety

## status
| Feature           | Support | Well Tested | Unified Plan | Example |
|-------------------|---------|-------------|--------------|---------|
| WebSocket         | Yes     | Yes         | -            | Yes     |
| Rest/Http API     | Yes     | Yes         | -            | Yes     |
| Video Room Plugin | Yes     | partially tested         | Yes          | Yes     |
| Video Call Plugin | Yes     | No          | wip          | Yes     |
| Streaming Plugin  | Yes     | No          | wip          | Yes     |
| Audio Room Plugin | Yes     | No          | wip          | Yes     |
| Sip Plugin        | Yes     | No          | -           | No      |
| Text Room Plugin  | Yes     | No          | -          | Yes     |



## Contributors ✨

Thanks goes to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tr>
    <td align="center"><a href="https://github.com/shivanshtalwar0"><img src="https://avatars.githubusercontent.com/u/26632663?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Shivansh Talwar</b></sub></a><br /><a href="https://github.com/flutterjanus/flutter_janus_client/commits?author=shivanshtalwar0" title="Code">💻</a> <a href="https://github.com/flutterjanus/flutter_janus_client/commits?author=shivanshtalwar0" title="Documentation">📖</a></td>
    <td align="center"><a href="https://github.com/kzawadi"><img src="https://avatars.githubusercontent.com/u/12481289?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Kelvin Zawadi</b></sub></a><br /><a href="https://github.com/flutterjanus/flutter_janus_client/commits?author=kzawadi" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/LifeNow"><img src="https://avatars.githubusercontent.com/u/18676202?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Eugene</b></sub></a><br /><a href="https://github.com/flutterjanus/flutter_janus_client/commits?author=LifeNow" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/igala"><img src="https://avatars.githubusercontent.com/u/454390?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Igal Avraham</b></sub></a><br /><a href="https://github.com/flutterjanus/flutter_janus_client/commits?author=igala" title="Code">💻</a></td>
    <td align="center"><a href="http://vigikaran.me/"><img src="https://avatars.githubusercontent.com/u/9039584?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Vigikaran</b></sub></a><br /><a href="https://github.com/flutterjanus/flutter_janus_client/commits?author=vigikaran" title="Code">💻</a></td>
  </tr>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!
