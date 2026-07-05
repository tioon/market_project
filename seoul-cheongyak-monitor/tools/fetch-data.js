#!/usr/bin/env node
/*
 * 청약홈 오픈API → listings.json 생성 파이프라인
 * - 서울/경기/인천(수도권) APT 분양정보 + 주택형별 특공 세대수 + 모집공고문 PDF 링크
 * - 실행: SERVICE_KEY 환경변수 필요 (data.go.kr 오픈API 인증키, Encoding)
 *   SERVICE_KEY=xxxx node tools/fetch-data.js
 * - 결과: 저장소 루트에 listings.json 생성 (index.html이 fetch)
 * ※ 인증키는 코드에 넣지 말 것! (GitHub Actions Secret로 주입)
 */
const fs = require('fs');
const path = require('path');

const KEY = process.env.SERVICE_KEY;
if (!KEY) { console.error('SERVICE_KEY 환경변수가 없습니다.'); process.exit(1); }

const BASE = 'https://api.odcloud.kr/api/ApplyhomeInfoDetailSvc/v1';
const LH_URL = 'https://apply.lh.or.kr/lhapply/apply/wt/wrtanc/selectWrtancList.do?mi=1027';
const TARGET = ['서울', '경기', '인천'];
const sleep = (ms) => new Promise(r => setTimeout(r, ms));

function ymd(d){ return d.toISOString().slice(0,10); }
async function api(pathname, params){
  const u = new URL(BASE + pathname);
  u.searchParams.set('serviceKey', KEY);
  for (const [k,v] of Object.entries(params||{})) u.searchParams.set(k, v);
  const res = await fetch(u, { headers: { 'Accept':'application/json' } });
  if (!res.ok) throw new Error(pathname + ' HTTP ' + res.status);
  return res.json();
}

function htypeOf(d){
  if (d.HOUSE_DTL_SECD_NM === '민영') return '민영';
  if (String(d.HOUSE_SECD) === '10') return '신혼희망타운';
  if (String(d.RENT_SECD) === '1') return '공공임대';
  const nm = (d.HOUSE_NM || '') + (d.HMPG_ADRES || '');
  if (/이익공유형|나눔/.test(nm)) return '나눔형';
  return '공공일반';
}
function ym(s){ return s && s.length>=6 ? s.slice(0,4)+'-'+s.slice(4,6) : ''; }
function areaNum(ty){ const m=String(ty||'').match(/\d+(\.\d+)?/); return m? Math.round(parseFloat(m[0])) : null; }

async function detailPdf(hm, pb){
  // 청약홈 상세페이지에서 모집공고문 PDF(getAtchmnfl) 링크 추출 (민영)
  try{
    const url = `https://www.applyhome.co.kr/ai/aia/selectAPTLttotPblancDetail.do?houseManageNo=${hm}&pblancNo=${pb}`;
    const res = await fetch(url);
    const html = await res.text();
    const m = html.match(/https:\/\/static\.applyhome\.co\.kr\/ai\/aia\/getAtchmnfl\.do[^"'<>\\]+/);
    return m ? m[0].replace(/&amp;/g,'&') : null;
  }catch(e){ return null; }
}

async function build(){
  const from = new Date(); from.setDate(from.getDate()-45);
  const list = await api('/getAPTLttotPblancDetail', {
    page:1, perPage:100, 'cond[RCRIT_PBLANC_DE::GTE]': ymd(from)
  });
  const rows = (list.data||[]).filter(d => TARGET.includes(d.SUBSCRPT_AREA_CODE_NM));
  const out = [];
  for (const d of rows){
    await sleep(250);
    const hm = d.HOUSE_MANAGE_NO, pb = d.PBLANC_NO;
    // 주택형별 (특공 세대수·면적·분양가)
    let spp=null, units=null, area=null, maxEok=null;
    try{
      const mdl = await api('/getAPTLttotPblancMdl', { perPage:50, 'cond[HOUSE_MANAGE_NO::EQ]': hm });
      const md = mdl.data||[];
      if (md.length){
        const sum=(k)=>md.reduce((s,x)=>s+(+x[k]||0),0);
        spp = { nw:sum('NWWDS_HSHLDCO'), first:sum('LFE_FRST_HSHLDCO'), nb:sum('NWBB_HSHLDCO'), gen:sum('SUPLY_HSHLDCO'), total:sum('SPSPLY_HSHLDCO') };
        const areas = md.map(x=>areaNum(x.HOUSE_TY)).filter(n=>n!=null);
        if (areas.length){ const mn=Math.min(...areas), mx=Math.max(...areas); area = '전용 '+(mn===mx?mn:mn+'~'+mx)+'㎡'; }
        const prices = md.map(x=>+x.LTTOT_TOP_AMOUNT||0);
        if (prices.length) maxEok = Math.round(Math.max(...prices)/1000)/10;
        units = md.map(x=>[String(areaNum(x.HOUSE_TY)), (+x.SUPLY_HSHLDCO||0), (+x.SPSPLY_HSHLDCO||0)]);
      }
    }catch(e){ /* 주택형별 없음(임대 등) */ }

    const gubun = d.HOUSE_DTL_SECD_NM === '민영' ? '민영' : '국민';
    let docType, docUrl;
    if (gubun === '민영'){ const pdf = await detailPdf(hm, pb); docType='pdf'; docUrl = pdf || d.PBLANC_URL; }
    else { docType='lh'; docUrl = LH_URL; }

    out.push({
      region: d.SUBSCRPT_AREA_CODE_NM, gubun, htype: htypeOf(d),
      name: d.HOUSE_NM, builder: d.CNSTRCT_ENTRPS_NM || d.BSNS_MBY_NM || '', phone: d.MDHS_TELNO || '',
      notice: d.RCRIT_PBLANC_DE, start: d.RCEPT_BGNDE, end: d.RCEPT_ENDDE,
      spStart: d.SPSPLY_RCEPT_BGNDE || null, win: d.PRZWNER_PRESNATN_DE, tot: +d.TOT_SUPLY_HSHLDCO||0,
      moveIn: ym(d.MVN_PREARNGE_YM),
      regSpec: d.SPECLT_RDN_EARTH_AT === 'Y', regAdj: d.MDAT_TRGET_AREA_SECD === 'Y',
      priceCap: d.PARCPRC_ULS_AT === 'Y', bigLand: d.LRSCL_BLDLND_AT === 'Y', publicLaw: d.PUBLIC_HOUSE_SPCLW_APPLC_AT === 'Y',
      area, maxEok, url: d.PBLANC_URL, docType, docUrl, spp, units
    });
  }
  // 최신 공고일 순
  out.sort((a,b)=> (b.notice||'').localeCompare(a.notice||''));
  const payload = { date: ymd(new Date()), count: out.length, listings: out };
  const dest = path.join(__dirname, '..', 'listings.json');
  fs.writeFileSync(dest, JSON.stringify(payload, null, 1));
  console.log('listings.json 생성: 수도권 ' + out.length + '건');
}
build().catch(e => { console.error(e); process.exit(1); });
