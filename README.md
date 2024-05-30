




# janus_client 
[![januscaler](https://img.shields.io/badge/powered_by-JanuScaler-b?style=for-the-badge&logo=Januscaler&logoColor=%238884ED&label=Powered%20By&labelColor=white&color=%238884ED)](https://januscaler.com)  

[![pub package](https://img.shields.io/pub/v/janus_client.svg)](https://pub.dartlang.org/packages/janus_client)[![Gitter](https://badges.gitter.im/flutter_janus_client/Lobby.svg)](https://gitter.im/flutter_janus_client/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)
<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->
[![All Contributors](https://img.shields.io/badge/all_contributors-13-orange.svg?style=flat-square)](#contributors-)
<!-- ALL-CONTRIBUTORS-BADGE:END -->

It is a feature rich flutter package, which offers all webrtc operations supported by [Janus: the general purpose WebRTC server](https://janus.conf.meetecho.com/),
it easily integrates into your flutter application and allows you to build webrtc features and functionality with clean and maintainable code.

> [!NOTE]
> ## What it will do?
> - It will help you in establishing communication with Janus server using either REST or Websocket depending on what you prefer 
> - It will provide you meaningful APIs for individual plugins so you can express your app logic without worrying about internals
> ## What it will not do?
> It will not manage every aspect of WebRTC for you by that we mean we only provide core functionalities and features when it comes to WebRTC, since this library uses flutter_webrtc for managing all of webrtc stack so you will need to refer its documentation when there's some use cases which we do not cover or does not exist in examples. This is done intentionally by design to give developers complete flexibility while also making sure library is lightweight and does not become a bloatware.
A classic example of that would be changing output device on a native device for example you want to switch from speaker to headsets or bluetooth audio device you will need to use `flutter_webrtc`'s `Helper` utility class:-   
>```dart 
>Helper.selectAudioOutput(deviceIdOfBluetoothDevice) 
>``` 


## [Demo of JanusClient](https://flutterjanus.github.io/flutter_janus_client/)

## [APIReference](https://flutterjanus.github.io/flutter_janus_client/doc/api/)

## [Wiki](https://github.com/flutterjanus/flutter_janus_client/wiki)

## [Take away apple specific pain for building flutter app](https://github.com/flutterjanus/flutter_janus_client/wiki/Take-away-Apple-IOS-and-macOS-related-pain-from-me-%F0%9F%92%AF-(building-for-apple))

## [screen share example](https://github.com/flutterjanus/screenshare_example)

## News & Updates
- Introduced support for simulcast
- videoroom and screenshare improvements (screenshare tested on android and chrome)
- sip plugin wrapper added with sip calling example
- Added errorHandler for typedMessage Stream for better development flow
- Just like new flutter version comes With desktop support out of the box
- All major plugins fully support unified plan
- Typed examples updated with null safety and latest dart constraints
- Introduced plugin specific wrapper classes with respective operation methods for rich development experience
- Introduced typed events (Class Based Events) for brilliant auto completion support for IDE
- Supports null-safety

## Feature Status
| Feature           | Support | Well Tested | Unified Plan | Example |
|-------------------|---------|-------------|--------------|---------|
| WebSocket         | Yes     | Yes         | -            | Yes     |
| Rest/Http API     | Yes     | Yes         | -            | Yes     |
| Video Room Plugin | Yes     | No         | Yes          | Yes     |
| Video Call Plugin | Yes     | No          | Yes          | Yes     |
| Streaming Plugin  | Yes     | No          | Yes          | Yes     |
| Audio Room Plugin | Yes     | No          | Yes          | Yes     |
| Sip Plugin        | Yes     | No          | Yes           | Yes      |
| Text Room Plugin  | Yes     | No          | -          | Yes     |
| ScreenSharing using VideoRoom plugin  | Yes     | No          | Yes          | Yes     |

## Platform Support Table
| Platform           | Support | Well Tested|
|-------------------|---------|-------------|
| Browser(Web)      | Yes     | Yes         |
| MacOs             | Yes     | No          |
| Android           | Yes     | Yes         | 
| Ios               | Yes     | No          | 
| Linux             | Yes     | No          | 
| Windows           | Yes     | No          | 


## Todo
- Documentation of some remaining plugins
- Polishing of examples
- Unit Test cases for all plugins

## Deprecated Api v1(0.0.x)
If by any chance you are looking for (although you shouldn't) old api then you can switch to v1 branch,
as it is very unstable and hard to maintain it was deprecated and will not recieve any fixes or feature updates.
It is highly recommended you migrate your code to latest version that is 2.X.X (stable)

## Contributors ✨

Thanks goes to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/shivanshtalwar0"><img src="https://avatars.githubusercontent.com/u/26632663?v=4?s=100" width="100px;" alt="Shivansh Talwar"/><br /><sub><b>Shivansh Talwar</b></sub></a><br /><a href="https://github.com/flutterjanus/flutter_janus_client/commits?author=shivanshtalwar0" title="Code">💻</a> <a href="https://github.com/flutterjanus/flutter_janus_client/commits?author=shivanshtalwar0" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/kzawadi"><img src="https://avatars.githubusercontent.com/u/12481289?v=4?s=100" width="100px;" alt="Kelvin Zawadi"/><br /><sub><b>Kelvin Zawadi</b></sub></a><br /><a href="https://github.com/flutterjanus/flutter_janus_client/commits?author=kzawadi" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/LifeNow"><img src="https://avatars.githubusercontent.com/u/18676202?v=4?s=100" width="100px;" alt="Eugene"/><br /><sub><b>Eugene</b></sub></a><br /><a href="https://github.com/flutterjanus/flutter_janus_client/commits?author=LifeNow" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/igala"><img src="https://avatars.githubusercontent.com/u/454390?v=4?s=100" width="100px;" alt="Igal Avraham"/><br /><sub><b>Igal Avraham</b></sub></a><br /><a href="https://github.com/flutterjanus/flutter_janus_client/commits?author=igala" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="http://vigikaran.me/"><img src="https://avatars.githubusercontent.com/u/9039584?v=4?s=100" width="100px;" alt="Vigikaran"/><br /><sub><b>Vigikaran</b></sub></a><br /><a href="https://github.com/flutterjanus/flutter_janus_client/commits?author=vigikaran" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/UserSense"><img src="https://avatars.githubusercontent.com/u/65860664?v=4?s=100" width="100px;" alt="UserSense"/><br /><sub><b>UserSense</b></sub></a><br /><a href="https://github.com/flutterjanus/flutter_janus_client/commits?author=UserSense" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/baihua666"><img src="https://avatars.githubusercontent.com/u/5125983?v=4?s=100" width="100px;" alt="baihua666"/><br /><sub><b>baihua666</b></sub></a><br /><a href="https://github.com/flutterjanus/flutter_janus_client/issues?q=author%3Abaihua666" title="Bug reports">🐛</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/ngoluuduythai"><img src="https://avatars.githubusercontent.com/u/12238262?v=4?s=100" width="100px;" alt="ngoluuduythai"/><br /><sub><b>ngoluuduythai</b></sub></a><br /><a href="https://github.com/flutterjanus/flutter_janus_client/commits?author=ngoluuduythai" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://www.facebook.com/sakshamgupta12"><img src="https://avatars.githubusercontent.com/u/14076514?v=4?s=100" width="100px;" alt="Saksham Gupta"/><br /><sub><b>Saksham Gupta</b></sub></a><br /><a href="https://github.com/flutterjanus/flutter_janus_client/commits?author=sakshamgupta05" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/chu06"><img src="https://avatars.githubusercontent.com/u/129312223?v=4?s=100" width="100px;" alt="chu06"/><br /><sub><b>chu06</b></sub></a><br /><a href="https://github.com/flutterjanus/flutter_janus_client/commits?author=chu06" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/musagil"><img src="https://avatars.githubusercontent.com/u/7420090?v=4?s=100" width="100px;" alt="Musagil Musabayli"/><br /><sub><b>Musagil Musabayli</b></sub></a><br /><a href="https://github.com/flutterjanus/flutter_janus_client/commits?author=musagil" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/mazen930"><img src="https://avatars.githubusercontent.com/u/33043493?v=4?s=100" width="100px;" alt="Mazen Amr"/><br /><sub><b>Mazen Amr</b></sub></a><br /><a href="https://github.com/flutterjanus/flutter_janus_client/commits?author=mazen930" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Clon1998"><img src="https://avatars.githubusercontent.com/u/10357775?v=4?s=100" width="100px;" alt="Patrick Schmidt"/><br /><sub><b>Patrick Schmidt</b></sub></a><br /><a href="https://github.com/flutterjanus/flutter_janus_client/commits?author=Clon1998" title="Code">💻</a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!

## Wait there's more... The Javascript Client!
If you loved the api style and architecture of flutter_janus_client and you wishing to have something similar for your next javascript project involving webrtc features.
then worry not because we have got you covered. we have written wrapper on top of our good old `janus.js`, you might ask why? well the answer to that question is it does not support
type bindings hence no rich ide support, so we proudly presents [typed_janus_js(feature rich promisified and reactive wrapper on top of janus.js)](https://github.com/flutterjanus/JanusJs)
or you can straight away use it by installing from npm `npm i typed_janus_js`.

## Donations 
[![ko-fi](https://www.ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/U7U11OZL8)  

<a href="https://www.buymeacoffee.com/gr20hjk" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" style="height: 51px !important;width: 217px !important;" ></a>
