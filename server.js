// const express = require('express');
// const WebSocket = require('ws');
// const http = require('http');

// const app = express();
// const server = http.createServer(app);
// const wss = new WebSocket.Server({ server });

// let game = null;
// let players = [];

// wss.on('connection', (ws) => {
//   if (players.length >= 2) {
//     ws.close(1000, '游戏已满员');
//     return;
//   }
//   players.push(ws);

//   // 分配玩家ID
//   const playerId = players.length;
//   ws.send(JSON.stringify({ type: 'init', data: { playerId } }));

//   if (players.length === 2) {
//     game = new Game(players);
//     broadcast(game.sendState());
//   }

//   ws.on('message', (message) => {
//     try {
//       const msg = JSON.parse(message);
//       if (!game) return;

//       switch (msg.type) {
//         case 'place-piece':
//           game.placePiece(msg.data.x, msg.data.y, msg.data.playerId);
//           broadcast(game.sendState());
//           break;

//         case 'undo':
//           if (game.undoMove()) {
//             broadcast(game.sendState());
//           }
//           break;

//         case 'surrender':
//           game.surrender(msg.data.playerId);
//           broadcast(game.sendState());
//           break;

//         case 'reset':
//           game.reset();
//           broadcast(game.sendState());
//           break;
//       }
//     } catch (error) {
//       console.error('消息处理错误:', error);
//     }
//   });

//   ws.on('close', () => {
//     players = players.filter(player => player !== ws);
//     if (game) {
//       game.surrender(players.length ? 1 : 2); // 断开玩家自动判负
//       game = null;
//     }
//     players = [];
//   });
// });

// function broadcast(message) {
//   const data = JSON.stringify(message);
//   players.forEach(player => {
//     if (player.readyState === WebSocket.OPEN) player.send(data);
//   });
// }

// class Game {
//   constructor(players) {
//     this.boardSize = 15;
//     this.board = Array.from({ length: this.boardSize }, () => 
//       Array(this.boardSize).fill(0));
//     this.players = players;
//     this.moves = [];
//     this.currentPlayer = 1;
//     this.winner = 0;
//     this.gameOver = false;
//   }

//   reset() {
//     this.board = Array.from({ length: this.boardSize }, () => 
//       Array(this.boardSize).fill(0));
//     this.moves = [];
//     this.currentPlayer = 1;
//     this.winner = 0;
//     this.gameOver = false;
//   }

//   placePiece(x, y, playerId) {
//     if (this.gameOver || this.currentPlayer !== playerId || this.board[x][y] !== 0) return;
    
//     this.board[x][y] = playerId;
//     this.moves.push({ x, y, playerId });
//     this.checkWin(x, y, playerId);
//     this.currentPlayer = playerId === 1 ? 2 : 1;
//   }

//   undoMove() {
//     if (this.moves.length === 0 || this.gameOver) return false;
    
//     const lastMove = this.moves.pop();
//     this.board[lastMove.x][lastMove.y] = 0;
//     this.currentPlayer = lastMove.playerId;
//     return true;
//   }

//   surrender(playerId) {
//     this.winner = playerId === 1 ? 2 : 1;
//     this.gameOver = true;
//   }

//   checkWin(x, y, playerId) {
//     const directions = [[1,0], [0,1], [1,1], [1,-1]];
//     for (const [dx, dy] of directions) {
//       let count = 1;
//       [[1, 1], [-1, -1]].forEach(([signX, signY]) => {
//         for (let i = 1; i <= 4; i++) {
//           const nx = x + dx * i * signX;
//           const ny = y + dy * i * signY;
//           if (nx < 0 || nx >= this.boardSize || ny < 0 || ny >= this.boardSize) break;
//           if (this.board[nx][ny] === playerId) count++; else break;
//         }
//       });
//       if (count >= 5) {
//         this.winner = playerId;
//         this.gameOver = true;
//         break;
//       }
//     }
//   }

//   sendState() {
//     return {
//       type: 'update',
//       data: {
//         board: this.board,
//         currentPlayer: this.currentPlayer,
//         winner: this.winner,
//         gameOver: this.gameOver
//       }
//     };
//   }
// }

// server.listen(3000, () => console.log('服务器运行在 http://localhost:3000'));



