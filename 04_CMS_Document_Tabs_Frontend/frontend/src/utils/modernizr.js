/**
 * Lodijke Custom Modernizr v3.13 Feature Detection Suite
 * Detecteert Geolocation API, HTML5 History API, Drag & Drop, Touch, LocalStorage & WebGL
 * en injecteert automatisch CSS classes op <html> (bijv. "js geolocation history ...").
 */
const docElement = typeof document !== 'undefined' ? document.documentElement : null;
const hasWindow = typeof window !== 'undefined';
const hasNavigator = typeof navigator !== 'undefined';

const tests = {
  geolocation: () => Boolean(hasNavigator && 'geolocation' in navigator && typeof navigator.geolocation.getCurrentPosition === 'function'),
  securecontext: () => Boolean(hasWindow && (window.isSecureContext || ['localhost', '127.0.0.1', '::1'].includes(window.location.hostname))),
  history: () => Boolean(hasWindow && window.history && 'pushState' in window.history && 'replaceState' in window.history),
  draganddrop: () => {
    if (!docElement) return false;
    const div = document.createElement('div');
    return ('draggable' in div) || ('ondragstart' in div && 'ondrop' in div);
  },
  touchevents: () => Boolean(hasWindow && ('ontouchstart' in window || (hasNavigator && navigator.maxTouchPoints > 0))),
  localstorage: () => {
    try {
      const k = '__modernizr_ls__';
      window.localStorage.setItem(k, k);
      window.localStorage.removeItem(k);
      return true;
    } catch (_) {
      return false;
    }
  },
  svg: () => Boolean( typeof document !== 'undefined' && !!document.createElementNS && !!document.createElementNS('http://www.w3.org/2000/svg', 'svg').createSVGRect ),
  webgl: () => {
    if (typeof document === 'undefined') return false;
    try {
      const canvas = document.createElement('canvas');
      return Boolean(window.WebGLRenderingContext && (canvas.getContext('webgl') || canvas.getContext('experimental-webgl')));
    } catch (_) {
      return false;
    }
  }
};

const Modernizr = {
  _version: '3.13.0-lodijke',
  tests: {},
  addTest(name, fn) {
    const result = Boolean(typeof fn === 'function' ? fn() : fn);
    this[name] = result;
    this.tests[name] = result;
    if (docElement) {
      docElement.classList.remove(`no-${name}`, name);
      docElement.classList.add(result ? name : `no-${name}`);
    }
    return result;
  },
  runAll() {
    if (docElement) {
      docElement.classList.remove('no-js');
      docElement.classList.add('js');
    }
    Object.entries(tests).forEach(([key, testFn]) => {
      this.addTest(key, testFn);
    });
    return this;
  }
};

Modernizr.runAll();

if (hasWindow) {
  window.Modernizr = Modernizr;
}

/**
 * Officiële RDNAP / Schreuders benadering: WGS84 (lat, lon) -> Rijksdriehoek (RD X, RD Y)
 */
export function wgs84ToRd(lat, lon) {
  const phi0 = 52.15517440;
  const lam0 = 5.38720621;
  const dPhi = 0.36 * (lat - phi0);
  const dLam = 0.36 * (lon - lam0);

  const x = 155000
    + 190094.945 * dLam
    - 11832.228 * dPhi * dLam
    - 114.221 * Math.pow(dPhi, 2) * dLam
    - 32.391 * Math.pow(dLam, 3)
    - 0.705 * dPhi
    - 2.340 * Math.pow(dPhi, 3) * dLam
    - 0.608 * dPhi * Math.pow(dLam, 3);

  const y = 463000
    + 309056.544 * dPhi
    + 3638.893 * Math.pow(dLam, 2)
    + 73.077 * Math.pow(dPhi, 2)
    - 157.984 * dPhi * Math.pow(dLam, 2)
    + 59.788 * Math.pow(dPhi, 3)
    + 0.433 * dLam
    - 6.439 * Math.pow(dPhi, 2) * Math.pow(dLam, 2)
    - 0.032 * dPhi * dLam
    + 0.092 * Math.pow(dLam, 4)
    - 0.054 * dPhi * Math.pow(dLam, 4);

  return {
    rdX: Number(x.toFixed(2)),
    rdY: Number(y.toFixed(2))
  };
}

/**
 * Rijksdriehoek (RD X, RD Y) -> WGS84 (lat, lon)
 */
export function rdToWgs84(x, y) {
  const dX = (x - 155000) * 1e-5;
  const dY = (y - 463000) * 1e-5;

  const sumN =
    (3235.65389 * dY) +
    (-32.58297 * Math.pow(dX, 2)) +
    (-0.24750 * Math.pow(dY, 2)) +
    (-0.84978 * Math.pow(dX, 2) * dY) +
    (-0.06550 * Math.pow(dY, 3)) +
    (-0.01709 * Math.pow(dX, 2) * Math.pow(dY, 2)) +
    (-0.00738 * dX) +
    (0.00530 * Math.pow(dX, 4));

  const sumE =
    (5260.52916 * dX) +
    (105.94684 * dX * dY) +
    (2.45656 * dX * Math.pow(dY, 2)) +
    (-0.81885 * Math.pow(dX, 3)) +
    (0.05594 * dX * Math.pow(dY, 3)) +
    (-0.05607 * Math.pow(dX, 3) * dY);

  return {
    lat: Number((52.15517440 + (sumN / 3600)).toFixed(6)),
    lon: Number((5.38720621 + (sumE / 3600)).toFixed(6))
  };
}

export default Modernizr;
