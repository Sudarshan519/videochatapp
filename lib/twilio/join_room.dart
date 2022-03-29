import 'package:flutter/material.dart';
import 'package:twilio_programmable_video/twilio_programmable_video.dart';

var accessToken =
    "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImN0eSI6InR3aWxpby1mcGE7dj0xIn0.eyJqdGkiOiJTS2JiYmQ4NjY3N2NjNjQ2NDk3ZjhhMWEzMzk4ZDMwYmRhLTE2NDgwOTg2MDQiLCJpc3MiOiJTS2JiYmQ4NjY3N2NjNjQ2NDk3ZjhhMWEzMzk4ZDMwYmRhIiwic3ViIjoiQUM1ZGM2NTQxYmQ4NzUzOTQ4NDJkNjdlMmVkYzk0NTlkNiIsImV4cCI6MTY0ODEwMjIwNCwiZ3JhbnRzIjp7ImlkZW50aXR5IjoidGVzdCIsInZpZGVvIjp7InJvb20iOiJ0ZXN0In19fQ.YTE4bOkDlRaMw_ClsD6CdtLiadmwcvKzo-2prypZtYM";

// import ;
class TwilioHomePage extends StatefulWidget {
  const TwilioHomePage({Key? key}) : super(key: key);

  @override
  State<TwilioHomePage> createState() => _TwilioHomePageState();
}

class _TwilioHomePageState extends State<TwilioHomePage> {
  var isloading = true;
  late var primaryVideoView;
  late var secondaryVideo;
  late Room room;
  late LocalVideoTrack videoTrack;
  List<Widget> _widgets = [];
  void _onMessage(RemoteDataTrackStringMessageEvent event) {
    print('onMessage => ${event.remoteDataTrack.sid}, ${event.message}');
  }

  void _onDataTrackSubscribed(RemoteDataTrackSubscriptionEvent event) {
    final dataTrack = event.remoteDataTrackPublication.remoteDataTrack;
    dataTrack!.onMessage.listen(_onMessage);
  }

  connectRoom() async {
    secondaryVideo = Align(
      alignment: Alignment.bottomCenter,
      child: Container(height: 500, width: 400, color: Colors.black),
    );
    primaryVideoView = Container(
      child: const Center(child: Text("Connecting")),
    );
    isloading = false;
    shareCamera();
    // Connect to a room.
    room = await TwilioProgrammableVideo.connect(
        ConnectOptions(accessToken, videoTracks: [videoTrack]));

    room.onConnected.listen((Room room) {
      print('Connected to ${room.name}');
    });

    room.onConnectFailure.listen((RoomConnectFailureEvent event) {
      print('Failed connecting, exception: ${event.exception!.message}');
    });

    room.onDisconnected.listen((RoomDisconnectedEvent event) {
      print('Disconnected from ${event.room.name}');
    });

    room.onRecordingStarted.listen((Room room) {
      print('Recording started in ${room.name}');
    });

    room.onRecordingStopped.listen((Room room) {
      print('Recording stopped in ${room.name}');
    });

    ///on connected
    room.onParticipantConnected
        .listen((RoomParticipantConnectedEvent roomEvent) {
      roomEvent.remoteParticipant.onVideoTrackSubscribed
          .listen((RemoteVideoTrackSubscriptionEvent event) {
        var mirror = false;
        _widgets.add(event.remoteVideoTrackPublication.remoteVideoTrack!
            .widget(mirror: mirror));
        print("total widgets" + _widgets.length.toString());
        setState(() {});
        event.remoteParticipant.onDataTrackSubscribed
            .listen(_onDataTrackSubscribed);
      });
    });

// ... Assume we have received the connected callback.

// After receiving the connected callback the LocalParticipant becomes available.
    var localParticipant = room.localParticipant!;
    print('LocalParticipant ${room.localParticipant!.identity.toString()}');

// Get the first participant from the room.
    var remoteParticipant = room.remoteParticipants[0];
    print('RemoteParticipant ${remoteParticipant.identity} is in the room');
  }

  shareCamera() async {
    // Share your camera.
    var cameraSources = await CameraSource.getSources();
    print("camera" +
        cameraSources.firstWhere((source) => source.isFrontFacing).toString());

    var cameraCapturer = CameraCapturer(
      cameraSources.firstWhere((source) => source.isFrontFacing),
    );
    LocalVideoTrack localVideoTrack =
        LocalVideoTrack(true, cameraCapturer, name: "user");
    var widget = localVideoTrack.widget();
    _widgets.add(SizedBox(height: 200, width: 200, child: widget));
    isloading = false;
    setState(() {});
    // var trackId = Uuid().v4();
    // videoTrack = LocalVideoTrack(true, cameraCapturer);
    // primaryVideoView = Container(
    //     color: Colors.black,
    //     height: 200,
    //     width: 200,
    //     child: videoTrack.widget(mirror: false));
    // print("camera connected");
    // setState(() {});
// Render camera to a widget (only after connect event).

// Switch the camera source.
    // var cameraSources = await CameraSource.getSources();
    // var cameraSource =
    //     cameraSources.firstWhere((source) => source.isBackFacing);
    // await cameraCapturer.switchCamera(cameraSource);

    // await primaryVideoView.setMirror(cameraSource.isBackFacing);
  }

  disconnect() async {
    await room.disconnect();

// This results in a call to Room#onDisconnected
    room.onDisconnected.listen((RoomDisconnectedEvent event) {
      print('Disconnected from ${event.room.name}');
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    shareCamera();
    // connectRoom();
  }

  @override
  Widget build(BuildContext context) {
    // loadCamera();
    return Scaffold(
        floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.red,
            onPressed: () {
              disconnect();
            },
            child: Icon(
              Icons.call_end,
            )),
        body: isloading
            ? Center(child: CircularProgressIndicator())
            : Stack(children: [_widgets[0]]));
  }
}
