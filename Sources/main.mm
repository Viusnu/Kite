#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <QuartzCore/QuartzCore.h>

static const CGFloat kWinW = 1400, kWinH = 1050;
static const CGFloat kChromeH = 102;
static const CGFloat kPanelW = 440, kPanelWide = 600;
static const CGFloat kGap = 14;

// ───────────────────────────── DEFAULT STATE (modes + settings) ─────────────────────────────
static const char *kDefaultState = R"KITE({
"v":3,"sites":[{"name":"Google","url":"https://www.google.com"},{"name":"YouTube","url":"https://www.youtube.com"},{"name":"Wikipedia","url":"https://www.wikipedia.org"},{"name":"GitHub","url":"https://github.com"},{"name":"Gmail","url":"https://mail.google.com"},{"name":"Amazon","url":"https://www.amazon.in"}],
"settings":{"home":"","search":"google","theme":"light","assistantOpen":false,
  "apiKey":"","model":"claude-sonnet-5-5","pageContext":true,"language":""},
"activeMode":"shopping",
"modes":[
 {"id":"shopping","builtin":true,"name":"Shopping","emoji":"🛍️","color":"#7c3aed","tone":"balanced","home":"","openOnSwitch":false,
  "prompt":"You are Kite's shopping assistant. Help the user decide what to buy: compare products, suggest outfits and pairings, judge whether a price is fair, and summarize reviews and trade-offs. Ground answers in the page content when it is a product or store page, and say so when the page lacks the information instead of guessing. Mention price, material, fit and value when known.",
  "chips":[
   {"label":"Smart Compare","prompt":"Compare the products or options on this page. Give a short verdict on the best pick and why."},
   {"label":"Mix & Match","prompt":"Give me one clean, wearable outfit or pairing idea for the item I'm viewing, explained piece by piece with why each piece works."},
   {"label":"Price Pulse","prompt":"Is the price here fair? Note what drives the price, what to compare it against, and what to watch for before buying."},
   {"label":"Review Digest","prompt":"Summarize the reviews or key selling points on this page: top pros, top cons, and who it is best for."}]},
 {"id":"personal","builtin":true,"name":"Personal","emoji":"🌿","color":"#0891b2","tone":"balanced","home":"","openOnSwitch":false,
  "prompt":"You are Kite's personal assistant for everyday browsing. Explain things clearly, summarize pages, answer questions about what the user is reading, and help with writing. Be friendly and plain-spoken.",
  "chips":[
   {"label":"Summarize","prompt":"Summarize this page in a few bullet points."},
   {"label":"Explain Simply","prompt":"Explain the main idea of this page simply, as if to a curious friend, with one example."},
   {"label":"Key Facts","prompt":"List the key facts, numbers and names from this page."},
   {"label":"Write Reply","prompt":"Draft a short, friendly reply I could send about this page's topic."}]},
 {"id":"business","builtin":true,"name":"Business","emoji":"💼","color":"#2563eb","tone":"concise","home":"","openOnSwitch":false,
  "prompt":"You are Kite's business assistant. Be concise, structured and decision-oriented. Extract the facts that matter, flag risks and assumptions, and keep a professional tone.",
  "chips":[
   {"label":"Exec Summary","prompt":"Write an executive summary of this page: what it is, why it matters, and the decision or next step it implies."},
   {"label":"Action Items","prompt":"List concrete action items I should take based on this page, in priority order."},
   {"label":"SWOT","prompt":"Give a quick SWOT (strengths, weaknesses, opportunities, threats) for the subject of this page."},
   {"label":"Draft Email","prompt":"Draft a concise professional email I could send about this page's topic."}]}
]})KITE";

