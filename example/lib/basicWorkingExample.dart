//                Map<String, dynamic> configuration = {
//                  "iceServers": [
//                    {
//                      "url": "stun:40.85.216.95:3478",
//                      "username": "onemandev",
//                      "credential": "SecureIt"
//                    },
//                    {
//                      "url": "turn:40.85.216.95:3478",
//                      "username": "onemandev",
//                      "credential": "SecureIt"
//                    },
//                  ]
//                };
//
//                final Map<String, dynamic> offerSdpConstraints = {};
//                RTCPeerConnection peerConnection = await createPeerConnection(
//                    configuration, offerSdpConstraints);

//                peerConnection.

//                final Map<String, dynamic> mediaConstraints = {
//                  "audio": true,
//                  "video": {
//                    "mandatory": {
//                      "minWidth":
//                          '1280', // Provide your own width, height and frame rate here
//                      "minHeight": '720',
//                      "minFrameRate": '60',
//                    },
//                    "facingMode": "user",
//                    "optional": [],
//                  }
//                };
//                MediaStream mediaStream =
//                    await navigator.getUserMedia(mediaConstraints);
//                setState(() {
//                  _localRenderer.srcObject = mediaStream;
//                  _localRenderer.mirror = true;
//                });
//                await mediaStream
//                    .getVideoTracks()
//                    .firstWhere((track) => track.kind == "video")
//                    .switchCamera();
//                await peerConnection.addStream(mediaStream);

//                peerConnection.onIceConnectionState =
//                    (RTCIceConnectionState s) {
//                  print('got state');
//                  print(s.toString());
//                };
//                RTCSessionDescription offer = await peerConnection.createOffer(
//                    {"offerToReceiveAudio": true, "offerToReceiveVideo": true});
//                await peerConnection.setLocalDescription(offer);
