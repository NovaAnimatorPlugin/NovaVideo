# NovaVideo (PowerShell version) - reference-video player that follows the NovaAnimator timeline.
# Windows only, nothing to install. Start it with Start_NovaVideo_PowerShell.bat (double-click),
# pick your video in the page that opens, then in Studio:
#   SupremeAnimator > Reference video (synced) > Sync with NovaVideo
# Listens only on 127.0.0.1 (your own PC). Your video never leaves your computer.
param([int]$Port = 8765)

$ErrorActionPreference = 'Stop'
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$state = @{ playing = $false; time = 0.0; speed = 1.0; fps = 30.0; length = 0.0 }
$script:lastUpdate = -1.0

$page = @'
<!doctype html>
<html lang="en"><head><meta charset="utf-8"><title>Nova Video</title>
<meta name="viewport" content="width=device-width,initial-scale=1">
<style>
:root{--bg:#12112a;--panel:#1c1a3b;--line:#34306a;--txt:#e8ecff;--dim:#8f94c8;--acc:#8b7cf6;--ok:#4fd1c5;--bad:#f0716b}
*{box-sizing:border-box}
html,body{height:100%;margin:0;background:var(--bg);color:var(--txt);font:13px/1.3 "Segoe UI",system-ui,sans-serif}
body{display:flex;flex-direction:column;gap:8px;padding:10px}
.bar{display:flex;gap:8px;align-items:center;flex-wrap:wrap;background:var(--panel);border:1px solid var(--line);border-radius:8px;padding:8px 10px}
.title{font-weight:700;letter-spacing:.08em}
.dot{width:9px;height:9px;border-radius:50%;background:var(--bad);display:inline-block;margin-right:6px}
.dot.on{background:var(--ok);box-shadow:0 0 8px var(--ok)}
.sp{flex:1}
button{background:#2a2757;color:var(--txt);border:1px solid var(--line);border-radius:6px;padding:5px 10px;cursor:pointer;font:inherit}
button:hover{border-color:var(--acc)} button:disabled{opacity:.45;cursor:default}
button.on{background:var(--acc);color:#fff;border-color:var(--acc)}
input[type=number]{width:70px;background:#13122b;color:var(--txt);border:1px solid var(--line);border-radius:6px;padding:4px 6px;font:inherit}
label{display:flex;gap:5px;align-items:center;color:var(--dim)}
#stage{position:relative;flex:1;min-height:120px;background:#000;border:1px solid var(--line);border-radius:8px;overflow:hidden}
video{position:absolute;left:0;top:0;width:100%;height:100%;object-fit:contain;transform-origin:0 0;background:#000}
#drop{position:absolute;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:6px;color:var(--dim);text-align:center;cursor:pointer;padding:20px}
#drop b{color:var(--txt);font-size:15px}
#seek{flex:1;min-width:120px;accent-color:var(--acc)}
.mono{font-variant-numeric:tabular-nums;color:var(--dim)}
#hint{color:var(--bad);display:none}
</style></head><body>
<div class="bar">
  <span class="title"><span id="dot" class="dot"></span>NOVA VIDEO</span>
  <span id="conn" class="mono"></span>
  <span class="sp"></span>
  <button id="open" data-en="Open video" data-es="Abrir video"></button>
  <button id="pin" data-en="Pin (floating)" data-es="Fijar (flotante)"></button>
  <button id="mute" data-en="Mute" data-es="Silenciar"></button>
  <input id="file" type="file" accept="video/*" hidden>
</div>
<div class="bar">
  <label><span data-en="Delay (ms)" data-es="Retraso (ms)"></span><input id="delay" type="number" value="0" step="10"></label>
  <label><span data-en="Speed" data-es="Velocidad"></span><input id="spd" type="number" value="1" step="0.05" min="0.1" max="8"></label>
  <label><input id="sync" type="checkbox" checked><span data-en="Sync to Nova" data-es="Sincronizar con Nova"></span></label>
  <button id="reset" data-en="Reset" data-es="Reiniciar"></button>
  <span id="hint" data-en="Click the video once to allow playback." data-es="Haz clic en el video una vez para permitir la reproduccion."></span>
</div>
<div id="stage">
  <video id="v" playsinline></video>
  <div id="drop"><b data-en="Drop a video here or click to choose" data-es="Suelta un video aqui o haz clic para elegir"></b>
  <span data-en="Your video stays on your PC. Scroll = zoom, drag = move, double-click = reset." data-es="Tu video se queda en tu PC. Rueda = zoom, arrastrar = mover, doble clic = reiniciar."></span></div>
</div>
<div class="bar">
  <button id="m1">-1</button>
  <button id="play" data-en="Play" data-es="Play"></button>
  <button id="p1">+1</button>
  <input id="seek" type="range" min="0" max="1000" value="0">
  <span id="time" class="mono">00:00.000 &nbsp; F0</span>
</div>
<script>
const $=id=>document.getElementById(id);
const es=(navigator.language||'').toLowerCase().startsWith('es');
document.querySelectorAll('[data-en]').forEach(e=>{e.textContent=es?e.dataset.es:e.dataset.en});
document.documentElement.lang=es?'es':'en';
const v=$('v'), stage=$('stage');
let st={connected:false,playing:false,time:0,speed:1,fps:30,length:0};
let zoom=1,tx=0,ty=0;

function delayS(){return (parseFloat($('delay').value)||0)/1000}
function mul(){return Math.max(0.1,parseFloat($('spd').value)||1)}
function syncOn(){return $('sync').checked && st.connected && !!v.src}
function fmt(t){t=Math.max(0,t);const m=Math.floor(t/60),s=t-m*60;return String(m).padStart(2,'0')+':'+s.toFixed(3).padStart(6,'0')}
function readout(){
  $('time').innerHTML=fmt(v.currentTime)+' &nbsp; F'+Math.round(v.currentTime*(st.fps||30));
  if(v.duration) $('seek').value=Math.round(v.currentTime/v.duration*1000);
}
function conn(){
  $('dot').className='dot'+(st.connected?' on':'');
  $('conn').textContent=st.connected
    ?(es?'Studio conectado':'Studio connected')+(st.playing?' - \u25B6':' - \u275A\u275A')
    :(es?'Esperando a Studio... (SupremeAnimator > Video de referencia)':'Waiting for Studio... (SupremeAnimator > Reference video)');
  $('play').disabled=$('sync').checked&&st.connected;
}
function apply(){
  conn();
  if(!syncOn()) return;
  const target=Math.max(0,st.time*mul()+delayS());
  if(st.playing){
    v.playbackRate=Math.min(16,Math.max(0.0625,st.speed*mul()));
    if(v.paused){v.currentTime=target;v.play().catch(()=>{$('hint').style.display='inline'})}
    else if(Math.abs(v.currentTime-target)>0.2) v.currentTime=target;
  }else{
    if(!v.paused) v.pause();
    if(Math.abs(v.currentTime-target)>0.5/(st.fps||30)) v.currentTime=target;
  }
}
// live state from Studio. A Web Worker does the polling so it is not slowed down when this window is in the background
function listen(){
  const code="let base='';onmessage=e=>{base=e.data;loop()};"
    +"async function loop(){for(;;){const t0=Date.now();"
    +"try{const r=await fetch(base+'/state',{cache:'no-store'});postMessage(await r.json())}catch(_){postMessage(null)}"
    +"await new Promise(r=>setTimeout(r,Math.max(0,100-(Date.now()-t0))))}}";
  const w=new Worker(URL.createObjectURL(new Blob([code],{type:'text/javascript'})));
  w.onmessage=e=>{ if(e.data){st=e.data;apply()} else {st.connected=false;conn()} };
  w.postMessage(location.origin);
}
listen();

function load(f){
  if(!f) return;
  if(v.src) URL.revokeObjectURL(v.src);
  v.src=URL.createObjectURL(f);
  $('drop').style.display='none';
  v.load();
  v.addEventListener('loadeddata',()=>{readout();apply()},{once:true});
}
$('open').onclick=()=>$('file').click();
$('drop').onclick=()=>$('file').click();
$('file').onchange=e=>load(e.target.files[0]);
stage.ondragover=e=>e.preventDefault();
stage.ondrop=e=>{e.preventDefault();load(e.dataTransfer.files[0])};

$('mute').onclick=()=>{v.muted=!v.muted;$('mute').classList.toggle('on',v.muted)};
$('pin').onclick=async()=>{
  try{ if(document.pictureInPictureElement) await document.exitPictureInPicture(); else await v.requestPictureInPicture(); }
  catch(e){ alert(es?'Este navegador no permite la ventana flotante (usa Chrome o Edge).':'This browser cannot float the video (use Chrome or Edge).'); }
};
$('sync').onchange=()=>{conn();apply()};
$('delay').onchange=apply; $('spd').onchange=apply;
$('reset').onclick=()=>{$('delay').value=0;$('spd').value=1;apply()};

function step(n){
  const d=n/(st.fps||30);
  if(syncOn()){ $('delay').value=Math.round((delayS()+d)*1000); apply(); }
  else { v.pause(); v.currentTime=Math.max(0,v.currentTime+d); }
}
$('m1').onclick=()=>step(-1); $('p1').onclick=()=>step(1);
$('play').onclick=()=>{ if(v.paused) v.play(); else v.pause(); $('play').textContent=v.paused?'Play':'Pause'; };
$('seek').oninput=()=>{
  if(!v.duration) return;
  const t=$('seek').value/1000*v.duration;
  if(syncOn()){ $('delay').value=Math.round((t-st.time*mul())*1000); apply(); }  // drag to line the video up with the current Studio frame
  else v.currentTime=t;
};
addEventListener('keydown',e=>{
  if(e.target.tagName==='INPUT'&&e.target.type==='number') return;
  if(e.key==='ArrowLeft'){step(-1);e.preventDefault()} else if(e.key==='ArrowRight'){step(1);e.preventDefault()}
});
if(v.requestVideoFrameCallback){const cb=()=>{readout();v.requestVideoFrameCallback(cb)};v.requestVideoFrameCallback(cb)}
v.addEventListener('timeupdate',readout);
document.addEventListener('click',()=>{$('hint').style.display='none'});

// zoom toward the cursor, drag to move, double-click to reset
function tf(){v.style.transform='translate('+tx+'px,'+ty+'px) scale('+zoom+')'}
stage.addEventListener('wheel',e=>{
  if(!v.src) return; e.preventDefault();
  const r=stage.getBoundingClientRect(), cx=e.clientX-r.left, cy=e.clientY-r.top;
  const nz=Math.min(8,Math.max(1,zoom*(e.deltaY<0?1.15:1/1.15)));
  tx=cx-(cx-tx)*(nz/zoom); ty=cy-(cy-ty)*(nz/zoom); zoom=nz;
  if(zoom===1){tx=0;ty=0} tf();
},{passive:false});
let drag=null;
stage.addEventListener('pointerdown',e=>{if(zoom>1&&v.src){drag={x:e.clientX-tx,y:e.clientY-ty};stage.setPointerCapture(e.pointerId)}});
stage.addEventListener('pointermove',e=>{if(drag){tx=e.clientX-drag.x;ty=e.clientY-drag.y;tf()}});
stage.addEventListener('pointerup',()=>{drag=null});
stage.addEventListener('dblclick',()=>{zoom=1;tx=0;ty=0;tf()});
conn();
</script></body></html>
'@

function Get-Snapshot {
    $age = 1e9
    if ($script:lastUpdate -ge 0) { $age = $sw.Elapsed.TotalSeconds - $script:lastUpdate }
    $t = [double]$state.time
    if ($state.playing -and $script:lastUpdate -ge 0) { $t += [Math]::Min($age, 5.0) * [double]$state.speed }
    $obj = [ordered]@{
        connected = ($age -lt 8.0)
        playing   = ($state.playing -and ($age -lt 8.0))
        time      = $t
        speed     = [double]$state.speed
        fps       = [double]$state.fps
        length    = [double]$state.length
    }
    return ($obj | ConvertTo-Json -Compress)
}

function Update-State($raw) {
    $b = $raw | ConvertFrom-Json
    $state.playing = [bool]$b.playing
    $state.time = [Math]::Max(0.0, [double]$b.time)
    if ($b.speed) { $state.speed = [double]$b.speed } else { $state.speed = 1.0 }
    if ($b.fps) { $state.fps = [double]$b.fps } else { $state.fps = 30.0 }
    $state.length = [double]$b.length
    $script:lastUpdate = $sw.Elapsed.TotalSeconds
}

function Send-Text($res, [string]$text, [string]$type, [int]$code = 200) {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
    $res.StatusCode = $code
    $res.ContentType = $type
    $res.Headers.Add('Cache-Control', 'no-store')
    $res.ContentLength64 = $bytes.Length
    $res.OutputStream.Write($bytes, 0, $bytes.Length)
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:$Port/")
try {
    $listener.Start()
}
catch {
    Write-Host "Could not use port $Port ($($_.Exception.Message))."
    Write-Host "Close the other NovaVideo window or pick another port, for example:  -Port 9000"
    Read-Host "Press Enter to close"
    exit 1
}

$url = "http://127.0.0.1:$Port/"
Write-Host "NovaVideo is running at $url"
Write-Host "1) Pick your video in the page that just opened."
Write-Host "2) In Studio: SupremeAnimator > Reference video (synced) > Sync with NovaVideo."
Write-Host "Leave this window open while you animate. Ctrl+C or close the window to quit."
Start-Process $url

try {
    while ($listener.IsListening) {
        $task = $listener.GetContextAsync()
        while (-not $task.AsyncWaitHandle.WaitOne(250)) { }   # short waits so Ctrl+C still works
        $ctx = $task.GetAwaiter().GetResult()
        $req = $ctx.Request
        $res = $ctx.Response
        try {
            $path = $req.Url.AbsolutePath
            if ($req.HttpMethod -eq 'GET' -and $path -eq '/') {
                Send-Text $res $page 'text/html; charset=utf-8'
            }
            elseif ($req.HttpMethod -eq 'GET' -and $path -eq '/state') {
                Send-Text $res (Get-Snapshot) 'application/json'
            }
            elseif ($req.HttpMethod -eq 'POST' -and $path -eq '/state') {
                $reader = New-Object System.IO.StreamReader($req.InputStream, [System.Text.Encoding]::UTF8)
                Update-State ($reader.ReadToEnd())
                Send-Text $res '{}' 'application/json'
            }
            else {
                Send-Text $res 'not found' 'text/plain' 404
            }
        }
        catch {
            try { Send-Text $res '{}' 'application/json' 400 } catch { }
        }
        finally {
            try { $res.Close() } catch { }
        }
    }
}
finally {
    $listener.Stop()
    $listener.Close()
}
