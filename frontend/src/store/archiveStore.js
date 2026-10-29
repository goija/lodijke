import { reactive } from 'vue';

function makeHistoricalSvgPlate(code, title, subtitle, drawingType) {
  let inner = '';
  if (drawingType === 'ship') {
    inner = `<rect x="30" y="30" width="740" height="390" fill="#f9f7f2" stroke="#8b2229" stroke-width="3"/><path d="M 110,275 Q 260,340 650,310 L 690,220 L 635,215 Q 380,235 110,275 Z" fill="#8b2229" fill-opacity="0.18" stroke="#8b2229" stroke-width="3"/><line x1="310" y1="70" x2="310" y2="295" stroke="#18181b" stroke-width="5"/><ellipse cx="375" cy="285" rx="42" ry="58" fill="#8b2229" fill-opacity="0.3" stroke="#18181b" stroke-width="2.5"/>`;
  } else if (drawingType === 'rescue') {
    inner = `<rect x="30" y="30" width="740" height="390" fill="#eef6fa" stroke="#8b2229" stroke-width="3"/><path d="M 30,290 Q 200,260 400,290 T 770,280 L 770,420 L 30,420 Z" fill="#a8cfe0" stroke="#4d7c94" stroke-width="2"/><path d="M 160,265 L 390,265 L 365,305 L 185,305 Z" fill="#8b2229" stroke="#18181b" stroke-width="2.5"/>`;
  } else if (drawingType === 'house') {
    inner = `<rect x="30" y="30" width="740" height="390" fill="#f9f7f2" stroke="#8b2229" stroke-width="3"/><rect x="140" y="165" width="230" height="200" fill="#ffffff" stroke="#8b2229" stroke-width="3"/><polygon points="130,165 255,85 380,165" fill="#8b2229" fill-opacity="0.22" stroke="#8b2229" stroke-width="3"/><rect x="390" y="180" width="250" height="185" fill="#ffffff" stroke="#8b2229" stroke-width="3"/>`;
  } else {
    inner = `<rect x="30" y="30" width="740" height="390" fill="#f9f7f2" stroke="#8b2229" stroke-width="3"/><rect x="130" y="115" width="540" height="210" rx="10" fill="#8b2229" fill-opacity="0.14" stroke="#8b2229" stroke-width="3" stroke-dasharray="8,5"/>`;
  }
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 500" width="800" height="500"><rect width="800" height="500" fill="#ffffff"/>${inner}<rect x="30" y="420" width="740" height="50" fill="#8b2229"/><text x="50" y="451" fill="#ffffff" font-family="Inter, sans-serif" font-size="19" font-weight="bold">[${code}] ${title}</text><text x="55" y="70" fill="#8b2229" font-family="JetBrains Mono, monospace" font-size="15" font-weight="bold">${subtitle}</text></svg>`;
  return 'data:image/svg+xml;utf8,' + encodeURIComponent(svg);
}

