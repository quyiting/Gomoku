// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';

// void main() => runApp(GomokuApp());

// class GomokuApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: '五子棋',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: GomokuGame(),
//     );
//   }
// }

// class GomokuGame extends StatefulWidget {
//   @override
//   _GomokuGameState createState() => _GomokuGameState();
// }

// class _GomokuGameState extends State<GomokuGame> {
//   late WebSocketChannel _channel;
//   List<List<int>> board = List.generate(15, (_) => List.filled(15, 0));
//   int currentPlayer = 1;
//   int? playerId;
//   int winner = 0;
//   bool gameOver = false;

//   @override
//   void initState() {
//     super.initState();
//     _channel = WebSocketChannel.connect(Uri.parse('ws://localhost:3000'));
//     _channel.stream.listen((message) {
//       final msg = jsonDecode(message);
//       switch (msg['type']) {
//         case 'init':
//           setState(() => playerId = msg['data']['playerId']);
//           break;
//         case 'update':
//           setState(() {
//             board = List.generate(15,
//                 (i) => List.from(msg['data']['board'][i].map((e) => e as int)));
//             currentPlayer = msg['data']['currentPlayer'];
//             winner = msg['data']['winner'];
//             gameOver = msg['data']['gameOver'];
//           });
//           break;
//       }
//     });
//   }

//   void _placePiece(int x, int y) {
//     if (playerId == null || playerId != currentPlayer || gameOver) return;
//     _channel.sink.add(jsonEncode({
//       'type': 'place-piece',
//       'data': {'x': x, 'y': y, 'playerId': playerId}
//     }));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('玩家 ${playerId ?? '等待连接'}')),
//       body: Column(
//         children: [
//           Expanded(
//             child: GridView.builder(
//               gridDelegate:
//                   SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 15),
//               itemCount: 225,
//               itemBuilder: (context, index) {
//                 final x = index ~/ 15;
//                 final y = index % 15;
//                 return GestureDetector(
//                   onTap: () => _placePiece(x, y),
//                   child: Container(
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.grey),
//                       color: _getPieceColor(board[x][y]),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//           if (gameOver) Text('玩家 $winner 胜利！', style: TextStyle(fontSize: 24)),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               ElevatedButton(
//                 onPressed: () =>
//                     _channel.sink.add(jsonEncode({'type': 'undo'})),
//                 child: Text('悔棋'),
//               ),
//               SizedBox(width: 20),
//               ElevatedButton(
//                 onPressed: () => _channel.sink.add(jsonEncode({
//                   'type': 'surrender',
//                   'data': {'playerId': playerId}
//                 })),
//                 child: Text('认输'),
//               ),
//               SizedBox(width: 20),
//               ElevatedButton(
//                 onPressed: () =>
//                     _channel.sink.add(jsonEncode({'type': 'reset'})),
//                 child: Text('重新开始'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green,
//                 ),
//               ),
//             ],
//           )
//         ],
//       ),
//     );
//   }

//   Color _getPieceColor(int value) {
//     return switch (value) {
//       1 => Colors.black,
//       2 => Colors.white,
//       _ => Colors.transparent,
//     };
//   }

//   @override
//   void dispose() {
//     _channel.sink.close();
//     super.dispose();
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() => runApp(GomokuApp());

class GomokuApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '在线五子棋',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: GomokuGame(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GomokuGame extends StatefulWidget {
  @override
  _GomokuGameState createState() => _GomokuGameState();
}

class _GomokuGameState extends State<GomokuGame> {
  late WebSocketChannel _channel;
  List<List<int>> board = List.generate(15, (_) => List.filled(15, 0));
  int currentPlayer = 1;
  int? playerId;
  int winner = 0;
  bool gameOver = false;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _connectToServer();
  }

  void _connectToServer() {
    //本地或者做内网穿透修改这里！！！！！！
    // const wsUrl = 'wss://55b1-124-205-119-208.ngrok-free.app'; // 替换你的ngrok地址
    const wsUrl = 'ws://127.0.0.1:3000';
    setState(() => _isConnected = false);

    _channel = WebSocketChannel.connect(Uri.parse(wsUrl))
      ..stream.handleError((error) {
        print('连接错误: $error');
        _showReconnectDialog();
      }).listen((message) {
        _handleServerMessage(message);
      }, onDone: () {
        if (!gameOver) _showReconnectDialog();
      });
  }

  void _handleServerMessage(dynamic message) {
    final msg = jsonDecode(message);
    switch (msg['type']) {
      case 'init':
        setState(() {
          playerId = msg['data']['playerId'];
          _isConnected = true;
        });
        break;
      case 'update':
        setState(() {
          board = List.generate(15,
              (i) => List.from(msg['data']['board'][i].map((e) => e as int)));
          currentPlayer = msg['data']['currentPlayer'];
          winner = msg['data']['winner'];
          gameOver = msg['data']['gameOver'];
        });
        break;
    }
  }

  void _showReconnectDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('连接中断'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('正在尝试重新连接...'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _connectToServer();
            },
            child: Text('重试'),
          ),
        ],
      ),
    );
  }

  void _placePiece(int x, int y) {
    if (playerId == null || playerId != currentPlayer || gameOver) return;

    _channel.sink.add(jsonEncode({
      'type': 'place-piece',
      'data': {'x': x, 'y': y, 'playerId': playerId}
    }));
  }

  Widget _buildStatusIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.circle,
          color: _isConnected ? Colors.green : Colors.red,
          size: 16,
        ),
        SizedBox(width: 8),
        Text(
          _isConnected ? '已连接（玩家 $playerId）' : '连接中...',
          style: TextStyle(
              fontSize: 16, color: _isConnected ? Colors.green : Colors.orange),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('在线五子棋'),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text('游戏规则'),
                content: Text('黑方先手，五子连珠获胜\n认输后对方自动获胜'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('确定'),
                  )
                ],
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: _buildStatusIndicator(),
          ),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 15,
                  childAspectRatio: 1,
                ),
                itemCount: 225,
                itemBuilder: (context, index) {
                  final x = index ~/ 15;
                  final y = index % 15;
                  return _buildGridItem(x, y);
                },
              ),
            ),
          ),
          if (gameOver)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 15),
              child: Text(
                winner > 0 ? '玩家 $winner 获胜！' : '游戏结束',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildControlButton(
                  label: '悔棋',
                  icon: Icons.undo,
                  onPressed: () =>
                      _channel.sink.add(jsonEncode({'type': 'undo'})),
                ),
                SizedBox(width: 20),
                _buildControlButton(
                  label: '认输',
                  icon: Icons.flag,
                  onPressed: () => _channel.sink.add(jsonEncode({
                    'type': 'surrender',
                    'data': {'playerId': playerId}
                  })),
                  color: Colors.red,
                ),
                SizedBox(width: 20),
                _buildControlButton(
                  label: '重玩',
                  icon: Icons.replay,
                  onPressed: () =>
                      _channel.sink.add(jsonEncode({'type': 'reset'})),
                  color: Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(int x, int y) {
    final piece = board[x][y];
    final isCurrentPlayer = playerId == currentPlayer;

    return GestureDetector(
      onTap: () => _placePiece(x, y),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          color: _getGridColor(x, y),
        ),
        child: AnimatedSwitcher(
          duration: Duration(milliseconds: 200),
          child: piece != 0
              ? Center(
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: piece == 1 ? Colors.black : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                  ),
                )
              : SizedBox.shrink(),
        ),
      ),
    );
  }

  Color _getGridColor(int x, int y) {
    // 添加棋盘网格线效果
    if (x % 5 == 0 && y % 5 == 0) return Colors.amber.shade100;
    if (x == 7 && y == 7) return Colors.amber.shade200;
    return (x + y) % 2 == 0 ? Colors.amber.shade50 : Colors.amber.shade100;
  }

  Widget _buildControlButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color color = Colors.blue,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, size: 28),
          color: color,
          onPressed: onPressed,
          tooltip: label,
        ),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }
}
