import fs from 'node:fs';
import {performance} from 'node:perf_hooks';
const input = process.argv[2];
if (!input) throw new Error('Usage: node pc/benchmark.mjs input.wav');
const wav = fs.readFileSync(input);
if (wav.toString('ascii',0,4)!=='RIFF'||wav.toString('ascii',8,12)!=='WAVE') throw new Error('PCM WAV required');
let fmt, data;
for(let p=12;p+8<=wav.length;) {
  const n=wav.readUInt32LE(p+4), id=wav.toString('ascii',p,p+4);
  if(p+8+n>wav.length) throw new Error('Truncated WAV');
  if(id==='fmt ') fmt=wav.subarray(p+8,p+8+n);
  if(id==='data') data=wav.subarray(p+8,p+8+n);
  p+=8+n+(n%2);
}
if(!fmt||!data||fmt.readUInt16LE(0)!==1||fmt.readUInt16LE(2)!==1||fmt.readUInt16LE(14)!==16) throw new Error('16-bit mono PCM WAV required');
const rate=fmt.readUInt32LE(4), frame=Math.round(rate*.16)*2;
const events=[]; let start, firstText;
const socket=new WebSocket('ws://127.0.0.1:8080/v1/audio/transcriptions/realtime');
const timeout=setTimeout(()=>{socket.close(); console.error('Timed out');process.exitCode=1},60000);
socket.addEventListener('error',()=>{clearTimeout(timeout); console.error('WebSocket connection failed');process.exitCode=1});
socket.addEventListener('open',()=>socket.send(JSON.stringify({type:'session.update',session:{sample_rate:rate,language:'ja-JP',word_timestamps:true}})));
socket.addEventListener('message',async e=>{
  const m=JSON.parse(e.data);
  if(m.type==='session.updated') {
    start=performance.now();
    for(let p=0;p<data.length;p+=frame) {
      const target=start+p/(rate*2)*1000;
      await new Promise(r=>setTimeout(r,Math.max(0,target-performance.now())));
      socket.send(data.subarray(p,p+frame));
    }
    await new Promise(r=>setTimeout(r,Math.max(0,start+data.length/(rate*2)*1000-performance.now())));
    socket.send(JSON.stringify({type:'input_audio_buffer.commit'}));
  } else if(m.type.endsWith('.delta')||m.type.endsWith('.completed')) {
    const ms=performance.now()-start;
    if(firstText===undefined&&(m.delta||m.transcript))firstText=ms;
    events.push({received_ms:ms,...m});
    console.log(Math.round(ms)+'ms '+(m.delta||m.transcript||''));
  } else if(m.type==='input_audio_buffer.committed') {
    clearTimeout(timeout);socket.close();
    const result={audio_seconds:data.length/(rate*2),first_text_ms:firstText,total_ms:performance.now()-start,timing_scope:'paced WAV ingress start to received event; not word-level subtitle latency',events};
    fs.mkdirSync('results',{recursive:true});
    fs.writeFileSync('results/stream-benchmark.json',JSON.stringify(result,null,2));
  } else if(m.type==='error') {clearTimeout(timeout);socket.close();console.error(m);process.exitCode=1;}
});
