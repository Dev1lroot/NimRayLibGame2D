const WebSocket = require('ws');

const wss = new WebSocket.Server({ port: 3000 });

const clients = new Map();
let clientIdCounter = 0;
var tiles = [];
var players = {};

// Generating Tiles
for(let i = 0; i < 1000; i ++)
{
    tiles.push({
        name: "tile", 
        x: -100 + 32*Math.round(Math.random()*200),
        y: -100 + 32*Math.round(Math.random()*200),
    })
}

console.log('WebSocket server started on port 3000');

wss.on('connection', function connection(ws)
{
    const clientId = clientIdCounter++;
    clients.set(clientId, ws);
    
    console.log(`New client connected. ID: ${clientId}. Total clients: ${clients.size}`);
    
    ws.send(JSON.stringify({
        packet: "game_info", 
        tiles: tiles, 
        players: Object.values(players) 
    }));

    //broadcast(`Client ${clientId} has joined the chat.`, clientId);

    ws.on('message', function message(data) {
        const receivedMessage = data.toString();
        console.log(`Received from client ${clientId}: ${receivedMessage}`);
        //broadcast(`Client ${clientId}: ${receivedMessage}`);
        try{
            let json = JSON.parse(receivedMessage);
            if('packet' in json)
            {
                if('player' in json)
                {
                    players[json.player.uuid] = json.player;

                    console.log("Broadcasting Players Position Changes")
                    broadcast(JSON.stringify({
                        packet: "players",
                        players: Object.values(players)
                    }));
                }
            }
        }
        catch(e){
            console.log("Receiving bad packet: " + receivedMessage);
        }
    });

    ws.on('close', function close() {
        clients.delete(clientId);
        console.log(`Client ${clientId} disconnected. Total clients left: ${clients.size}`);
        broadcast(`Client ${clientId} has left the chat.`, clientId);
    });

    ws.on('error', function error(err) {
        console.error(`WebSocket error for client ${clientId}:`, err);
    });
});

function broadcast(message, excludeClientId = null) {
    clients.forEach((clientWs, clientId) => {

        if (clientWs.readyState === WebSocket.OPEN) {

            if (excludeClientId === null || clientId !== excludeClientId) {
                clientWs.send(message);
            }
        }
    });
}
// let automaticMessageCounter = 0;
// setInterval(() => {
//     automaticMessageCounter++;
//     const message = `[SERVER BROADCAST] This is an automatic message #${automaticMessageCounter}. Current time: ${new Date().toLocaleTimeString()}`;
//     console.log(`Sending scheduled broadcast: ${message}`);
//     broadcast(message);
// }, 10000);