const express = require('express');
const WebSocket = require('ws');
const http = require('http');
const cors = require('cors');

const app = express();

// 启用CORS
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST']
}));

// 创建HTTP服务器
const server = http.createServer(app);

// 创建WebSocket服务器
const wss = new WebSocket.Server({ server });

let game = null;
let players = [];

wss.on('connection', (ws) => {
  console.log('新客户端连接');
  
  if (players.length >= 2) {
    ws.close(1000, '游戏人数已满');
    return;
  }
  
  players.push(ws);
  const playerId = players.length;
  
  // 发送初始化信息
  ws.send(JSON.stringify({
    type: 'init',
    data: { playerId }
  }));

  if (players.length === 2) {
    game = new Game(players);
    broadcast(game.sendState());
  }

  ws.on('message', (message) => {
    try {
      const msg = JSON.parse(message);
      if (!game) return;

      switch (msg.type) {
        case 'place-piece':
          game.placePiece(msg.data.x, msg.data.y, msg.data.playerId);
          broadcast(game.sendState());
          break;

        case 'undo':
          if (game.undoMove()) {
            broadcast(game.sendState());
          }
          break;

        case 'surrender':
          game.surrender(msg.data.playerId);
          broadcast(game.sendState());
          break;

        case 'reset':
          game.reset();
          broadcast(game.sendState());
          break;
      }
    } catch (error) {
      console.error('消息处理错误:', error);
    }
  });

  ws.on('close', () => {
    console.log('客户端断开连接');
    players = players.filter(player => player !== ws);
    if (game) {
      game.surrender(players.length ? 1 : 2);
      game = null;
    }
    players = [];
  });
});

function broadcast(message) {
  const data = JSON.stringify(message);
  players.forEach(player => {
    if (player.readyState === WebSocket.OPEN) {
      player.send(data);
    }
  });
}

class Game {
  constructor(players) {
    this.boardSize = 15;
    this.board = Array.from({ length: this.boardSize }, () => 
      Array(this.boardSize).fill(0));
    this.players = players;
    this.moves = [];
    this.currentPlayer = 1;
    this.winner = 0;
    this.gameOver = false;
  }

  reset() {
    this.board = Array.from({ length: this.boardSize }, () => 
      Array(this.boardSize).fill(0));
    this.moves = [];
    this.currentPlayer = 1;
    this.winner = 0;
    this.gameOver = false;
  }

  placePiece(x, y, playerId) {
    if (this.gameOver || this.currentPlayer !== playerId || this.board[x][y] !== 0) return;
    
    this.board[x][y] = playerId;
    this.moves.push({ x, y, playerId });
    this.checkWin(x, y, playerId);
    this.currentPlayer = playerId === 1 ? 2 : 1;
  }

  undoMove() {
    if (this.moves.length === 0 || this.gameOver) return false;
    
    const lastMove = this.moves.pop();
    this.board[lastMove.x][lastMove.y] = 0;
    this.currentPlayer = lastMove.playerId;
    return true;
  }

  surrender(playerId) {
    this.winner = playerId === 1 ? 2 : 1;
    this.gameOver = true;
  }

  checkWin(x, y, playerId) {
    const directions = [[1,0], [0,1], [1,1], [1,-1]];
    for (const [dx, dy] of directions) {
      let count = 1;
      [[1, 1], [-1, -1]].forEach(([signX, signY]) => {
        for (let i = 1; i <= 4; i++) {
          const nx = x + dx * i * signX;
          const ny = y + dy * i * signY;
          if (nx < 0 || nx >= this.boardSize || ny < 0 || ny >= this.boardSize) break;
          if (this.board[nx][ny] === playerId) count++; else break;
        }
      });
      if (count >= 5) {
        this.winner = playerId;
        this.gameOver = true;
        break;
      }
    }
  }

  sendState() {
    return {
      type: 'update',
      data: {
        board: this.board,
        currentPlayer: this.currentPlayer,
        winner: this.winner,
        gameOver: this.gameOver
      }
    };
  }
}

// 启动服务器
server.listen(3000, '0.0.0.0', () => {
  console.log('服务器运行在 http://0.0.0.0:3000');
});
