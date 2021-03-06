import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class Message {
  Message(this.sender, this.text);

  final String sender;
  final String text;

  @override
  String toString() {
    return "$sender:$text";
  }
}


class SocketScreen extends StatefulWidget {
  _SocketScreenState createState() => _SocketScreenState();
}

class _SocketScreenState extends State<SocketScreen> {
  var _mainColor = Colors.red;

  final List<Message> messages = new List();
  final myController = TextEditingController();
  final ScrollController _scrollController = new ScrollController();

  Socket socket;

  Future<void> connect() async {
    final _ipController = TextEditingController();
    final _portController = TextEditingController();

    Alert alert = Alert(
        context: context,
        title: "Connect to a socket",
        content: Column(
          children: <Widget>[
            TextField(
              obscureText: false,
              controller: _ipController,
              decoration: InputDecoration(
                labelText: 'IP',
              ),
            ),
            TextField(
              obscureText: false,
              controller: _portController,
              decoration: InputDecoration(
                labelText: 'Port',
              ),
            ),
          ],
        ),
        buttons: [
          DialogButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Connect",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          )
        ]);
    await alert.show();
    if (_portController.value.text.isEmpty || _ipController.value.text.isEmpty)
      return;
    int port = int.parse(_portController.value.text.trim());
    var ip = _ipController.value.text.trim();

    connectTo(ip, port);
  }

  void connectTo(String ip, int port) {
    Socket.connect(ip, port).then((Socket sock) {
      socket = sock;
      socket.listen(dataHandler,
          onError: errorHandler, onDone: doneHandler, cancelOnError: false);
    }).catchError((Object e) {
      print("Unable to connect: $e");
    });
  }

  void dataHandler(data) {
    var text = utf8.decode(data);
    var msg = new Message("Other", text);
    setState(() {
      messages.add(msg);
    });
    scrollDown();
  }

  void errorHandler(error, StackTrace trace) {
    print(error);
  }

  void doneHandler() {
    socket.destroy();
  }

  void send() {
    if (socket == null) {
      connect();
      return;
    }
    if (myController.value.text.toString().trim().length == 0) return;

    var msg = new Message("You", myController.value.text.toString());

    setState(() {
      messages.add(msg);
    });
    socket.write(msg.text);
    socket.flush();
    myController.clear();
    scrollDown();
  }

  void scrollDown() {
    Timer(
        Duration(milliseconds: 15),
        () => _scrollController
            .jumpTo(_scrollController.position.maxScrollExtent));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: ListView.separated(
          controller: _scrollController,
          shrinkWrap: true,
          padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 16),
          itemCount: messages.length,
          itemBuilder: (BuildContext context, int index) {
            return Container(
              decoration: new BoxDecoration(
                  color: messages[index].sender == "You"
                      ? Colors.grey
                      : Colors.red,
                  borderRadius:
                      new BorderRadius.all(new Radius.circular(10.0))),
              padding: EdgeInsets.all(10),
              child: Text('${messages[index]}'),
            );
          },
          separatorBuilder: (BuildContext context, int index) =>
              const Divider(),
        )),
        bottomSheet: Container(
          child: Row(
            children: <Widget>[
              Expanded(
                  child: TextField(
                style: TextStyle(fontSize: 18),
                controller: myController,
                onSubmitted: (str) => send(),
                decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter a message',
                    contentPadding: EdgeInsets.all(10)),
              )),
              IconButton(
                iconSize: 30,
                padding: EdgeInsets.all(10),
                icon: new Icon(
                  FontAwesome.send,
                ),
                onPressed: () => send(),
              )
            ],
          ),
        ));
  }
}