export const DEFAULT_PHOTOS = [
  { id: 'pod-img-01', title: 'Hoogaars TH 2 "Eben Haëzer" bij Scheepswerf Van Duivendijk', category: 'Vloot TH 2 / TH 12 / TH 90', year: '1902', location: "Contr'Escarpe, Tholen", desc: 'Houten Thoolse hoogaars TH 2 Eben Haëzer, gebouwd in 1902 voor Benjamin Willem Schot en bevaren door zijn zoon Cornelis Jan Schot B.W.zn.', dimensions: '800 x 500 px', sizeText: 'POD-01', dataUrl: makeHistoricalSvgPlate('TH 2 - 1902', 'Hoogaars TH 2 Eben Haezer - Werf Van Duivendijk', 'VLOOT B.W. SCHOT THOLEN', 'ship') },
  { id: 'pod-img-02', title: 'Reddingsactie met roeiboot van de TH 12 bij Watersnood Oud-Vossemeer', category: 'Vloot TH 2 / TH 12 / TH 90', year: '12-13 maart 1906', location: 'Oud-Vossemeer', desc: 'Evacuatie van inwoners met de roeiboot van hoogaars TH 12 "Niets zonder Gods zegen" tijdens de stormvloed van maart 1906.', dimensions: '800 x 500 px', sizeText: 'POD-02', dataUrl: makeHistoricalSvgPlate('TH 12 - 1906', 'Reddingsactie Watersnood Oud-Vossemeer met TH 12', 'STORMVLOED 12-13 MAART 1906', 'rescue') },
  { id: 'pod-img-03', title: 'Woonhuis Kruittoren 23 & Familiepanden te Tholen', category: "Kruittoren 23 & Contr'Escarpe", year: 'ca. 1905', location: 'Kruittoren 23 (Wijk A 107), Tholen', desc: 'Woonhuis van Benjamin Willem Schot aan de Kruittoren 23 en de naastgelegen familiehuizen (waaronder Anna Schot).', dimensions: '800 x 500 px', sizeText: 'POD-03', dataUrl: makeHistoricalSvgPlate('KRUITTOREN 23', 'Woonhuis B.W. Schot & Familiepanden Tholen', 'WIJK A NR. 107 THOLEN', 'house') },
  { id: 'pod-img-04', title: "Oesterloods Schot & Kegge aan de Contr'Escarpe", category: "Kruittoren 23 & Contr'Escarpe", year: 'Juli 1913', location: "Contr'Escarpe, Tholen", desc: 'De oesterloods van Cornelis Jan Schot en Jacob Kegge waarvoor in juli 1913 vergroting werd aangevraagd.', dimensions: '800 x 500 px', sizeText: 'POD-04', dataUrl: makeHistoricalSvgPlate('LOODS 1913', "Oesterloods C.J. Schot & J. Kegge - Contr'Escarpe", 'VERZENDING ZEEUWSE OESTERS', 'house') },
  { id: 'pod-img-05', title: 'Perceel No. 369 op de Bol van Lodijke (12,5 ha)', category: 'Bol van Lodijke & Percelen', year: '1892 / 1915', location: 'Bol van Lodijke, Oosterschelde', desc: 'Ligging van oesterperceel No. 369 (12,5 ha) op de Bol van Lodijke in het Verdronken Land van Reimerswaal.', dimensions: '800 x 500 px', sizeText: 'POD-05', dataUrl: makeHistoricalSvgPlate('PERCEEL 369', 'Bol van Lodijke - 12,5 Hectare Oesterbank', 'CONCESSIE B.W. SCHOT', 'map') },
  { id: 'pod-img-06', title: 'Hofstede De Gortzak in Polder Schakerloo (Sectie I nr. 360)', category: 'Hofsteden & Schakerloo', year: '1768 / 1893 / 1915', location: 'Schakerloo Sectie I nr. 360', desc: 'Hofstede De Gortzak (122 gemeten), geveild door erven mr. T.A. Wagtho (1893) en verkocht door Jacob Moelker (1915).', dimensions: '800 x 500 px', sizeText: 'POD-06', dataUrl: makeHistoricalSvgPlate('DE GORTZAK', 'Hofstede De Gortzak - Schakerloo Sectie I 360', 'BOOGAART - WAGTHO - MOELKER', 'house') },
  { id: 'pod-img-07', title: 'Eikenhouten Polderklepduiker (Schaal 1:5)', category: 'Archeologie & Klepduiker', year: '18e / 19e eeuw', location: 'Scherpenisse Sectie E 1551', desc: 'Constructietekening van een eikenhouten uitwateringssluis met getijdeklep onder de zeedijk.', dimensions: '800 x 500 px', sizeText: 'POD-07', dataUrl: makeHistoricalSvgPlate('KLEPDUIKER 1:5', 'Eikenhouten Polderklepduiker met Getijdeklep', 'WATERSTAAT THOLEN & SCHERPENISSE', 'map') },
  { id: 'pod-img-08', title: 'Expansie naar Flauwers onder Zierikzee (1912)', category: 'Bol van Lodijke & Percelen', year: '1912', location: 'Flauwers onder Zierikzee', desc: 'Pachting van oester- en mosselgronden te Flauwers van mr. Fokker door Kees, Jacob en Willem Schot.', dimensions: '800 x 500 px', sizeText: 'POD-08', dataUrl: makeHistoricalSvgPlate('FLAUWERS 1912', 'Oester- en Mosselgronden Flauwers Zierikzee', 'ZIERIKZEESE TAK FAMILIE SCHOT', 'ship') }
];