// ───────────────────────────── CHROME (tabs + toolbar) ─────────────────────────────
static const char *kChromeHTML = R"KITE(<!DOCTYPE html>
<html><head><meta charset="UTF-8">
<style>
:root{--fg:#1b1c22;--mut:#7a7d88;--tab:rgba(255,255,255,.45);--tabh:rgba(255,255,255,.78);--taba:#fff;
 --addr:rgba(110,110,150,.13);--addra:#fff;--hov:rgba(0,0,0,.06);--seg:rgba(110,110,150,.14);--div:#d6d8df;
 --ac:#7c3aed;--acs:rgba(124,58,237,.12);--acb:rgba(124,58,237,.30)}
[data-theme=dark]{--fg:#ececf1;--mut:#9396a6;--tab:rgba(255,255,255,.06);--tabh:rgba(255,255,255,.12);--taba:#2d2d38;
 --addr:rgba(255,255,255,.08);--addra:#2d2d38;--hov:rgba(255,255,255,.1);--seg:rgba(255,255,255,.08);--div:#40404c}
*{box-sizing:border-box}
html,body{margin:0;height:102px;overflow:hidden;background:transparent}
body{font-family:-apple-system,BlinkMacSystemFont,'SF Pro Text','Inter',sans-serif;color:var(--fg);
  -webkit-user-select:none;user-select:none;position:relative;cursor:default}
svg{width:18px;height:18px;fill:none;stroke:currentColor;stroke-width:2;stroke-linecap:round;stroke-linejoin:round;flex:none}
button{font:inherit;color:inherit;background:none;border:0;padding:0;cursor:pointer;display:flex;align-items:center;justify-content:center}

.top{position:absolute;left:0;right:14px;top:7px;height:31px;display:flex;align-items:center}
.sp{width:86px;flex:none}
.home{width:24px;height:24px;color:var(--mut);margin-right:13px}
.home svg{fill:currentColor;stroke-width:1.5;width:20px;height:20px}
.mode{height:31px;padding:0 11px 0 11px;border-radius:16px;background:var(--acs);border:1px solid var(--acb);color:var(--ac);
  font-size:14px;font-weight:500;gap:7px;flex:none;max-width:230px}
.mode span{white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.mode svg{width:15px;height:15px}
.tabs{display:flex;gap:8.5px;margin-left:26px;min-width:0;overflow:hidden}
.tab{flex:0 1 162px;min-width:84px;height:31px;border-radius:13px;display:flex;align-items:center;padding:0 9px 0 10px;
  gap:8px;background:var(--tab);font-size:13px;opacity:.9;transition:background .15s}
.tab:hover{background:var(--tabh)}
.tab.active{background:var(--taba);opacity:1;box-shadow:0 1px 5px rgba(30,30,60,.14)}
.fav{width:16px;height:16px;border-radius:50%;color:#fff;font-size:9px;font-weight:700;display:flex;align-items:center;justify-content:center;flex:none}
.ttl{flex:1;min-width:0;white-space:nowrap;overflow:hidden;-webkit-mask-image:linear-gradient(90deg,#000 calc(100% - 18px),transparent)}
.x{width:16px;height:16px;border-radius:5px;display:flex;align-items:center;justify-content:center;flex:none}
.x svg{width:13px;height:13px}
.x:hover{background:var(--hov)}
.plus{width:28px;height:28px;margin-left:5px;color:var(--mut);border-radius:8px;flex:none}
.plus:hover{background:var(--hov)}
.tabmenu{margin-left:auto;width:30px;height:28px;border-radius:9px;flex:none}
.tabmenu:hover{background:var(--hov)}

.row{position:absolute;left:17px;right:14px;top:54px;height:38px;display:flex;align-items:center}
.ib{width:28px;height:28px;border-radius:8px;margin-right:1.5px}
.ib:hover{background:var(--hov)}
.ib svg{width:19px;height:19px}
.addr{flex:1;margin-left:19px;height:38px;border-radius:15px;background:var(--addr);display:flex;align-items:center;
  padding:0 12px 0 14px;gap:10px;position:relative;min-width:0;transition:background .15s,box-shadow .15s}
.addr.editing{background:var(--addra);box-shadow:0 0 0 2px var(--acb)}
.addr>svg{width:18px;height:18px}
.view{flex:1;font-size:14.5px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;cursor:text;min-width:0}
.view .p{color:var(--mut)}
.view:empty:before{content:'Search or enter a website';color:var(--mut)}
.addr.editing .view{display:none}
.addr:not(.editing) input{position:absolute;opacity:0;pointer-events:none}
input{flex:1;font:inherit;font-size:14.5px;border:0;outline:0;background:transparent;color:var(--fg);min-width:0;-webkit-user-select:text}
.ai-i{width:28px;height:28px;border-radius:8px}
.ai-i svg{width:18px;height:18px}
.ai-i:hover{background:var(--hov)}
.rg{display:flex;align-items:center;margin-left:14px}
.theme{display:flex;background:var(--seg);border-radius:18px;padding:2px;margin-left:6px}
.tb{width:31px;height:31px;border-radius:50%;color:var(--mut)}
.tb svg{width:16px;height:16px}
.tb.on{background:#17181d;color:#fff;box-shadow:0 2px 6px rgba(0,0,0,.25)}
[data-theme=dark] .tb.on{background:#f3f3f7;color:#17181d}
.avatar{width:37px;height:37px;border-radius:50%;margin-left:12px;background:linear-gradient(135deg,#f6cdd8,#aebcff);
  border:1px solid #fff;box-shadow:0 0 0 1px rgba(0,0,0,.08);display:flex;align-items:flex-end;justify-content:center;overflow:hidden;color:#fff}
.avatar svg{fill:currentColor;stroke:none;width:30px;height:30px;margin-bottom:-4px}
.div{width:1px;height:14px;background:var(--div);margin:0 14px 0 19px}
.asst{height:39px;min-width:129px;border-radius:20px;background:var(--acs);border:1px solid var(--acb);color:var(--ac);
  font-size:14.5px;font-weight:500;gap:8px;padding:0 10px 0 9px}
.orb{width:24px;height:24px;border-radius:50%;flex:none;background:radial-gradient(circle at 35% 30%,#fff 0,var(--acb) 30%,var(--ac) 100%)}
.asst svg{width:14px;height:14px}
</style></head>
<body>
<div class="top">
  <div class="sp"></div>
  <button class="home" onclick="post({action:'home'})"><svg viewBox="0 0 24 24"><path d="M3 10.5 12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z"/></svg></button>
  <button class="mode" id="modeBtn" onclick="modeMenu()"><span id="mEm">🛍️</span><span id="mNm">Shopping Mode</span><svg viewBox="0 0 24 24"><path d="m6 9 6 6 6-6"/></svg></button>
  <div class="tabs" id="tabs"></div>
  <button class="plus" onclick="post({action:'newTab'})"><svg viewBox="0 0 24 24"><path d="M12 5v14M5 12h14"/></svg></button>
  <button class="tabmenu"><svg viewBox="0 0 24 24"><path d="m6 9 6 6 6-6"/></svg></button>
</div>
<div class="row">
  <button class="ib" onclick="post({action:'back'})"><svg viewBox="0 0 24 24"><path d="m15 18-6-6 6-6"/></svg></button>
  <button class="ib" onclick="post({action:'forward'})"><svg viewBox="0 0 24 24"><path d="m9 18 6-6-6-6"/></svg></button>
  <button class="ib" onclick="post({action:'reload'})"><svg viewBox="0 0 24 24"><path d="M21 12a9 9 0 1 1-3-6.7L21 8"/><path d="M21 3v5h-5"/></svg></button>
  <button class="ib" title="Settings" onclick="post({action:'openSettings'})"><svg viewBox="0 0 24 24"><path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/><circle cx="12" cy="12" r="3"/></svg></button>

  <div class="addr" id="addr">
    <svg viewBox="0 0 24 24"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
    <div class="view" id="view" onclick="edit()"></div>
    <input id="url" spellcheck="false" placeholder="Search or enter URL..." onblur="unedit()" onkeydown="if(event.key==='Enter'){go()}if(event.key==='Escape'){this.blur()}">
    <button class="ai-i" title="Bookmark"><svg viewBox="0 0 24 24"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg></button>
    <button class="ai-i" title="Mode settings" onclick="post({action:'openSettings',tab:'modes'})"><svg viewBox="0 0 24 24"><line x1="21" x2="14" y1="4" y2="4"/><line x1="10" x2="3" y1="4" y2="4"/><line x1="21" x2="12" y1="12" y2="12"/><line x1="8" x2="3" y1="12" y2="12"/><line x1="21" x2="16" y1="20" y2="20"/><line x1="12" x2="3" y1="20" y2="20"/><line x1="14" x2="14" y1="2" y2="6"/><line x1="8" x2="8" y1="10" y2="14"/><line x1="16" x2="16" y1="18" y2="22"/></svg></button>
  </div>

  <div class="rg">
    <div class="theme">
      <button class="tb on" id="tSun" onclick="post({action:'theme',value:'light'})"><svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.93 19.07l1.41-1.41M17.66 6.34l1.41-1.41M2 12h2M20 12h2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41"/></svg></button>
      <button class="tb" id="tMoon" onclick="post({action:'theme',value:'dark'})"><svg viewBox="0 0 24 24"><path d="M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z"/></svg></button>
    </div>
    <div class="avatar"><svg viewBox="0 0 24 24"><circle cx="12" cy="8" r="4.2"/><path d="M3 24c0-5 4-8 9-8s9 3 9 8z"/></svg></div>
    <div class="div"></div>
    <button class="asst" onclick="post({action:'toggleAssistant'})"><span class="orb"></span><span>Assistant</span><span id="asstIc"></span></button>
  </div>
</div>
<script>
const post=m=>window.webkit.messageHandlers.kiteHost.postMessage(m);
const X='<svg viewBox="0 0 24 24"><path d="M18 6 6 18M6 6l12 12"/></svg>';
const CH='<svg viewBox="0 0 24 24"><path d="m6 9 6 6 6-6"/></svg>';
const $=id=>document.getElementById(id);
const addr=$('addr'),input=$('url'),view=$('view');
let cur='',S=null;
function hexRgb(h){h=h.replace('#','');return [0,2,4].map(i=>parseInt(h.substr(i,2),16))}
function setAccent(c){const [r,g,b]=hexRgb(c),st=document.documentElement.style;
  st.setProperty('--ac',c);st.setProperty('--acs','rgba('+r+','+g+','+b+',.12)');st.setProperty('--acb','rgba('+r+','+g+','+b+',.30)')}
function applyState(s){
  S=s;document.documentElement.dataset.theme=s.settings.theme;
  const m=s.modes.find(x=>x.id===s.activeMode)||s.modes[0];setAccent(m.color);
  $('mEm').textContent=m.emoji;$('mNm').textContent=/mode$/i.test(m.name)?m.name:m.name+' Mode';
  $('tSun').classList.toggle('on',s.settings.theme!=='dark');$('tMoon').classList.toggle('on',s.settings.theme==='dark');
  $('asstIc').innerHTML=s.panelOpen?X:CH;
}
function modeMenu(){const r=$('modeBtn').getBoundingClientRect();post({action:'modeMenu',x:r.left,y:r.bottom+4})}
function color(s){let h=0;for(const c of (s||'x'))h=(h*31+c.charCodeAt(0))%360;return 'hsl('+h+',55%,42%)'}
function renderUrl(u){
  input.value=u;view.textContent='';
  try{const x=new URL(u);
    const h=document.createElement('span');h.className='h';h.textContent=x.host.replace(/^www\./,'');
    const p=document.createElement('span');p.className='p';p.textContent=(x.pathname==='/'?'':x.pathname)+x.search;
    view.append(h,p);
  }catch(e){view.textContent=u}
}
function edit(){addr.classList.add('editing');input.focus();input.select()}
function unedit(){addr.classList.remove('editing');renderUrl(cur)}
function go(){post({action:'navigate',url:input.value});input.blur()}
function updateState(s){
  cur=s.currentUrl||'';
  if(!addr.classList.contains('editing'))renderUrl(cur);
  const list=$('tabs');list.textContent='';
  s.tabs.forEach((t,i)=>{
    const d=document.createElement('div');d.className='tab'+(i===s.active?' active':'');
    const f=document.createElement('span');f.className='fav';f.textContent=(t.title||'N').trim().charAt(0).toUpperCase();f.style.background=color(t.title);
    const ti=document.createElement('span');ti.className='ttl';ti.textContent=t.title;
    const x=document.createElement('span');x.className='x';x.innerHTML=X;
    x.onclick=e=>{e.stopPropagation();post({action:'closeTab',index:i})};
    d.append(f,ti,x);d.onclick=()=>post({action:'switchTab',index:i});list.appendChild(d);
  });
}
document.addEventListener('mousedown',e=>{if(!e.target.closest('button,.tab,.addr,input'))post({action:'drag'})});
document.addEventListener('dblclick',e=>{if(!e.target.closest('button,.tab,.addr,input'))post({action:'zoom'})});
</script></body></html>)KITE";

// ───────────────────────────── AI ASSISTANT PANEL ─────────────────────────────
static const char *kSidebarHTML = R"KITE(<!DOCTYPE html>
<html><head><meta charset="UTF-8">
<style>
:root{--bg:#fff;--fg:#17171c;--line:#ececf0;--card:#fafafc;--bub:#f6f6f9;--foot:#f6f6fa;--inner:#fff;--mut:#7d7f8b;
 --ac:#7c3aed;--acs:rgba(124,58,237,.12);--acb:rgba(124,58,237,.28)}
[data-theme=dark]{--bg:#1a1a21;--fg:#ececf1;--line:#2c2c36;--card:#22222b;--bub:#262630;--foot:#20202a;--inner:#16161d;--mut:#8d90a0}
*{box-sizing:border-box}
html,body{margin:0;height:100%}
body{display:flex;flex-direction:column;background:var(--bg);color:var(--fg);position:relative;
  font-family:-apple-system,BlinkMacSystemFont,'SF Pro Text','Inter',sans-serif;font-size:14.5px;letter-spacing:-.012em;overflow:hidden}
svg{width:20px;height:20px;fill:none;stroke:currentColor;stroke-width:2;stroke-linecap:round;stroke-linejoin:round;flex:none}
button{font:inherit;color:inherit;background:none;border:0;padding:0;cursor:pointer;display:flex;align-items:center;justify-content:center}

header{height:66px;flex:none;border-bottom:1px solid var(--line);display:flex;align-items:center;padding:0 16px 0 20px}
.spark{width:19px;height:19px;fill:var(--ac);stroke:var(--ac);stroke-width:1.4}
h1{margin:0 0 0 9px;font-size:20px;font-weight:500;letter-spacing:-.025em}
.analyze{margin-left:10px;height:26px;padding:0 10px;border-radius:14px;background:var(--acs);color:var(--ac);font-size:12.5px;font-weight:500;gap:5px;border:1px solid var(--acb)}
.analyze:hover{filter:brightness(.96)}
.hr{margin-left:auto;display:flex;gap:1px}
.hr button{width:31px;height:30px;border-radius:8px}
.hr button:hover{background:var(--bub)}
.hr svg{width:18px;height:18px}
.menu{position:absolute;top:58px;right:14px;background:var(--bg);border:1px solid var(--line);border-radius:12px;padding:5px;min-width:190px;
  box-shadow:0 10px 30px rgba(0,0,0,.16);display:none;z-index:5}
.menu button{width:100%;justify-content:flex-start;padding:8px 10px;border-radius:8px;font-size:13.5px}
.menu button:hover{background:var(--bub)}

.ctx{flex:none;display:flex;align-items:center;gap:8px;margin:10px 16px 0;padding:6px 8px 6px 7px;border:1px solid var(--line);border-radius:12px;background:var(--card)}
.ctx .fav{width:22px;height:22px;border-radius:6px;background:var(--ac);color:#fff;font-size:11px;font-weight:700;display:flex;align-items:center;justify-content:center;flex:none}
.ctx .ct{flex:1;min-width:0;font-size:12.5px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.ctx .cl{font-size:11.5px;color:var(--mut)}
.sw{width:30px;height:18px;border-radius:10px;background:var(--line);position:relative;flex:none;transition:background .15s}
.sw i{position:absolute;left:2px;top:2px;width:14px;height:14px;border-radius:50%;background:#fff;box-shadow:0 1px 3px rgba(0,0,0,.3);transition:left .15s}
.sw.on{background:var(--ac)}.sw.on i{left:14px}

#scroll{flex:1;min-height:0;overflow-y:auto;padding:18px 18px 26px 18px}
#scroll::-webkit-scrollbar{width:0}
.ubub{margin:14px 0 0 auto;max-width:86%;width:fit-content;background:var(--bub);border-radius:14px;padding:10px 14px;line-height:1.5;border:1px solid var(--line);white-space:pre-wrap;word-break:break-word}
.ai{position:relative;margin-top:16px;padding-left:28px;line-height:1.55;word-break:break-word}
.ai .orb{position:absolute;left:0;top:3px;width:18px;height:18px;border-radius:50%;background:radial-gradient(circle at 35% 30%,#fff 0,var(--acb) 30%,var(--ac) 100%)}
.ai p{margin:0 0 8px}.ai p:last-child{margin-bottom:0}
.ai ul,.ai ol{margin:0 0 8px;padding-left:20px}.ai li{margin-bottom:4px}
.ai h5{margin:10px 0 4px;font-size:14.5px;font-weight:600}
.ai code{background:var(--bub);border:1px solid var(--line);border-radius:5px;padding:0 4px;font-size:12.5px}
.ai.err{color:#e5484d}
.ai .tools{margin-top:6px;display:flex;gap:6px}
.mini{height:24px;padding:0 9px;border:1px solid var(--line);border-radius:12px;font-size:11.5px;color:var(--mut)}
.mini:hover{background:var(--bub);color:var(--fg)}
.dots{display:inline-flex;gap:4px;padding:6px 0}
.dots i{width:6px;height:6px;border-radius:50%;background:var(--ac);opacity:.35;animation:b 1s infinite}
.dots i:nth-child(2){animation-delay:.15s}.dots i:nth-child(3){animation-delay:.3s}
@keyframes b{0%,80%,100%{opacity:.25;transform:translateY(0)}40%{opacity:1;transform:translateY(-3px)}}

footer{flex:none;margin:0 14px 14px;border:1px solid var(--line);border-radius:20px;background:var(--foot);box-shadow:0 2px 12px rgba(20,20,40,.05)}
.chips{display:flex;align-items:center;gap:5px;padding:8px 8px 8px 10px}
#chips{display:flex;gap:5px;overflow-x:auto;flex:1;min-width:0;scrollbar-width:none}
#chips::-webkit-scrollbar{display:none}
.c{height:29px;padding:0 12px;border-radius:15px;font-size:12.5px;font-weight:450;white-space:nowrap;flex:none;border:1px solid transparent}
.c:hover{background:var(--acs);color:var(--ac);border-color:var(--acb)}
.more{margin-left:2px;width:29px;height:29px;border-radius:50%;background:var(--inner);border:1px solid var(--line);flex:none}
.more svg{width:14px;height:14px;fill:currentColor;stroke:none}
.inner{background:var(--inner);border-radius:17px;margin:0 2px 2px;padding:12px 14px 12px;border-top:1px solid var(--line)}
#attrow{display:flex;gap:6px;flex-wrap:wrap}
#attrow:not(:empty){margin-bottom:8px}
.att{display:flex;align-items:center;gap:6px;background:var(--bub);border:1px solid var(--line);border-radius:10px;padding:3px 6px 3px 8px;font-size:12px;max-width:100%}
.att button{width:16px;height:16px;border-radius:4px;color:var(--mut)}
.att svg{width:11px;height:11px}
textarea{display:block;width:100%;height:46px;max-height:120px;border:0;outline:0;resize:none;font:inherit;font-size:14px;color:var(--fg);background:transparent;letter-spacing:-.01em}
textarea::placeholder{color:var(--mut)}
.act{display:flex;align-items:center;gap:7px;margin-top:6px}
.sm{height:27px;padding:0 10px;border:1px solid var(--line);border-radius:14px;font-size:12px;gap:6px;background:var(--inner)}
.sm:hover{background:var(--bub)}
.sm svg{width:12px;height:12px}
.send{margin-left:auto;width:31px;height:31px;border-radius:50%;background:var(--fg);color:var(--bg)}
.send svg{width:16px;height:16px;stroke-width:2.4}
</style></head>
<body>
<header>
  <svg class="spark" viewBox="0 0 24 24"><path d="M9.937 15.5A2 2 0 0 0 8.5 14.063l-6.135-1.582a.5.5 0 0 1 0-.962L8.5 9.936A2 2 0 0 0 9.937 8.5l1.582-6.135a.5.5 0 0 1 .963 0L14.063 8.5A2 2 0 0 0 15.5 9.937l6.135 1.581a.5.5 0 0 1 0 .964L15.5 14.063a2 2 0 0 0-1.437 1.437l-1.582 6.135a.5.5 0 0 1-.963 0z"/></svg>
  <h1>AI Assistant</h1>
  <button class="analyze" onclick="analyze()"><svg viewBox="0 0 24 24" style="width:12px;height:12px"><circle cx="12" cy="12" r="9" stroke-dasharray=".1 4.2" stroke-width="3"/></svg>Analyze</button>
  <div class="hr">
    <button title="Resize panel" onclick="post({action:'expand'})"><svg viewBox="0 0 24 24"><path d="M15 3h6v6M9 21H3v-6M21 3l-7 7M3 21l7-7"/></svg></button>
    <button title="New chat" onclick="newChat()"><svg viewBox="0 0 24 24"><path d="M12 3H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.4 2.6a2.1 2.1 0 0 1 3 3L12 15l-4 1 1-4Z"/></svg></button>
    <button title="More" onclick="toggleMenu(event)"><svg viewBox="0 0 24 24" style="fill:currentColor;stroke:none"><circle cx="12" cy="5" r="1.6"/><circle cx="12" cy="12" r="1.6"/><circle cx="12" cy="19" r="1.6"/></svg></button>
  </div>
</header>
<div class="menu" id="menu">
  <button onclick="newChat()">New chat</button>
  <button onclick="post({action:'settings',tab:'modes'})">Customize this mode</button>
  <button onclick="post({action:'settings',tab:'assistant'})">Assistant settings</button>
  <button onclick="clearAll()">Clear all chats</button>
</div>

<div class="ctx"><span class="fav" id="cf">K</span><span class="ct" id="ct">No page</span><span class="cl">Page context</span><button class="sw on" id="sw" title="Let the assistant read this page" onclick="togglePage()"><i></i></button></div>

<div id="scroll"><div id="chat"></div></div>

<footer>
  <div class="chips"><div id="chips"></div>
    <button class="more" title="Customize quick actions" onclick="post({action:'settings',tab:'modes'})"><svg viewBox="0 0 24 24"><circle cx="5" cy="12" r="1.8"/><circle cx="12" cy="12" r="1.8"/><circle cx="19" cy="12" r="1.8"/></svg></button>
  </div>
  <div class="inner">
    <div id="attrow"></div>
    <textarea id="ta" placeholder="Ask for outfit ideas or anything you need…" oninput="grow()" onkeydown="if(event.key==='Enter'&&!event.shiftKey){event.preventDefault();sendInput()}"></textarea>
    <div class="act">
      <button class="sm" onclick="post({action:'attach'})"><svg viewBox="0 0 24 24"><path d="m21.44 11.05-9.19 9.19a6 6 0 0 1-8.49-8.49l8.57-8.57A4 4 0 1 1 18 8.84l-8.59 8.57a2 2 0 0 1-2.83-2.83l8.49-8.48"/></svg>Attach Files</button>
      <button class="sm" onclick="dictate()"><svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="3"/></svg>Voice Message</button>
      <button class="send" onclick="sendInput()"><svg viewBox="0 0 24 24"><path d="M12 19V5M5 12l7-7 7 7"/></svg></button>
    </div>
  </div>
</footer>

<script>
const post=m=>window.webkit.messageHandlers.kiteAI.postMessage(m);
const $=id=>document.getElementById(id);
let S=null,mid=null,hist={},pend={},page={t:'',u:''},usePage=true,att=[],inited=false,seq=0;
function hexRgb(h){h=h.replace('#','');return [0,2,4].map(i=>parseInt(h.substr(i,2),16))}
function setAccent(c){const [r,g,b]=hexRgb(c),st=document.documentElement.style;
  st.setProperty('--ac',c);st.setProperty('--acs','rgba('+r+','+g+','+b+',.12)');st.setProperty('--acb','rgba('+r+','+g+','+b+',.30)')}
function mode(){return S.modes.find(m=>m.id===S.activeMode)||S.modes[0]}
function esc(s){return String(s).replace(/[&<>]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;'}[c]))}
function inline(s){return esc(s).replace(/`([^`]+)`/g,'<code>$1</code>').replace(/\*\*([^*]+)\*\*/g,'<b>$1</b>').replace(/(^|[^*])\*([^*\n]+)\*/g,'$1<i>$2</i>')}
function md(t){let out='',list=null;const close=()=>{if(list){out+='</'+list+'>';list=null}};
  for(const raw of String(t).split('\n')){const l=raw.trimEnd();let m;
    if(m=l.match(/^\s*[-*•]\s+(.*)/)){if(list!=='ul'){close();out+='<ul>';list='ul'}out+='<li>'+inline(m[1])+'</li>'}
    else if(m=l.match(/^\s*\d+[.)]\s+(.*)/)){if(list!=='ol'){close();out+='<ol>';list='ol'}out+='<li>'+inline(m[1])+'</li>'}
    else if(!l.trim()){close()}
    else{close();m=l.match(/^#{1,4}\s+(.*)/);out+=m?'<h5>'+inline(m[1])+'</h5>':'<p>'+inline(l)+'</p>'}}
  close();return out}

function applyState(s){
  const first=!inited,prev=mid;S=s;const m=mode();
  document.documentElement.dataset.theme=s.settings.theme;setAccent(m.color);
  if(first){usePage=s.settings.pageContext!==false;inited=true;renderPage()}
  mid=m.id;renderChips(m);
  if(first||prev!==mid||!(hist[mid]||[]).length)renderChat();
}
function setPage(p){page=p;renderPage()}
function renderPage(){
  const t=(page.t||'').trim();$('cf').textContent=(t||'K').charAt(0).toUpperCase();
  let host='';try{host=new URL(page.u).host.replace(/^www\./,'')}catch(e){}
  $('ct').textContent=t?(t+(host?' · '+host:'')):'No page';
  $('sw').classList.toggle('on',usePage);$('ct').style.opacity=usePage?1:.5;
}
function togglePage(){usePage=!usePage;renderPage()}
function renderChips(m){const c=$('chips');c.innerHTML='';
  (m.chips||[]).forEach(ch=>{const b=document.createElement('button');b.className='c';b.textContent=ch.label;b.onclick=()=>send(ch.label,ch.prompt);c.appendChild(b)})}
function bottom(){const s=$('scroll');s.scrollTop=s.scrollHeight}
function addUser(t){const d=document.createElement('div');d.className='ubub';d.textContent=t;$('chat').appendChild(d)}
function addAI(t,opt){opt=opt||{};const d=document.createElement('div');d.className='ai'+(opt.err?' err':'');
  d.innerHTML='<span class="orb"></span><div class="body">'+md(t)+'</div>';
  const tools=document.createElement('div');tools.className='tools';
  if(opt.copy){const b=document.createElement('button');b.className='mini';b.textContent='Copy';
    b.onclick=()=>{try{navigator.clipboard.writeText(t);b.textContent='Copied'}catch(e){b.textContent='Copy failed'}};tools.appendChild(b)}
  if(opt.settings){const b=document.createElement('button');b.className='mini';b.textContent='Open Settings';b.onclick=()=>post({action:'settings',tab:'assistant'});tools.appendChild(b)}
  if(tools.children.length)d.appendChild(tools);
  $('chat').appendChild(d)}
function showTyping(){const d=document.createElement('div');d.className='ai';d.id='typing';d.innerHTML='<span class="orb"></span><span class="dots"><i></i><i></i><i></i></span>';$('chat').appendChild(d)}
function renderChat(){const c=$('chat');c.innerHTML='';const m=mode();const h=hist[m.id]||[];
  if(!h.length)addAI("Hi! I'm in **"+m.name+"** mode "+m.emoji+". Ask me anything about the page you're on, or tap a quick action below.");
  h.forEach(x=>{if(x.role==='user')addUser(x.shown||x.content);else addAI(x.content,{copy:true})});
  if(Object.values(pend).some(p=>p.mode===m.id))showTyping();bottom()}
function send(shown,prompt,force){
  if(!S)return;const m=mode();let content=prompt||shown;
  if(att.length)content+='\n\n'+att.map(a=>'[Attached file: '+a.name+']\n'+a.text).join('\n\n');
  const shownText=shown+(att.length?'\n📎 '+att.map(a=>a.name).join(', '):'');
  att=[];renderAtt();
  (hist[m.id]=hist[m.id]||[]).push({role:'user',content:content,shown:shownText});
  const id='r'+(++seq);pend[id]={mode:m.id};
  const msgs=hist[m.id].slice(-12).map(x=>({role:x.role,content:x.content}));
  while(msgs.length&&msgs[0].role!=='user')msgs.shift();
  renderChat();
  post({action:'ask',id:id,mode:m.id,usePage:!!(usePage||force),messages:msgs});
}
function receiveReply(r){
  const p=pend[r.id];delete pend[r.id];if(!p)return;
  if(r.error){renderChat();if(mode().id===p.mode){
    if(r.error==='NO_KEY')addAI("I need an API key before I can answer. Add one in **Settings → Assistant**.",{err:true,settings:true});
    else addAI('Something went wrong: '+r.error,{err:true});bottom()}return}
  (hist[p.mode]=hist[p.mode]||[]).push({role:'assistant',content:r.text||'(empty reply)'});
  if(mode().id===p.mode)renderChat();
}
function sendInput(){const v=$('ta').value.trim();if(!v&&!att.length)return;$('ta').value='';grow();send(v||'Please look at the attached file.',v)}
function analyze(){send('Analyze this page','Analyze this page for me: what it is, what it is for, and the 3 most useful things to know. Be brief.',true)}
function grow(){const t=$('ta');t.style.height='46px';t.style.height=Math.min(t.scrollHeight,120)+'px'}
function newChat(){hist[mid]=[];att=[];renderAtt();renderChat();$('menu').style.display='none'}
function clearAll(){hist={};att=[];renderAtt();renderChat();$('menu').style.display='none'}
function toggleMenu(e){e.stopPropagation();const m=$('menu');m.style.display=m.style.display==='block'?'none':'block'}
document.addEventListener('click',()=>{$('menu').style.display='none'});
function renderAtt(){const r=$('attrow');r.innerHTML='';att.forEach((a,i)=>{const d=document.createElement('div');d.className='att';
  d.append('📎 '+a.name);const b=document.createElement('button');b.innerHTML='<svg viewBox="0 0 24 24"><path d="M18 6 6 18M6 6l12 12"/></svg>';
  b.onclick=()=>{att.splice(i,1);renderAtt()};d.appendChild(b);r.appendChild(d)})}
function addAttachment(o){if(o.error){addAI(o.error,{err:true});bottom();return}att.push({name:o.name,text:o.text});renderAtt()}
function dictate(){$('ta').focus();post({action:'dictate'})}
</script></body></html>)KITE";

// ───────────────────────────── SETTINGS ─────────────────────────────
static const char *kSettingsHTML = R"KITE(<!DOCTYPE html>
<html><head><meta charset="UTF-8">
<style>
:root{color-scheme:light;--bg:#fff;--side:#f6f6fa;--fg:#17171c;--mut:#7d7f8b;--line:#e8e8ee;--in:#fff;--inb:#dcdce4;--hov:#f0f0f5;
 --ac:#7c3aed;--acs:rgba(124,58,237,.12);--acb:rgba(124,58,237,.30)}
[data-theme=dark]{color-scheme:dark;--bg:#1a1a21;--side:#16161c;--fg:#ececf1;--mut:#8d90a0;--line:#2c2c36;--in:#23232c;--inb:#3a3a46;--hov:#262630}
*{box-sizing:border-box}
html,body{margin:0;height:100%}
body{background:var(--bg);color:var(--fg);font-family:-apple-system,BlinkMacSystemFont,'SF Pro Text','Inter',sans-serif;font-size:14px;letter-spacing:-.01em;display:flex;overflow:hidden}
button{font:inherit;color:inherit;background:none;border:0;padding:0;cursor:pointer}
aside{width:200px;flex:none;background:var(--side);border-right:1px solid var(--line);padding:22px 12px;display:flex;flex-direction:column}
aside h2{margin:0 10px 16px;font-size:18px;font-weight:600;letter-spacing:-.02em}
.nav{display:flex;align-items:center;gap:9px;width:100%;text-align:left;padding:9px 10px;border-radius:9px;font-size:14px;margin-bottom:2px}
.nav:hover{background:var(--hov)}.nav.on{background:var(--acs);color:var(--ac);font-weight:500}
.foot{margin-top:auto;font-size:11.5px;color:var(--mut);padding:0 10px;line-height:1.5}
main{flex:1;min-width:0;display:flex;flex-direction:column}
.mh{height:60px;flex:none;border-bottom:1px solid var(--line);display:flex;align-items:center;padding:0 22px}
.mh h3{margin:0;font-size:16px;font-weight:600}
#saved{margin-left:12px;font-size:12px;color:var(--mut)}
.close{margin-left:auto;width:30px;height:30px;border-radius:8px;font-size:18px;color:var(--mut)}
.close:hover{background:var(--hov)}
.body{flex:1;min-height:0;overflow-y:auto;padding:22px 26px 30px}
.panel{display:none}
.group{border:1px solid var(--line);border-radius:14px;padding:4px 16px;margin-bottom:18px}
.r{display:flex;align-items:center;gap:16px;padding:13px 0;border-bottom:1px solid var(--line)}
.r:last-child{border-bottom:0}
.r .l{flex:1;min-width:0}.r .l b{display:block;font-weight:500}.r .l span{display:block;font-size:12px;color:var(--mut);margin-top:2px;line-height:1.4}
input[type=text],input[type=password],select,textarea{font:inherit;font-size:13.5px;color:var(--fg);background:var(--in);border:1px solid var(--inb);border-radius:9px;padding:8px 10px;outline:0;min-width:0}
input:focus,select:focus,textarea:focus{border-color:var(--ac);box-shadow:0 0 0 3px var(--acs)}
.r input[type=text],.r input[type=password]{width:260px}
.r select{width:260px}
textarea{width:100%;resize:vertical;line-height:1.5}
.seg{display:flex;background:var(--hov);border-radius:9px;padding:2px}
.seg button{padding:6px 14px;border-radius:7px;font-size:13px;color:var(--mut)}
.seg button.on{background:var(--in);color:var(--fg);box-shadow:0 1px 3px rgba(0,0,0,.15)}
.sw{width:38px;height:22px;border-radius:11px;background:var(--inb);position:relative;flex:none;transition:background .15s}
.sw i{position:absolute;left:2px;top:2px;width:18px;height:18px;border-radius:50%;background:#fff;box-shadow:0 1px 3px rgba(0,0,0,.3);transition:left .15s}
.sw.on{background:var(--ac)}.sw.on i{left:18px}
.btn{height:32px;padding:0 14px;border-radius:9px;border:1px solid var(--inb);background:var(--in);font-size:13px}
.btn:hover{background:var(--hov)}
.btn.pri{background:var(--ac);border-color:var(--ac);color:#fff}.btn.pri:hover{filter:brightness(1.08);background:var(--ac)}
.btn.dng{color:#e5484d;border-color:rgba(229,72,77,.4)}
.note{font-size:12px;color:var(--mut);margin:-8px 2px 18px;line-height:1.5}

.mwrap{display:flex;gap:18px;min-height:0}
#mlist{width:200px;flex:none}
.mi{display:flex;align-items:center;gap:9px;width:100%;text-align:left;padding:8px 10px;border-radius:10px;margin-bottom:3px;border:1px solid transparent}
.mi:hover{background:var(--hov)}.mi.on{background:var(--acs);border-color:var(--acb)}
.mi .e{font-size:17px}.mi .n{flex:1;min-width:0;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.mi .act{font-style:normal;font-size:10.5px;color:var(--ac);font-weight:600}
.add{width:100%;text-align:left;padding:9px 10px;border:1px dashed var(--inb);border-radius:10px;color:var(--mut);margin-top:6px}
.add:hover{background:var(--hov);color:var(--fg)}
#med{flex:1;min-width:0}
.f{margin-bottom:16px}.f>label{display:block;font-size:12px;font-weight:600;color:var(--mut);text-transform:uppercase;letter-spacing:.04em;margin-bottom:6px}
.f input[type=text],.f select{width:100%}
.two{display:grid;grid-template-columns:90px 1fr;gap:12px}
.emo{display:flex;flex-wrap:wrap;gap:4px;margin-top:6px}
.emo button{width:30px;height:30px;border-radius:8px;font-size:16px}.emo button:hover{background:var(--hov)}
.sws{display:flex;align-items:center;gap:8px;flex-wrap:wrap}
.sc{width:26px;height:26px;border-radius:50%;border:2px solid transparent;box-shadow:0 0 0 1px var(--inb)}
.sc.on{border-color:var(--bg);box-shadow:0 0 0 2px var(--fg)}
input[type=color]{width:34px;height:28px;padding:0;border:0;background:none;cursor:pointer}
.cr{display:grid;grid-template-columns:150px 1fr 30px;gap:8px;margin-bottom:8px}
.cr button{border-radius:8px;color:var(--mut)}.cr button:hover{background:var(--hov);color:#e5484d}
.chk{display:flex;align-items:center;gap:8px;margin-top:8px;font-size:13px;color:var(--mut)}
.btns{display:flex;gap:8px;flex-wrap:wrap;margin-top:6px;padding-top:16px;border-top:1px solid var(--line)}
</style></head>
<body>
<aside>
  <h2>Settings</h2>
  <button class="nav on" id="n-general" onclick="showTab('general')">⚙️ General</button>
  <button class="nav" id="n-assistant" onclick="showTab('assistant')">✨ Assistant</button>
  <button class="nav" id="n-modes" onclick="showTab('modes')">🎛️ Modes</button>
  <div class="foot">Kite Browser<br>Everything is stored locally on this Mac.</div>
</aside>
<main>
  <div class="mh"><h3 id="ttl">General</h3><span id="saved"></span><button class="close" onclick="closeS()">✕</button></div>
  <div class="body">

  <div class="panel" id="p-general">
    <div class="group">
      <div class="r"><div class="l"><b>Home page</b><span>Leave empty to use the Kite start page</span></div><input type="text" id="home" placeholder="Empty = Kite start page" oninput="S.settings.home=this.value;commit()"><button class="btn" onclick="S.settings.home='';$('home').value='';commit()">Kite Home</button></div>
      <div class="r"><div class="l"><b>Search engine</b><span>Used when you type something that isn't a URL</span></div>
        <select id="search" onchange="S.settings.search=this.value;commit()"><option value="google">Google</option><option value="duckduckgo">DuckDuckGo</option><option value="bing">Bing</option><option value="brave">Brave Search</option></select></div>
      <div class="r"><div class="l"><b>Appearance</b><span>Applies to the toolbar, assistant and settings</span></div>
        <div class="seg"><button id="th-light" onclick="setTheme('light')">☀️ Light</button><button id="th-dark" onclick="setTheme('dark')">🌙 Dark</button></div></div>
      <div class="r"><div class="l"><b>Open assistant on launch</b><span>Show the AI panel when Kite starts</span></div><button class="sw" id="tg-assistantOpen" onclick="tog('assistantOpen')"><i></i></button></div>
    </div>
  </div>

  <div class="panel" id="p-assistant">
    <div class="group">
      <div class="r"><div class="l"><b>Anthropic API key</b><span>Powers the assistant. Create one at console.anthropic.com</span></div>
        <input type="password" id="key" placeholder="sk-ant-…" oninput="S.settings.apiKey=this.value.trim();commit()"></div>
      <div class="r"><div class="l"><b>Model</b><span>Haiku is fastest, Opus is the most capable</span></div>
        <select id="model" onchange="S.settings.model=this.value;commit()"><option value="claude-haiku-5-5">Claude Haiku 5.5 · fast</option><option value="claude-sonnet-5-5">Claude Sonnet 5.5 · balanced</option><option value="claude-opus-5-5">Claude Opus 5.5 · most capable</option></select></div>
      <div class="r"><div class="l"><b>Read the page by default</b><span>Send the current page's text to the assistant as context</span></div><button class="sw" id="tg-pageContext" onclick="tog('pageContext')"><i></i></button></div>
      <div class="r"><div class="l"><b>Reply language</b><span>Leave empty to answer in the language you write in</span></div><input type="text" id="lang" placeholder="e.g. Hindi, Tamil, English" oninput="S.settings.language=this.value;commit()"></div>
    </div>
    <div style="display:flex;gap:10px;align-items:center">
      <button class="btn pri" onclick="testKey()">Test connection</button><span id="tres" style="font-size:12.5px;color:var(--mut)"></span>
      <button class="btn" style="margin-left:auto" onclick="post({action:'clearChats'})">Clear all chats</button>
    </div>
    <p class="note" style="margin-top:14px">Your key is stored in this app's local preferences (not the Keychain) and is only sent to api.anthropic.com. Page text is sent only when "Page context" is on.</p>
  </div>

  <div class="panel" id="p-modes"><div class="mwrap"><div id="mlist"></div><div id="med"></div></div></div>
  </div>
</main>
<script>
const $=id=>document.getElementById(id);
const esc=s=>String(s==null?'':s).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const post=m=>window.webkit.messageHandlers.kiteSettings.postMessage(m);
let S,D,tab='general',sel=null,tmr=null,delArm=false;
const SW=['#7c3aed','#2563eb','#0891b2','#059669','#65a30d','#d97706','#e11d48','#db2777','#475569'];
const EMO=['🛍️','💼','🌿','🎓','🧪','✈️','🍳','💡','🎮','📈','🏠','🎨','📚','🏋️','🎧','🔒'];
function hexRgb(h){h=h.replace('#','');return [0,2,4].map(i=>parseInt(h.substr(i,2),16))}
function setAccent(c){const [r,g,b]=hexRgb(c),st=document.documentElement.style;
  st.setProperty('--ac',c);st.setProperty('--acs','rgba('+r+','+g+','+b+',.12)');st.setProperty('--acb','rgba('+r+','+g+','+b+',.30)')}
function cur(){return S.modes.find(m=>m.id===sel)||S.modes[0]}
function commit(){$('saved').textContent='Saving…';clearTimeout(tmr);tmr=setTimeout(()=>{post({action:'save',state:S});$('saved').textContent='Saved ✓'},250)}
function initSettings(state,defaults,t){S=state;D=defaults;sel=S.activeMode;delArm=false;applyTheme();showTab(t||'general')}
function applyTheme(){document.documentElement.dataset.theme=S.settings.theme;setAccent(cur().color)}
function showTab(t){tab=t;
  ['general','assistant','modes'].forEach(x=>{$('p-'+x).style.display=x===t?'block':'none';$('n-'+x).classList.toggle('on',x===t)});
  $('ttl').textContent={general:'General',assistant:'Assistant',modes:'Modes'}[t];$('saved').textContent='';
  if(t==='general'){$('home').value=S.settings.home||'';$('search').value=S.settings.search;tgSet('assistantOpen');themeBtns()}
  if(t==='assistant'){$('key').value=S.settings.apiKey||'';$('model').value=S.settings.model;tgSet('pageContext');$('lang').value=S.settings.language||'';$('tres').textContent=''}
  if(t==='modes')renderModes();
}
function tgSet(k){$('tg-'+k).classList.toggle('on',!!S.settings[k])}
function tog(k){S.settings[k]=!S.settings[k];tgSet(k);commit()}
function themeBtns(){$('th-light').classList.toggle('on',S.settings.theme!=='dark');$('th-dark').classList.toggle('on',S.settings.theme==='dark')}
function setTheme(t){S.settings.theme=t;applyTheme();themeBtns();commit()}
function closeS(){clearTimeout(tmr);if(S)post({action:'save',state:S});post({action:'close'})}
function testKey(){$('tres').textContent='Testing…';post({action:'save',state:S});post({action:'test'})}
function testResult(r){const e=$('tres');e.textContent=r.msg;e.style.color=r.ok?'#16a34a':'#e5484d'}

function renderModes(){
  $('mlist').innerHTML=S.modes.map(m=>'<button class="mi '+(m.id===sel?'on':'')+'" onclick="selMode(\''+m.id+'\')"><span class="e">'+esc(m.emoji)+'</span><span class="n">'+esc(m.name)+'</span>'+(m.id===S.activeMode?'<i class="act">ACTIVE</i>':'')+'</button>').join('')
    +'<button class="add" onclick="newMode()">＋ Add new mode</button>';
  renderEditor();
}
function listOnly(){const keep=document.activeElement;$('mlist').innerHTML=S.modes.map(m=>'<button class="mi '+(m.id===sel?'on':'')+'" onclick="selMode(\''+m.id+'\')"><span class="e">'+esc(m.emoji)+'</span><span class="n">'+esc(m.name)+'</span>'+(m.id===S.activeMode?'<i class="act">ACTIVE</i>':'')+'</button>').join('')
    +'<button class="add" onclick="newMode()">＋ Add new mode</button>'}
function selMode(id){sel=id;delArm=false;setAccent(cur().color);renderModes()}
function newMode(){const id='m'+Date.now();
  S.modes.push({id:id,builtin:false,name:'New Mode',emoji:'✨',color:'#d97706',tone:'balanced',home:'',openOnSwitch:false,
    prompt:'You are a helpful assistant for this kind of browsing. Describe here how the assistant should behave, what to focus on and what to avoid.',
    chips:[{label:'Summarize',prompt:'Summarize this page in a few bullet points.'},{label:'Key Points',prompt:'List the key points I should remember from this page.'}]});
  sel=id;showTab('modes');commit();setTimeout(()=>{const n=$('f-name');if(n){n.focus();n.select()}},50)}
function renderEditor(){const m=cur();if(!m)return;setAccent(m.color);
  const sws=SW.map(c=>'<button class="sc '+(c.toLowerCase()===(m.color||'').toLowerCase()?'on':'')+'" style="background:'+c+'" onclick="setColor(\''+c+'\')"></button>').join('');
  const chips=(m.chips||[]).map((c,i)=>'<div class="cr"><input type="text" value="'+esc(c.label)+'" placeholder="Label" oninput="cur().chips['+i+'].label=this.value;commit()"><input type="text" value="'+esc(c.prompt)+'" placeholder="What should the assistant do?" oninput="cur().chips['+i+'].prompt=this.value;commit()"><button onclick="delChip('+i+')">✕</button></div>').join('');
  $('med').innerHTML=
   '<div class="f"><label>Icon &amp; name</label><div class="two"><input type="text" id="f-emo" value="'+esc(m.emoji)+'" style="text-align:center;font-size:20px" oninput="cur().emoji=this.value;listOnly();commit()"><input type="text" id="f-name" value="'+esc(m.name)+'" placeholder="Mode name" oninput="cur().name=this.value;listOnly();commit()"></div>'
   +'<div class="emo">'+EMO.map(e=>'<button onclick="setEmoji(this.textContent)">'+e+'</button>').join('')+'</div></div>'
   +'<div class="f"><label>Accent colour</label><div class="sws">'+sws+'<input type="color" value="'+esc(m.color)+'" oninput="cur().color=this.value;setAccent(this.value);commit()"></div></div>'
   +'<div class="f"><label>Assistant behaviour</label><textarea rows="5" oninput="cur().prompt=this.value;commit()" placeholder="Tell the assistant who it is in this mode">'+esc(m.prompt)+'</textarea></div>'
   +'<div class="f"><label>Reply style</label><select onchange="cur().tone=this.value;commit()"><option value="concise"'+(m.tone==='concise'?' selected':'')+'>Concise · short and to the point</option><option value="balanced"'+(m.tone==='balanced'?' selected':'')+'>Balanced</option><option value="detailed"'+(m.tone==='detailed'?' selected':'')+'>Detailed · thorough with reasoning</option></select></div>'
   +'<div class="f"><label>Quick actions (buttons above the chat box)</label>'+chips+((m.chips||[]).length<6?'<button class="btn" onclick="addChip()">＋ Add quick action</button>':'')+'</div>'
   +'<div class="f"><label>Start page (optional)</label><input type="text" value="'+esc(m.home)+'" placeholder="https://…" oninput="cur().home=this.value;commit()"><label class="chk"><input type="checkbox" '+(m.openOnSwitch?'checked':'')+' onchange="cur().openOnSwitch=this.checked;commit()"> Open this page when I switch to this mode</label></div>'
   +'<div class="btns"><button class="btn pri" onclick="useMode()">'+(m.id===S.activeMode?'✓ Active mode':'Use this mode')+'</button>'
   +(m.builtin?'<button class="btn" onclick="resetMode()">Reset to default</button>':'<button class="btn dng" onclick="delMode()">'+(delArm?'Click again to confirm':'Delete mode')+'</button>')+'</div>';
}
function setEmoji(e){cur().emoji=e;renderModes();commit()}
function setColor(c){cur().color=c;renderModes();commit()}
function addChip(){cur().chips.push({label:'New action',prompt:''});renderEditor();commit()}
function delChip(i){cur().chips.splice(i,1);renderEditor();commit()}
function useMode(){S.activeMode=sel;renderModes();commit()}
function resetMode(){const d=D.modes.find(x=>x.id===sel);if(!d)return;const i=S.modes.findIndex(x=>x.id===sel);S.modes[i]=JSON.parse(JSON.stringify(d));renderModes();commit()}
function delMode(){if(!delArm){delArm=true;renderEditor();return}
  S.modes=S.modes.filter(x=>x.id!==sel);if(S.activeMode===sel)S.activeMode=S.modes[0].id;sel=S.activeMode;delArm=false;renderModes();commit()}
document.addEventListener('keydown',e=>{if(e.key==='Escape')closeS()});
</script></body></html>)KITE";

// ───────────────────────────── helpers ─────────────────────────────
// ── Kite Home (start page) ──
static const char *kHomeHTML = R"KITE(<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>Home</title>
<style>
:root{color-scheme:light;--bg1:#f3f4f9;--bg2:#fbf1f8;--fg:#17171c;--mut:#7d7f8b;--card:rgba(255,255,255,.78);--line:rgba(0,0,0,.08);--in:#fff;
 --ac:#7c3aed;--acs:rgba(124,58,237,.12);--acb:rgba(124,58,237,.30)}
[data-theme=dark]{color-scheme:dark;--bg1:#13131a;--bg2:#1a1722;--fg:#ececf1;--mut:#9396a6;--card:rgba(255,255,255,.07);--line:rgba(255,255,255,.1);--in:#23232c}
*{box-sizing:border-box}
html,body{margin:0;min-height:100%}
body{min-height:100vh;color:var(--fg);font-family:-apple-system,BlinkMacSystemFont,'SF Pro Text','Inter',sans-serif;letter-spacing:-.01em;
  background:radial-gradient(900px 480px at 50% -8%,var(--acs),transparent 70%),linear-gradient(160deg,var(--bg1),var(--bg2));
  display:flex;flex-direction:column;align-items:center;padding:70px 24px 50px}
.time{font-size:13px;color:var(--mut)}
h1{margin:6px 0 26px;font-size:36px;font-weight:600;letter-spacing:-.03em}
form{width:100%;max-width:620px;height:52px;border-radius:26px;background:var(--card);border:1px solid var(--line);display:flex;align-items:center;
  padding:0 20px;gap:12px;box-shadow:0 6px 24px rgba(30,30,60,.08);transition:border-color .15s,box-shadow .15s}
form:focus-within{border-color:var(--acb);box-shadow:0 0 0 4px var(--acs)}
form svg{width:19px;height:19px;fill:none;stroke:var(--mut);stroke-width:2;stroke-linecap:round;stroke-linejoin:round;flex:none}
form input{flex:1;border:0;outline:0;background:transparent;font:inherit;font-size:16px;color:var(--fg)}
#mchip{margin-top:14px;font-size:12.5px;color:var(--ac);background:var(--acs);border:1px solid var(--acb);padding:4px 12px;border-radius:14px}
.grid{display:grid;grid-template-columns:repeat(auto-fill,112px);gap:18px;justify-content:center;width:100%;max-width:900px;margin-top:42px}
.tile{position:relative;display:flex;flex-direction:column;align-items:center;gap:10px;padding:16px 8px 12px;border-radius:18px;background:var(--card);
  border:1px solid var(--line);color:inherit;text-decoration:none;cursor:pointer;font:inherit;transition:transform .15s,box-shadow .15s,border-color .15s}
.tile:hover{transform:translateY(-3px);box-shadow:0 10px 26px rgba(30,30,60,.14);border-color:var(--acb)}
.ic{width:48px;height:48px;border-radius:14px;background:var(--acs);color:var(--ac);display:flex;align-items:center;justify-content:center;font-size:20px;font-weight:600;overflow:hidden}
.ic img{width:30px;height:30px;border-radius:6px}
.nm{font-size:12.5px;max-width:100%;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.act{position:absolute;top:6px;right:6px;display:none;gap:3px}
.tile:hover .act{display:flex}
.ab{width:20px;height:20px;border-radius:6px;background:var(--in);color:var(--mut);font-size:11px;display:flex;align-items:center;justify-content:center;box-shadow:0 1px 3px rgba(0,0,0,.2)}
.ab:hover{color:var(--ac)}
.add .ic{background:transparent;border:1.5px dashed var(--acb);font-size:26px;font-weight:300}
.ov{position:fixed;inset:0;background:rgba(0,0,0,.35);display:none;align-items:center;justify-content:center;z-index:9}
.ov.on{display:flex}
.md{width:360px;background:var(--in);border:1px solid var(--line);border-radius:18px;padding:22px;box-shadow:0 20px 60px rgba(0,0,0,.3)}
.md h3{margin:0 0 14px;font-size:17px}
.md label{display:block;font-size:11.5px;font-weight:600;color:var(--mut);text-transform:uppercase;letter-spacing:.04em;margin:12px 0 6px}
.md input{width:100%;font:inherit;font-size:14px;color:var(--fg);background:transparent;border:1px solid var(--line);border-radius:10px;padding:9px 11px;outline:0}
.md input:focus{border-color:var(--ac);box-shadow:0 0 0 3px var(--acs)}
.mb{display:flex;justify-content:flex-end;gap:8px;margin-top:20px}
.b{height:34px;padding:0 16px;border-radius:10px;border:1px solid var(--line);background:transparent;color:var(--fg);font:inherit;font-size:13.5px;cursor:pointer}
.b.p{background:var(--ac);border-color:var(--ac);color:#fff}
</style></head>
<body>
<div class="time" id="clock"></div>
<h1 id="hi">Hello</h1>
<form id="sf"><svg viewBox="0 0 24 24"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg><input id="q" placeholder="Search or enter a website" autocomplete="off" spellcheck="false"></form>
<div id="mchip"></div>
<div class="grid" id="grid"></div>
<div class="ov" id="ov"><div class="md"><h3 id="mt">Add website</h3>
  <label>Name</label><input id="mn" placeholder="e.g. YouTube">
  <label>Address</label><input id="mu" placeholder="youtube.com">
  <div class="mb"><button class="b" onclick="closeM()">Cancel</button><button class="b p" onclick="saveM()">Save</button></div></div></div>
<script>
const post=m=>window.webkit.messageHandlers.kiteHome.postMessage(m);
const $=id=>document.getElementById(id);
let sites=[],editing=-1;
function hexRgb(h){h=h.replace('#','');return [0,2,4].map(i=>parseInt(h.substr(i,2),16))}
function host(u){try{return new URL(u).hostname}catch(e){return ''}}
function norm(u){u=(u||'').trim();if(!u)return '';if(!/^https?:\/\//i.test(u))u='https://'+u;try{new URL(u);return u}catch(e){return ''}}
function save(){post({action:'saveSites',sites:sites})}
function initHome(d){
  sites=d.sites||[];
  document.documentElement.dataset.theme=d.theme==='dark'?'dark':'light';
  if(d.color){const c=hexRgb(d.color),st=document.documentElement.style;
    st.setProperty('--ac',d.color);st.setProperty('--acs','rgba('+c[0]+','+c[1]+','+c[2]+',.12)');st.setProperty('--acb','rgba('+c[0]+','+c[1]+','+c[2]+',.30)')}
  $('mchip').textContent=((d.emoji||'')+' '+(d.mode||'')+' mode').trim();
  render();
}
function render(){
  const g=$('grid');g.innerHTML='';
  sites.forEach((s,i)=>{
    const a=document.createElement('a');a.className='tile';a.href=s.url;a.title=s.url;
    const h=host(s.url);
    const ic=document.createElement('div');ic.className='ic';ic.textContent=(s.name||h||'?').charAt(0).toUpperCase();
    if(h){const img=new Image();img.onload=()=>{ic.textContent='';ic.appendChild(img)};
      img.src='https://www.google.com/s2/favicons?domain='+encodeURIComponent(h)+'&sz=64'}
    const nm=document.createElement('div');nm.className='nm';nm.textContent=s.name||h;
    const act=document.createElement('div');act.className='act';
    const ed=document.createElement('span');ed.className='ab';ed.textContent='✎';ed.title='Edit';
    ed.onclick=e=>{e.preventDefault();e.stopPropagation();openM(i)};
    const rm=document.createElement('span');rm.className='ab';rm.textContent='✕';rm.title='Remove';
    rm.onclick=e=>{e.preventDefault();e.stopPropagation();sites.splice(i,1);save();render()};
    act.append(ed,rm);a.append(ic,nm,act);g.appendChild(a);
  });
  if(sites.length<24){const b=document.createElement('button');b.className='tile add';
    b.innerHTML='<div class="ic">+</div><div class="nm">Add website</div>';b.onclick=()=>openM(-1);g.appendChild(b)}
}
function openM(i){editing=i;const s=i>=0?sites[i]:{name:'',url:''};
  $('mt').textContent=i>=0?'Edit website':'Add website';$('mn').value=s.name;$('mu').value=s.url;$('mu').style.borderColor='';
  $('ov').classList.add('on');setTimeout(()=>$(i>=0?'mn':'mu').focus(),30)}
function closeM(){$('ov').classList.remove('on')}
function saveM(){const u=norm($('mu').value);if(!u){$('mu').style.borderColor='#e5484d';return}
  const n=$('mn').value.trim()||host(u).replace(/^www\./,'');const it={name:n,url:u};
  if(editing>=0)sites[editing]=it;else sites.push(it);save();render();closeM()}
document.addEventListener('keydown',e=>{if(e.key==='Escape')closeM();if(e.key==='Enter'&&$('ov').classList.contains('on'))saveM()});
$('sf').addEventListener('submit',e=>{e.preventDefault();const v=$('q').value.trim();if(v)post({action:'search',q:v})});
function tick(){const n=new Date(),h=n.getHours();
  $('hi').textContent=h<5?'Good night':h<12?'Good morning':h<17?'Good afternoon':'Good evening';
  $('clock').textContent=n.toLocaleTimeString([],{hour:'2-digit',minute:'2-digit'})+' · '+n.toLocaleDateString([],{weekday:'long',month:'long',day:'numeric'})}
setInterval(tick,20000);tick();
window.addEventListener('pageshow',()=>post({action:'ready'}));
post({action:'ready'});
</script></body></html>)KITE";

// click on the dark area outside the settings card closes it
@interface KiteScrim : NSView
@property (nonatomic, weak) NSView *card;
@property (nonatomic, copy) void (^onOutside)(void);
@end
@implementation KiteScrim
- (BOOL)acceptsFirstMouse:(NSEvent *)e { return YES; }
- (void)mouseDown:(NSEvent *)e {
    NSPoint p = [self convertPoint:e.locationInWindow fromView:nil];
    if (!self.card || !NSPointInRect(p, self.card.frame)) { if (self.onOutside) self.onOutside(); }
}
@end

static NSString *JSONString(id obj) {
    if (!obj || ![NSJSONSerialization isValidJSONObject:obj]) return @"null";
    NSData *d = [NSJSONSerialization dataWithJSONObject:obj options:0 error:nil];
    return d ? [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding] : @"null";
}
static id JSONParse(NSString *s) {
    if (!s) return nil;
    NSData *d = [s dataUsingEncoding:NSUTF8StringEncoding];
    return [NSJSONSerialization JSONObjectWithData:d options:NSJSONReadingMutableContainers | NSJSONReadingMutableLeaves error:nil];
}
static NSColor *HexColor(NSString *hex) {
    NSString *h = [hex stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"# "]];
    unsigned v = 0x7c3aed;
    if (h.length == 6) [[NSScanner scannerWithString:h] scanHexInt:&v];
    return [NSColor colorWithSRGBRed:((v >> 16) & 255) / 255.0 green:((v >> 8) & 255) / 255.0 blue:(v & 255) / 255.0 alpha:1];
}
static NSColor *Mix(NSColor *a, NSColor *b, CGFloat t) {
    return [NSColor colorWithSRGBRed:a.redComponent * (1 - t) + b.redComponent * t
                               green:a.greenComponent * (1 - t) + b.greenComponent * t
                                blue:a.blueComponent * (1 - t) + b.blueComponent * t alpha:1];
}

// ───────────────────────────── NATIVE SHELL ─────────────────────────────
@interface KiteDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler>
{
    NSWindow *window;
    NSView *backdrop;
    WKWebView *chromeWebView;
    NSView *webCard, *webContainerView;
    NSView *aiCard, *aiInner;
    WKWebView *aiSidebarWebView;
    NSView *settingsScrim, *settingsCard, *settingsInner;
    WKWebView *settingsWebView;

    NSMutableArray<WKWebView *> *tabWebViews;
    NSMutableArray<NSString *> *tabTitles;
    NSMutableArray<NSString *> *tabUrls;
    NSInteger activeTabIndex;
    BOOL isAssistantOpen, isWide;

    NSMutableDictionary *state;
    NSMutableDictionary *defaultState;
}
@end

@implementation KiteDelegate

// ── state ──
- (NSDictionary *)modeIn:(NSDictionary *)s id:(NSString *)mid {
    for (NSDictionary *m in s[@"modes"]) if ([m[@"id"] isEqualToString:mid ?: @""]) return m;
    return nil;
}
- (NSDictionary *)activeMode { return [self modeIn:state id:state[@"activeMode"]] ?: [state[@"modes"] firstObject]; }

- (void)loadState {
    defaultState = JSONParse([NSString stringWithUTF8String:kDefaultState]);
    NSString *saved = [[NSUserDefaults standardUserDefaults] stringForKey:@"kite.state.v2"];
    NSMutableDictionary *s = JSONParse(saved);
    if (![s isKindOfClass:[NSMutableDictionary class]]) s = JSONParse([NSString stringWithUTF8String:kDefaultState]);
    NSMutableDictionary *st = s[@"settings"];
    if (![st isKindOfClass:[NSMutableDictionary class]]) { st = [NSMutableDictionary dictionary]; s[@"settings"] = st; }
    for (NSString *k in defaultState[@"settings"]) if (!st[k]) st[k] = defaultState[@"settings"][k];
    NSArray *ms = s[@"modes"];
    if (![ms isKindOfClass:[NSArray class]] || !ms.count) s[@"modes"] = JSONParse(JSONString(defaultState[@"modes"]));
    if (![self modeIn:s id:s[@"activeMode"]]) s[@"activeMode"] = s[@"modes"][0][@"id"];
    if (![s[@"sites"] isKindOfClass:[NSArray class]]) s[@"sites"] = JSONParse(JSONString(defaultState[@"sites"]));
    if ([s[@"v"] integerValue] < 3) {
        s[@"v"] = @3;
        if ([st[@"home"] isEqualToString:@"https://www.google.com"]) st[@"home"] = @"";
        st[@"assistantOpen"] = @NO;
    }
    state = s;
}
- (void)saveState {
    [[NSUserDefaults standardUserDefaults] setObject:JSONString(state) forKey:@"kite.state.v2"];
}
- (NSDictionary *)publicState {
    NSMutableDictionary *s = JSONParse(JSONString(state));
    NSMutableDictionary *st = s[@"settings"];
    st[@"hasKey"] = @([st[@"apiKey"] length] > 0);
    [st removeObjectForKey:@"apiKey"];
    s[@"panelOpen"] = @(isAssistantOpen);
    return s;
}
- (void)pushStateTo:(WKWebView *)wv {
    [wv evaluateJavaScript:[NSString stringWithFormat:@"if(window.applyState)applyState(%@);", JSONString([self publicState])] completionHandler:nil];
}
- (void)applyAll {
    [self applyTheme];
    [self pushHomeAll];
    [self pushStateTo:chromeWebView];
    [self pushStateTo:aiSidebarWebView];
}
- (void)pushPage {
    NSString *t = (activeTabIndex >= 0 && activeTabIndex < tabTitles.count) ? tabTitles[activeTabIndex] : @"";
    NSString *u = (activeTabIndex >= 0 && activeTabIndex < tabUrls.count) ? tabUrls[activeTabIndex] : @"";
    [aiSidebarWebView evaluateJavaScript:[NSString stringWithFormat:@"if(window.setPage)setPage(%@);", JSONString(@{@"t": t, @"u": u})] completionHandler:nil];
}
- (NSString *)homeURL {
    NSString *h = state[@"settings"][@"home"];
    return h.length ? h : @"kite://home";
}

// ── launch ──
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    tabWebViews = [[NSMutableArray alloc] init];
    tabTitles = [[NSMutableArray alloc] init];
    tabUrls = [[NSMutableArray alloc] init];
    activeTabIndex = -1;
    [self loadState];
    isAssistantOpen = [state[@"settings"][@"assistantOpen"] boolValue];
    isWide = NO;

    [self setupMenu];

    NSRect vis = [[NSScreen mainScreen] visibleFrame];
    CGFloat w = MIN(kWinW, vis.size.width - 40), h = MIN(kWinH, vis.size.height - 30);
    NSRect frame = NSMakeRect(vis.origin.x + 20, vis.origin.y + vis.size.height - h - 10, w, h);

    NSWindowStyleMask style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                              NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable |
                              NSWindowStyleMaskFullSizeContentView;
    window = [[NSWindow alloc] initWithContentRect:frame styleMask:style backing:NSBackingStoreBuffered defer:NO];
    [window setTitle:@"Kite Browser"];
    [window setTitleVisibility:NSWindowTitleHidden];
    [window setTitlebarAppearsTransparent:YES];
    [window setMinSize:NSMakeSize(900, 560)];
    [window setDelegate:self];

    NSView *contentView = [window contentView];

    // tinted gradient backdrop (the cards float on top of it)
    backdrop = [[NSView alloc] initWithFrame:contentView.bounds];
    [backdrop setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    CAGradientLayer *g = [CAGradientLayer layer];
    g.startPoint = CGPointMake(0, 1); g.endPoint = CGPointMake(1, 0);
    [backdrop setLayer:g]; [backdrop setWantsLayer:YES];
    [contentView addSubview:backdrop];

    // toolbar
    WKWebViewConfiguration *chromeConfig = [[WKWebViewConfiguration alloc] init];
    [chromeConfig.userContentController addScriptMessageHandler:self name:@"kiteHost"];
    chromeWebView = [[WKWebView alloc] initWithFrame:NSZeroRect configuration:chromeConfig];
    [chromeWebView setValue:@NO forKey:@"drawsBackground"];
    [chromeWebView setNavigationDelegate:self];
    [contentView addSubview:chromeWebView];

    // floating page card
    NSView *wi = nil;
    webCard = [self makeCard:&wi];
    webContainerView = wi;
    [contentView addSubview:webCard];

    // floating assistant card
    WKWebViewConfiguration *aiConfig = [[WKWebViewConfiguration alloc] init];
    [aiConfig.userContentController addScriptMessageHandler:self name:@"kiteAI"];
    aiSidebarWebView = [[WKWebView alloc] initWithFrame:NSZeroRect configuration:aiConfig];
    [aiSidebarWebView setNavigationDelegate:self];
    [aiSidebarWebView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    NSView *ai = nil;
    aiCard = [self makeCard:&ai];
    aiInner = ai;
    [aiInner addSubview:aiSidebarWebView];
    [contentView addSubview:aiCard];

    // settings overlay
    settingsScrim = [[KiteScrim alloc] initWithFrame:contentView.bounds];
    [settingsScrim setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [settingsScrim setWantsLayer:YES];
    [settingsScrim layer].backgroundColor = [[NSColor colorWithWhite:0 alpha:0.28] CGColor];
    [settingsScrim setHidden:YES];
    // (outside-click handled by KiteScrim)
    
    NSView *si = nil;
    settingsCard = [self makeCard:&si];
    settingsInner = si;
    WKWebViewConfiguration *sConfig = [[WKWebViewConfiguration alloc] init];
    [sConfig.userContentController addScriptMessageHandler:self name:@"kiteSettings"];
    settingsWebView = [[WKWebView alloc] initWithFrame:NSZeroRect configuration:sConfig];
    [settingsWebView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [settingsInner addSubview:settingsWebView];
    [settingsScrim addSubview:settingsCard];
    { KiteScrim *ks = (KiteScrim *)settingsScrim; ks.card = settingsCard; ks.onOutside = ^{ [self hideSettings]; }; }
    [contentView addSubview:settingsScrim];

    [self layoutViews];
    [self applyTheme];

    NSURL *base = [NSURL URLWithString:@"https://kite.local"];
    [chromeWebView loadHTMLString:[NSString stringWithUTF8String:kChromeHTML] baseURL:base];
    [aiSidebarWebView loadHTMLString:[NSString stringWithUTF8String:kSidebarHTML] baseURL:base];
    [settingsWebView loadHTMLString:[NSString stringWithUTF8String:kSettingsHTML] baseURL:base];

    [self addNewTab:[self homeURL]];

    [window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
    [self layoutViews];
}

- (NSView *)makeCard:(NSView **)innerOut {
    NSView *outer = [[NSView alloc] initWithFrame:NSZeroRect];
    [outer setWantsLayer:YES];
    outer.layer.masksToBounds = NO;
    outer.layer.shadowColor = [[NSColor blackColor] CGColor];
    outer.layer.shadowOpacity = 0.16;
    outer.layer.shadowRadius = 16;
    outer.layer.shadowOffset = CGSizeMake(0, -4);
    NSView *inner = [[NSView alloc] initWithFrame:NSZeroRect];
    [inner setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [inner setWantsLayer:YES];
    inner.layer.cornerRadius = 16;
    inner.layer.masksToBounds = YES;
    inner.layer.borderWidth = 1;
    inner.layer.borderColor = [[NSColor colorWithWhite:0.5 alpha:0.18] CGColor];
    [outer addSubview:inner];
    *innerOut = inner;
    return outer;
}
- (void)sizeCard:(NSView *)outer inner:(NSView *)inner frame:(NSRect)f {
    [outer setFrame:f];
    [inner setFrame:outer.bounds];
    CGPathRef p = CGPathCreateWithRoundedRect(outer.bounds, 16, 16, NULL);
    outer.layer.shadowPath = p;
    CGPathRelease(p);
}

- (void)applyTheme {
    BOOL dark = [state[@"settings"][@"theme"] isEqualToString:@"dark"];
    [window setAppearance:[NSAppearance appearanceNamed:dark ? NSAppearanceNameDarkAqua : NSAppearanceNameAqua]];
    NSColor *ac = HexColor([self activeMode][@"color"]);
    NSColor *b1 = dark ? [NSColor colorWithSRGBRed:.075 green:.075 blue:.10 alpha:1] : [NSColor colorWithSRGBRed:.953 green:.957 blue:.976 alpha:1];
    NSColor *b2 = dark ? [NSColor colorWithSRGBRed:.10 green:.09 blue:.13 alpha:1] : [NSColor colorWithSRGBRed:.985 green:.945 blue:.975 alpha:1];
    CAGradientLayer *g = (CAGradientLayer *)backdrop.layer;
    g.colors = @[(id)[Mix(b1, ac, dark ? .18 : .12) CGColor], (id)[Mix(b2, ac, dark ? .10 : .06) CGColor]];
    [window setBackgroundColor:b1];
    webContainerView.layer.backgroundColor = [[NSColor whiteColor] CGColor];
    NSColor *aiBg = dark ? [NSColor colorWithSRGBRed:.102 green:.102 blue:.129 alpha:1] : [NSColor whiteColor];
    aiInner.layer.backgroundColor = [aiBg CGColor];
    settingsInner.layer.backgroundColor = [aiBg CGColor];
}

- (void)setupMenu {
    NSMenu *main = [[NSMenu alloc] init];

    NSMenuItem *appItem = [[NSMenuItem alloc] init];
    [main addItem:appItem];
    NSMenu *appMenu = [[NSMenu alloc] init];
    NSMenuItem *st = [appMenu addItemWithTitle:@"Settings…" action:@selector(menuSettings:) keyEquivalent:@","];
    st.target = self;
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItemWithTitle:@"Quit Kite Browser" action:@selector(terminate:) keyEquivalent:@"q"];
    [appItem setSubmenu:appMenu];

    NSMenuItem *fileItem = [[NSMenuItem alloc] init];
    [main addItem:fileItem];
    NSMenu *file = [[NSMenu alloc] initWithTitle:@"File"];
    NSMenuItem *nt = [file addItemWithTitle:@"New Tab" action:@selector(menuNewTab:) keyEquivalent:@"t"];
    NSMenuItem *ct = [file addItemWithTitle:@"Close Tab" action:@selector(menuCloseTab:) keyEquivalent:@"w"];
    NSMenuItem *rl = [file addItemWithTitle:@"Reload" action:@selector(menuReload:) keyEquivalent:@"r"];
    NSMenuItem *as = [file addItemWithTitle:@"Toggle Assistant" action:@selector(menuAssistant:) keyEquivalent:@"e"];
    nt.target = self; ct.target = self; rl.target = self; as.target = self;
    [fileItem setSubmenu:file];

    NSMenuItem *editItem = [[NSMenuItem alloc] init];
    [main addItem:editItem];
    NSMenu *edit = [[NSMenu alloc] initWithTitle:@"Edit"];
    [edit addItemWithTitle:@"Cut" action:@selector(cut:) keyEquivalent:@"x"];
    [edit addItemWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@"c"];
    [edit addItemWithTitle:@"Paste" action:@selector(paste:) keyEquivalent:@"v"];
    [edit addItemWithTitle:@"Select All" action:@selector(selectAll:) keyEquivalent:@"a"];
    [editItem setSubmenu:edit];

    [NSApp setMainMenu:main];
}
- (void)menuNewTab:(id)s { [self addNewTab:[self homeURL]]; }
- (void)menuCloseTab:(id)s { [self closeTabAction:activeTabIndex]; }
- (void)menuReload:(id)s { if (activeTabIndex >= 0) [tabWebViews[activeTabIndex] reload]; }
- (void)menuSettings:(id)s { [self showSettings:@"general" newMode:NO]; }
- (void)menuAssistant:(id)s { isAssistantOpen = !isAssistantOpen; [self layoutViews]; [self pushStateTo:chromeWebView]; }

// ── layout ──
- (void)layoutViews {
    NSRect b = window.contentView.bounds;
    CGFloat W = b.size.width, H = b.size.height;
    CGFloat bodyH = H - kChromeH;
    CGFloat panelW = MIN(isWide ? kPanelWide : kPanelW, W * 0.6);
    CGFloat cardH = MAX(100, bodyH - kGap);

    [chromeWebView setFrame:NSMakeRect(0, bodyH, W, kChromeH)];

    CGFloat webW = W - 2 * kGap - (isAssistantOpen ? panelW + kGap : 0);
    [self sizeCard:webCard inner:webContainerView frame:NSMakeRect(kGap, kGap, MAX(100, webW), cardH)];

    [aiCard setHidden:!isAssistantOpen];
    [self sizeCard:aiCard inner:aiInner frame:NSMakeRect(W - kGap - panelW, kGap, panelW, cardH)];
    [aiSidebarWebView setFrame:aiInner.bounds];

    CGFloat sw = MIN(920, W - 60), sh = MIN(660, H - 80);
    [settingsScrim setFrame:b];
    [self sizeCard:settingsCard inner:settingsInner frame:NSMakeRect((W - sw) / 2, (H - sh) / 2, sw, sh)];
    [settingsWebView setFrame:settingsInner.bounds];

    [self positionTrafficLights];
}

- (void)positionTrafficLights {
    NSButton *close = [window standardWindowButton:NSWindowCloseButton];
    NSView *tb = close.superview;
    NSView *container = tb.superview;
    if (!tb || !container) return;
    CGFloat H = window.frame.size.height, W = window.frame.size.width;
    CGFloat barH = 46;
    [container setFrame:NSMakeRect(0, H - barH, W, barH)];
    [tb setFrame:NSMakeRect(0, 0, W, barH)];
    NSArray *types = @[@(NSWindowCloseButton), @(NSWindowMiniaturizeButton), @(NSWindowZoomButton)];
    CGFloat x = 14;
    for (NSNumber *t in types) {
        NSButton *btn = [window standardWindowButton:(NSWindowButton)[t integerValue]];
        NSRect f = btn.frame;
        f.origin.x = x;
        f.origin.y = barH - 23 - f.size.height / 2.0;
        [btn setFrame:f];
        x += 20;
    }
}

- (void)windowDidResize:(NSNotification *)n { [self layoutViews]; }
- (void)windowDidEnterFullScreen:(NSNotification *)n { [self layoutViews]; }
- (void)windowDidExitFullScreen:(NSNotification *)n { [self layoutViews]; }

// ── settings overlay ──
- (void)showSettings:(NSString *)tab newMode:(BOOL)nm {
    if (settingsWebView.isLoading) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [self showSettings:tab newMode:nm]; });
        return;
    }
    [self layoutViews];
    [settingsScrim setHidden:NO];
    NSString *js = [NSString stringWithFormat:@"initSettings(%@,%@,'%@');%@",
                    JSONString(state), JSONString(defaultState), tab.length ? tab : @"general", nm ? @"newMode();" : @""];
    [settingsWebView evaluateJavaScript:js completionHandler:nil];
    [window makeFirstResponder:settingsWebView];
}
- (void)hideSettings { [settingsScrim setHidden:YES]; [window makeFirstResponder:nil]; }
- (void)scrimClicked:(NSClickGestureRecognizer *)g {
    NSPoint p = [g locationInView:settingsScrim];
    if (!NSPointInRect(p, settingsCard.frame)) [self hideSettings];
}

// ── mode menu (native) ──
- (void)showModeMenuAt:(NSPoint)pt {
    NSMenu *menu = [[NSMenu alloc] init];
    NSString *active = state[@"activeMode"];
    for (NSDictionary *m in state[@"modes"]) {
        NSMenuItem *it = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@  %@", m[@"emoji"], m[@"name"]]
                                                    action:@selector(pickMode:) keyEquivalent:@""];
        it.target = self; it.representedObject = m[@"id"];
        it.state = [m[@"id"] isEqualToString:active] ? NSControlStateValueOn : NSControlStateValueOff;
        [menu addItem:it];
    }
    [menu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *add = [[NSMenuItem alloc] initWithTitle:@"＋  Add New Mode…" action:@selector(menuAddMode:) keyEquivalent:@""];
    add.target = self; [menu addItem:add];
    NSMenuItem *cus = [[NSMenuItem alloc] initWithTitle:@"Customize Modes…" action:@selector(menuCustomize:) keyEquivalent:@""];
    cus.target = self; [menu addItem:cus];
    CGFloat y = chromeWebView.isFlipped ? pt.y : chromeWebView.bounds.size.height - pt.y;
    [menu popUpMenuPositioningItem:nil atLocation:NSMakePoint(pt.x, y) inView:chromeWebView];
}
- (void)pickMode:(NSMenuItem *)it { [self setActiveModeId:it.representedObject]; }
- (void)menuAddMode:(id)s { [self showSettings:@"modes" newMode:YES]; }
- (void)menuCustomize:(id)s { [self showSettings:@"modes" newMode:NO]; }
- (void)setActiveModeId:(NSString *)mid {
    if (![self modeIn:state id:mid]) return;
    state[@"activeMode"] = mid;
    [self saveState];
    [self applyAll];
    NSDictionary *m = [self activeMode];
    if ([m[@"openOnSwitch"] boolValue] && [m[@"home"] length]) [self navigateToUrl:m[@"home"]];
}

// ── messages ──
- (void)userContentController:(WKUserContentController *)ucc didReceiveScriptMessage:(WKScriptMessage *)message {
    NSDictionary *body = [message.body isKindOfClass:[NSDictionary class]] ? message.body : @{};
    NSString *action = body[@"action"];

    if ([message.name isEqualToString:@"kiteSettings"]) { [self handleSettings:action body:body]; return; }
    if ([message.name isEqualToString:@"kiteAI"]) { [self handleAI:action body:body]; return; }
    if ([message.name isEqualToString:@"kiteHome"]) {
        if ([message.frameInfo.securityOrigin.host isEqualToString:@"kite.home"]) [self handleHome:action body:body from:message.webView];
        return;
    }

    if ([action isEqualToString:@"newTab"]) {
        [self addNewTab:[self homeURL]];
    } else if ([action isEqualToString:@"home"]) {
        [self navigateToUrl:[self homeURL]];
    } else if ([action isEqualToString:@"switchTab"]) {
        [self switchToTab:[body[@"index"] integerValue]];
    } else if ([action isEqualToString:@"closeTab"]) {
        [self closeTabAction:[body[@"index"] integerValue]];
    } else if ([action isEqualToString:@"navigate"]) {
        [self navigateToUrl:body[@"url"]];
    } else if ([action isEqualToString:@"back"]) {
        if (activeTabIndex >= 0 && [tabWebViews[activeTabIndex] canGoBack]) [tabWebViews[activeTabIndex] goBack];
    } else if ([action isEqualToString:@"forward"]) {
        if (activeTabIndex >= 0 && [tabWebViews[activeTabIndex] canGoForward]) [tabWebViews[activeTabIndex] goForward];
    } else if ([action isEqualToString:@"reload"]) {
        if (activeTabIndex >= 0) [tabWebViews[activeTabIndex] reload];
    } else if ([action isEqualToString:@"toggleAssistant"]) {
        isAssistantOpen = !isAssistantOpen;
        [self layoutViews];
        [self pushStateTo:chromeWebView];
    } else if ([action isEqualToString:@"openSettings"]) {
        [self showSettings:body[@"tab"] ?: @"general" newMode:NO];
    } else if ([action isEqualToString:@"modeMenu"]) {
        [self showModeMenuAt:NSMakePoint([body[@"x"] doubleValue], [body[@"y"] doubleValue])];
    } else if ([action isEqualToString:@"theme"]) {
        state[@"settings"][@"theme"] = body[@"value"] ?: @"light";
        [self saveState]; [self applyAll];
    } else if ([action isEqualToString:@"drag"]) {
        NSEvent *ev = [NSApp currentEvent];
        if (ev) [window performWindowDragWithEvent:ev];
    } else if ([action isEqualToString:@"zoom"]) {
        [window zoom:nil];
    }
}

- (void)loadURLString:(NSString *)u inWebView:(WKWebView *)wv {
    if (!u.length || [u isEqualToString:@"kite://home"]) {
        [wv loadHTMLString:[NSString stringWithUTF8String:kHomeHTML] baseURL:[NSURL URLWithString:@"https://kite.home"]];
        return;
    }
    NSURL *url = [NSURL URLWithString:u] ?: [NSURL URLWithString:@"https://www.google.com"];
    [wv loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)pushHomeTo:(WKWebView *)wv {
    NSDictionary *m = [self activeMode];
    NSDictionary *d = @{@"sites": state[@"sites"] ?: @[],
                        @"mode": m[@"name"] ?: @"", @"emoji": m[@"emoji"] ?: @"",
                        @"color": m[@"color"] ?: @"#7c3aed",
                        @"theme": state[@"settings"][@"theme"] ?: @"light"};
    [wv evaluateJavaScript:[NSString stringWithFormat:@"if(window.initHome)initHome(%@);", JSONString(d)] completionHandler:nil];
}
- (void)pushHomeAll {
    for (WKWebView *t in tabWebViews) if ([t.URL.host isEqualToString:@"kite.home"]) [self pushHomeTo:t];
}

- (void)handleHome:(NSString *)action body:(NSDictionary *)body from:(WKWebView *)wv {
    if ([action isEqualToString:@"ready"]) {
        [self pushHomeTo:wv];
    } else if ([action isEqualToString:@"search"]) {
        NSString *q = body[@"q"];
        if ([q isKindOfClass:[NSString class]]) [self navigateToUrl:q];
    } else if ([action isEqualToString:@"saveSites"]) {
        id arr = JSONParse(JSONString(body[@"sites"]));
        if (![arr isKindOfClass:[NSArray class]]) return;
        NSMutableArray *clean = [NSMutableArray array];
        for (id it in arr) {
            if (![it isKindOfClass:[NSDictionary class]]) continue;
            NSString *u = it[@"url"], *n = it[@"name"];
            if (![u isKindOfClass:[NSString class]] || !([u hasPrefix:@"http://"] || [u hasPrefix:@"https://"])) continue;
            [clean addObject:[@{@"name": [n isKindOfClass:[NSString class]] ? n : @"", @"url": u} mutableCopy]];
        }
        state[@"sites"] = clean;
        [self saveState];
        for (WKWebView *t in tabWebViews) if (t != wv && [t.URL.host isEqualToString:@"kite.home"]) [self pushHomeTo:t];
    }
}

- (void)handleSettings:(NSString *)action body:(NSDictionary *)body {
    if ([action isEqualToString:@"close"]) {
        [self hideSettings];
    } else if ([action isEqualToString:@"save"]) {
        NSMutableDictionary *n = JSONParse(JSONString(body[@"state"]));
        if ([n isKindOfClass:[NSMutableDictionary class]] && n[@"modes"] && n[@"settings"] && [n[@"modes"] count]) {
            if (![self modeIn:n id:n[@"activeMode"]]) n[@"activeMode"] = n[@"modes"][0][@"id"];
            if (state[@"sites"]) n[@"sites"] = state[@"sites"];
            n[@"v"] = @3;
            state = n;
            [self saveState];
            [self applyAll];
        }
    } else if ([action isEqualToString:@"clearChats"]) {
        [aiSidebarWebView evaluateJavaScript:@"clearAll();" completionHandler:nil];
    } else if ([action isEqualToString:@"test"]) {
        if (![state[@"settings"][@"apiKey"] length]) {
            [settingsWebView evaluateJavaScript:@"testResult({ok:false,msg:'Enter an API key first'});" completionHandler:nil];
            return;
        }
        [self callClaude:@"Reply with the single word OK."
                messages:@[@{@"role": @"user", @"content": @"ping"}]
               maxTokens:16
              completion:^(NSString *text, NSString *err) {
            NSDictionary *d = @{@"ok": @(err == nil), @"msg": err ?: @"Connected ✓"};
            [self->settingsWebView evaluateJavaScript:[NSString stringWithFormat:@"testResult(%@);", JSONString(d)] completionHandler:nil];
        }];
    }
}

- (void)handleAI:(NSString *)action body:(NSDictionary *)body {
    if ([action isEqualToString:@"ask"]) {
        [self handleAsk:body];
    } else if ([action isEqualToString:@"expand"]) {
        isWide = !isWide; [self layoutViews];
    } else if ([action isEqualToString:@"settings"]) {
        [self showSettings:body[@"tab"] ?: @"general" newMode:NO];
    } else if ([action isEqualToString:@"attach"]) {
        [self pickAttachment];
    } else if ([action isEqualToString:@"dictate"]) {
        [window makeFirstResponder:aiSidebarWebView];
        [NSApp sendAction:NSSelectorFromString(@"startDictation:") to:nil from:nil];
    }
}

// ── AI ──
- (void)callClaude:(NSString *)system messages:(NSArray *)msgs maxTokens:(int)mt completion:(void (^)(NSString *, NSString *))done {
    NSDictionary *st = state[@"settings"];
    NSString *key = st[@"apiKey"];
    if (!key.length) { done(nil, @"NO_KEY"); return; }
    NSDictionary *payload = @{@"model": st[@"model"] ?: @"claude-sonnet-5-5", @"max_tokens": @(mt), @"system": system ?: @"", @"messages": msgs ?: @[]};
    if (![NSJSONSerialization isValidJSONObject:payload]) { done(nil, @"Invalid request"); return; }
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api.anthropic.com/v1/messages"]];
    req.HTTPMethod = @"POST";
    req.timeoutInterval = 90;
    [req setValue:key forHTTPHeaderField:@"x-api-key"];
    [req setValue:@"2023-06-01" forHTTPHeaderField:@"anthropic-version"];
    [req setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    req.HTTPBody = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
    [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *d, NSURLResponse *r, NSError *e) {
        NSString *text = nil, *err = nil;
        if (e) {
            err = e.localizedDescription;
        } else {
            id j = d ? [NSJSONSerialization JSONObjectWithData:d options:0 error:nil] : nil;
            if ([j isKindOfClass:[NSDictionary class]]) {
                NSDictionary *jd = j;
                if ([jd[@"error"] isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *ed = jd[@"error"];
                    err = ed[@"message"] ?: @"Request failed";
                } else {
                    NSMutableString *o = [NSMutableString string];
                    for (NSDictionary *blk in jd[@"content"]) {
                        if ([blk[@"type"] isEqualToString:@"text"]) [o appendString:blk[@"text"] ?: @""];
                    }
                    text = o;
                }
            } else err = @"Unexpected response from the API";
        }
        dispatch_async(dispatch_get_main_queue(), ^{ done(text, err); });
    }] resume];
}

- (void)reply:(NSString *)rid text:(NSString *)t error:(NSString *)e {
    NSDictionary *d = @{@"id": rid ?: @"", @"text": t ?: @"", @"error": e ?: @""};
    [aiSidebarWebView evaluateJavaScript:[NSString stringWithFormat:@"receiveReply(%@);", JSONString(d)] completionHandler:nil];
}

- (void)handleAsk:(NSDictionary *)body {
    NSString *rid = body[@"id"];
    NSDictionary *mode = [self modeIn:state id:body[@"mode"]] ?: [self activeMode];
    NSDictionary *st = state[@"settings"];
    if (![st[@"apiKey"] length]) { [self reply:rid text:nil error:@"NO_KEY"]; return; }

    void (^go)(NSString *) = ^(NSString *pageCtx) {
        NSMutableString *sys = [NSMutableString stringWithString:mode[@"prompt"] ?: @"You are a helpful browsing assistant."];
        NSString *tone = mode[@"tone"];
        if ([tone isEqualToString:@"concise"]) [sys appendString:@"\n\nKeep answers brief: under about 120 words unless the user asks for more."];
        else if ([tone isEqualToString:@"detailed"]) [sys appendString:@"\n\nBe thorough: include reasoning and examples."];
        NSString *lang = st[@"language"];
        if (lang.length) [sys appendFormat:@"\n\nAlways reply in %@.", lang];
        [sys appendString:@"\n\nFormat: plain text with light markdown only. Use short paragraphs, '-' bullets, and **bold** for key terms. No tables, no headings, no emojis unless the user uses them."];
        if (pageCtx.length) [sys appendFormat:@"\n\nThe user is currently browsing the page below. Use it as context when relevant, and don't claim to see anything that isn't in it.\n%@", pageCtx];
        else [sys appendString:@"\n\nYou cannot see the user's current page right now. If they ask about it, tell them to turn on Page context."];
        [self callClaude:sys messages:body[@"messages"] maxTokens:1500 completion:^(NSString *text, NSString *err) {
            [self reply:rid text:text error:err];
        }];
    };

    BOOL wantPage = [body[@"usePage"] boolValue];
    if (wantPage && activeTabIndex >= 0 && activeTabIndex < tabWebViews.count) {
        NSString *js = @"JSON.stringify({t:document.title,u:location.href,s:String(getSelection()).slice(0,2000),x:((document.body&&document.body.innerText)||'').replace(/\\s+/g,' ').slice(0,9000)})";
        [tabWebViews[activeTabIndex] evaluateJavaScript:js completionHandler:^(id r, NSError *e) {
            NSString *ctx = nil;
            if ([r isKindOfClass:[NSString class]]) {
                NSDictionary *d = JSONParse(r);
                if ([d isKindOfClass:[NSDictionary class]]) {
                    NSMutableString *c = [NSMutableString stringWithFormat:@"Title: %@\nURL: %@\n", d[@"t"], d[@"u"]];
                    if ([d[@"s"] length]) [c appendFormat:@"Selected text: %@\n", d[@"s"]];
                    [c appendFormat:@"Page text (truncated): %@", d[@"x"]];
                    ctx = c;
                }
            }
            go(ctx);
        }];
    } else {
        go(nil);
    }
}

- (void)pickAttachment {
    NSOpenPanel *p = [NSOpenPanel openPanel];
    p.allowsMultipleSelection = NO;
    p.message = @"Choose a text-based file (txt, md, csv, code, …)";
    [p beginSheetModalForWindow:window completionHandler:^(NSModalResponse r) {
        if (r != NSModalResponseOK || !p.URL) return;
        NSError *err = nil;
        NSString *txt = [NSString stringWithContentsOfURL:p.URL encoding:NSUTF8StringEncoding error:&err];
        NSDictionary *d;
        if (!txt) d = @{@"error": @"I can only read text-based files right now (txt, md, csv, json, code…)."};
        else {
            if (txt.length > 20000) txt = [txt substringToIndex:20000];
            d = @{@"name": p.URL.lastPathComponent, @"text": txt};
        }
        [self->aiSidebarWebView evaluateJavaScript:[NSString stringWithFormat:@"addAttachment(%@);", JSONString(d)] completionHandler:nil];
    }];
}

// ── tabs ──
- (void)addNewTab:(NSString *)urlString {
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    [config.userContentController addScriptMessageHandler:self name:@"kiteHome"];
    WKWebView *webView = [[WKWebView alloc] initWithFrame:[webContainerView bounds] configuration:config];
    [webView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [webView setNavigationDelegate:self];
    [webView setUIDelegate:self];
    [webView setCustomUserAgent:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15 KiteBrowser/1.0"];
    // (loaded below)
    [self loadURLString:urlString inWebView:webView];

    [tabWebViews addObject:webView];
    [tabTitles addObject:@"New Tab"];
    [tabUrls addObject:urlString ?: @""];
    [self switchToTab:tabWebViews.count - 1];
}

- (void)switchToTab:(NSInteger)index {
    if (index < 0 || index >= tabWebViews.count) return;
    if (activeTabIndex >= 0 && activeTabIndex < tabWebViews.count) [tabWebViews[activeTabIndex] removeFromSuperview];
    activeTabIndex = index;
    WKWebView *wv = tabWebViews[index];
    [wv setFrame:[webContainerView bounds]];
    [webContainerView addSubview:wv];
    [self updateChromeState];
}

- (void)closeTabAction:(NSInteger)index {
    if (index < 0 || index >= tabWebViews.count) return;
    [tabWebViews[index] removeFromSuperview];
    [tabWebViews removeObjectAtIndex:index];
    [tabTitles removeObjectAtIndex:index];
    [tabUrls removeObjectAtIndex:index];
    activeTabIndex = -1;
    if (tabWebViews.count == 0) [self addNewTab:[self homeURL]];
    else [self switchToTab:(index > 0) ? index - 1 : 0];
}

- (void)navigateToUrl:(NSString *)input {
    if (activeTabIndex < 0 || activeTabIndex >= tabWebViews.count) return;
    NSString *s = [input stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (!s.length) return;
    if ([s isEqualToString:@"kite://home"]) { [self loadURLString:s inWebView:tabWebViews[activeTabIndex]]; return; }
    NSURL *url = nil;
    if ([s hasPrefix:@"http://"] || [s hasPrefix:@"https://"] || [s hasPrefix:@"file://"]) {
        url = [NSURL URLWithString:s];
    } else if ([s containsString:@" "] || (![s containsString:@"."] && ![s hasPrefix:@"localhost"])) {
        NSString *q = [s stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        NSString *eng = state[@"settings"][@"search"];
        NSString *tpl = @"https://www.google.com/search?q=";
        if ([eng isEqualToString:@"duckduckgo"]) tpl = @"https://duckduckgo.com/?q=";
        else if ([eng isEqualToString:@"bing"]) tpl = @"https://www.bing.com/search?q=";
        else if ([eng isEqualToString:@"brave"]) tpl = @"https://search.brave.com/search?q=";
        url = [NSURL URLWithString:[tpl stringByAppendingString:q]];
    } else {
        url = [NSURL URLWithString:[@"https://" stringByAppendingString:s]];
    }
    if (url) [tabWebViews[activeTabIndex] loadRequest:[NSURLRequest requestWithURL:url]];
}

// ── web view delegates ──
- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration
   forNavigationAction:(WKNavigationAction *)action windowFeatures:(WKWindowFeatures *)features {
    NSURL *u = action.request.URL;
    if (u) [self addNewTab:[u absoluteString]];
    return nil;
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    for (NSInteger i = 0; i < tabWebViews.count; i++) {
        if (tabWebViews[i] == webView) {
            tabUrls[i] = webView.URL ? [webView.URL absoluteString] : @"";
            [self updateChromeState];
            break;
        }
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if (webView == chromeWebView) { [self pushStateTo:chromeWebView]; [self updateChromeState]; return; }
    if (webView == aiSidebarWebView) { [self pushStateTo:aiSidebarWebView]; [self pushPage]; return; }
    for (NSInteger i = 0; i < tabWebViews.count; i++) {
        if (tabWebViews[i] == webView) {
            tabTitles[i] = webView.title.length ? webView.title : @"Web Page";
            tabUrls[i] = webView.URL ? [webView.URL absoluteString] : @"";
            [self updateChromeState];
            break;
        }
    }
}

- (void)updateChromeState {
    NSMutableArray *tabsArray = [NSMutableArray array];
    for (NSInteger i = 0; i < tabWebViews.count; i++) {
        [tabsArray addObject:@{ @"title": tabTitles[i], @"url": tabUrls[i] }];
    }
    NSString *currentUrl = (activeTabIndex >= 0 && activeTabIndex < tabUrls.count) ? tabUrls[activeTabIndex] : @"";
    if ([currentUrl containsString:@"://kite.home"]) currentUrl = @"";
    NSString *json = JSONString(@{ @"active": @(activeTabIndex), @"currentUrl": currentUrl, @"tabs": tabsArray });
    [chromeWebView evaluateJavaScript:[NSString stringWithFormat:@"if(window.updateState)updateState(%@);", json] completionHandler:nil];
    [self pushPage];
}

- (BOOL)windowShouldClose:(id)sender { [NSApp terminate:nil]; return YES; }
@end

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        [app setActivationPolicy:NSApplicationActivationPolicyRegular];
        KiteDelegate *delegate = [[KiteDelegate alloc] init];
        [app setDelegate:delegate];
        [app run];
    }
    return 0;
}
