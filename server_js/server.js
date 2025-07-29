import Perlin2D from './perlin2d.js';
import WebSocket from 'ws';
import { WebSocketServer } from 'ws';
import fs from 'fs';
import { fileURLToPath } from 'url';
import path from 'path';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const TILE_SIZE = 32;
const CHUNK_SIZE = 16;
const VIEW_DISTANCE = 3;
const CHUNK_DIR = path.join(__dirname, 'overworld', 'chunks');

const MAP_DIFFUSE = new Perlin2D();
const MAP_TEMPERATURE = new Perlin2D();
const MAP_ERROSION = new Perlin2D();

fs.mkdirSync(CHUNK_DIR, { recursive: true });

function generateChunkData(chunkX, chunkY)
{
    const tiles = [];
    for(let ty=0; ty<CHUNK_SIZE; ty++)
    {
        for(let tx=0; tx<CHUNK_SIZE; tx++)
        {
            const wx = chunkX*CHUNK_SIZE + tx;
            const wy = chunkY*CHUNK_SIZE + ty;

            const diffuse = MAP_DIFFUSE.get(wx*0.05, wy*0.05);
            const temperature = MAP_TEMPERATURE.get(wx*0.05, wy*0.05);
            const errosion = MAP_ERROSION.get(wx*0.01, wy*0.01);

            let type = "grass";
            
            if(diffuse>0.3) type="forest";
            
            if(diffuse<-0.3) type="water";
            
            if(type == "grass" || type == "forest")
            {
                if(errosion > 0.5) type = "stone";
            }

            if(type == "grass")
            {
                if(temperature > 0.3) type = "sand";
                if(temperature < -0.3) type = "snow";
            }

            tiles.push({
                name: type,
                x: wx*TILE_SIZE,
                y: wy*TILE_SIZE
            });
        }
    }
    return tiles;
}


function loadOrGenerateChunk(chunkX, chunkY)
{
    const filePath = path.join(CHUNK_DIR, `${chunkX},${chunkY}.chunk`);
    if(fs.existsSync(filePath))
    {
        return JSON.parse(fs.readFileSync(filePath, 'utf8'));
    }
    else
    {
        const tiles = generateChunkData(chunkX, chunkY);
        fs.writeFileSync(filePath, JSON.stringify(tiles));
        return tiles;
    }
}


function getChunksForPlayer(px, py)
{
    const chunkX = Math.floor(px/(CHUNK_SIZE*TILE_SIZE));
    const chunkY = Math.floor(py/(CHUNK_SIZE*TILE_SIZE));
    const chunks = [];
    for(let cx = chunkX - VIEW_DISTANCE; cx <= chunkX + VIEW_DISTANCE; cx++){
        for(let cy = chunkY - VIEW_DISTANCE; cy <= chunkY + VIEW_DISTANCE; cy++){
            const tiles = loadOrGenerateChunk(cx, cy);
            chunks.push(...tiles);
        }
    }
    return chunks;
}


const wss = new WebSocketServer({ port: 3000 });
const clients = new Map();
let clientIdCounter = 0;
let players = {};
let clientMap = {}

console.log('WebSocket server started on port 3000');

wss.on('connection', ws => {
    const clientId = clientIdCounter++;
    clients.set(clientId, ws);
    console.log(`Client connected: ${clientId}`);

    ws.on('message', data => {
        try {
            const json = JSON.parse(data.toString());
            if(json.packet && json.player){
                const player = json.player;
                
                players[player.uuid] = player;
                clientMap[player.uuid] = ws;

                broadcast(JSON.stringify({
                    packet: "players",
                    players: Object.values(players)
                }));
            }
        } catch(e){
            console.log("Bad packet:", data.toString());
        }
    });

    ws.on('close', ()=>{
        clients.delete(clientId);
        console.log(`Client ${clientId} disconnected`);
    });

    ws.on('error', err=>{
        console.error(`WebSocket error for client ${clientId}:`, err);
    });
});

function broadcast(message, excludeClientId=null){
    clients.forEach((clientWs, clientId)=>{
        if(clientWs.readyState===WebSocket.OPEN && (excludeClientId===null || clientId!==excludeClientId)){
            clientWs.send(message);
        }
    });
}

setInterval(() => {
    for(let uuid of Object.keys(clientMap))
    {
        const chunks = getChunksForPlayer(players[uuid].position.x, players[uuid].position.y);

        clientMap[uuid].send(JSON.stringify({
            packet: "chunks",
            tiles: chunks
        }));
    }
},5000)