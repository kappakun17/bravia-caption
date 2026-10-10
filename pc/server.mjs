import http from 'node:http';
import fs from 'node:fs';
const page=fs.readFileSync(new URL('./index.html',import.meta.url));
http.createServer((req,res)=>{if(req.url!=='/'){res.writeHead(404);res.end();return;}res.writeHead(200,{'Content-Type':'text/html; charset=utf-8'});res.end(page)}).listen(8090,'127.0.0.1',()=>console.log('Caption screen: http://127.0.0.1:8090'));