export const store = reactive({
  activeTab: 'tabGenealogie',
  subTabs: {
    tabGenealogie: 'subGenBoom',
    tabFotos: 'subFotosOverzicht',
    tabDocumenten: 'docA',
    docASub: 'subProfiel',
    tabKaarten: 'subKaartZeekaart',
    tabPlattegronden: 'subPlatHoogaars',
    tabArcheologie: 'subArcRegister',
    tabGeologie: 'subGeoBoringen',
    tabKadaster: 'subKadRegister',
    tabWoo: 'subWooKeten',
    tabUitbreiding: 'subUitNieuwTab',
    tabRustCms: 'subRustEditor'
  },
  fontSizePx: 19,
  leftDrawerOpen: true,
  leftDrawerPinned: true,
  rightDrawerOpen: false,
  rightInspector: {
    badge: 'GRAMPS-ID: I0103',
    title: 'Benjamin Willem Schot (1840–1935)',
    body: 'Geboren 26 september 1840 te Tholen, overleden 17 november 1935 te Tholen (95 jr). Woonhuis: Kruittoren 23 (Wijk A 107). Oesterperceel No. 369 op de Bol van Lodijke (12,5 ha). Vloot: TH 2, TH 12 en TH 90.'
  },
  viewportMode: 'single',
  secondaryViewportTopic: 'fotos',
  globalSearchQuery: '',
  toastMessage: '',
  lightboxPhoto: null,
  photos: [...DEFAULT_PHOTOS],
  cmsRecords: [],
  avoredCollections: [],
  geoParcels: [],
  planimeterAudits: [],
  avoredStatus: 'Verbinden...',
  gitBranch: 'main',
  gitLastCommit: '-',
  gitRemote: 'https://github.com/goija/lodijke',
  gitLogs: [],
  customMainTabs: [],
  customDocs: [],

  showToast(msg) {
    this.toastMessage = msg;
    setTimeout(() => {
      if (this.toastMessage === msg) this.toastMessage = '';
    }, 4000);
  },

  setFontSize(px) {
    this.fontSizePx = px;
    document.documentElement.style.setProperty('--base-font-size', px + 'px');
  },

  switchTab(tabId, subTabId = null) {
    this.activeTab = tabId;
    if (subTabId && this.subTabs[tabId] !== undefined) {
      this.subTabs[tabId] = subTabId;
    }
  },

  openInSecondaryViewport(topic) {
    this.viewportMode = 'split';
    this.secondaryViewportTopic = topic;
    this.showToast(`Onderdeel '${topic}' geopend in Viewport 2.`);
  },

  loadLocalPhotos() {
    try {
      const saved = localStorage.getItem('tholen_schot_solid_pod_photos_v5');
      if (saved) {
        const parsed = JSON.parse(saved);
        if (Array.isArray(parsed) && parsed.length) this.photos = parsed;
      }
    } catch (e) {}
  },

  saveLocalPhotos() {
    try {
      localStorage.setItem('tholen_schot_solid_pod_photos_v5', JSON.stringify(this.photos));
    } catch (e) {}
  },

  async syncBackend(silent = false) {
    try {
      const [cmsRes, colRes, geoRes, planRes, gitRes] = await Promise.all([
        fetch('/api/cms'),
        fetch('/api/avored/collections'),
        fetch('/api/geojson/parcels'),
        fetch('/api/planimeter/audit'),
        fetch('/api/git/status')
      ]);
      if (cmsRes.ok) this.cmsRecords = await cmsRes.json();
      if (colRes.ok) this.avoredCollections = await colRes.json();
      if (geoRes.ok) this.geoParcels = await geoRes.json();
      if (planRes.ok) this.planimeterAudits = await planRes.json();
      if (gitRes.ok) {
        const gitData = await gitRes.json();
        this.gitBranch = gitData.branch || 'main';
        this.gitLastCommit = gitData.last_commit || '-';
        this.gitRemote = gitData.remote || 'https://github.com/goija/lodijke';
        this.gitLogs = gitData.logs || [];
      }
      this.avoredStatus = 'AvoRed + Planimeter + GraphQL Online';
      if (!silent) this.showToast('Gesynchroniseerd met Rust Shoelace-Planimeter, GraphQL & Git op 8082.');
    } catch (e) {
      this.avoredStatus = 'Solid POD Lokaal';
      if (!silent) this.showToast('Offline modus: Solid POD opslag actief.');
    }
  },

  async executeGraphQL(query, variables = {}) {
    const res = await fetch('/api/graphql', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ query, variables })
    });
    return await res.json();
  }
});
