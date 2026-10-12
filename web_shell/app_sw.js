// 自前の Service Worker。Flutter 同梱の SW は「自分を unregister するだけ」の非推奨版に
// なったため、オフライン動作はこちらで担う。
//
// 方針は 2 本立て。
// - 先取り: install 時にアプリ一式を控える。一度開けば、その場でオフラインでも動く。
// - network-first: オンライン時は必ずネットワークの最新を返し、成功応答を控え直す。
//   ネットワークが死んでいるときだけ控えを返す。オンラインで古い/壊れた資産を掴む事故が起きない。

// 次の 2 行は pwa_postbuild.sh がビルドごとに書き換える(素の `flutter build web` では入口だけ控える)。
const VERSION = 'dev';
const PRECACHE = [];

const CACHE = 'app-' + VERSION;
const ENTRY = ['./', 'index.html', 'manifest.json'];
// Flutter の描画エンジンは既定フォント(Roboto)と、同梱フォントに無い字の代替フォントを
// ここから取る。オフラインでも字が欠けないよう、自オリジンと同じ扱いで控える。
const FONT_CDN = 'https://fonts.gstatic.com';
const handles = (url) => url.origin === self.location.origin || url.origin === FONT_CDN;

self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE);
    const urls = [...new Set([...ENTRY, ...PRECACHE.map(encodeURI)])];
    // 1 つでも欠けたら install ごと失敗させる(半端な控えで「オフライン可」を名乗らない。
    // 次の訪問でブラウザが再試行する)。no-cache = HTTP キャッシュを再検証して使う。
    await Promise.all(urls.map((u) => cache.add(new Request(u, { cache: 'no-cache' }))));
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)));
    await self.clients.claim();
  })());
});

// 描画エンジン(CanvasKit)は端末ごとに使う版が違い重いので、先取り一覧には入れない。
// 初回訪問では SW が握る前に読み終えたフォント CDN の分もある。
// ページが実際に読み込んだ資産の一覧を受け取り、控えに無いものを足す。
self.addEventListener('message', (event) => {
  const data = event.data;
  if (!data || data.type !== 'loaded' || !Array.isArray(data.urls)) return;
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE);
    await Promise.allSettled(data.urls.map(async (u) => {
      if (!handles(new URL(u, self.location.href))) return;
      if (await cache.match(u)) return;
      await cache.add(u);
    }));
  })());
});

async function fromCache(req) {
  const cached =
    (await caches.match(req)) || (await caches.match(req, { ignoreSearch: true }));
  if (!cached) return null;
  const range = req.headers.get('range');
  const m = range && /^bytes=(\d*)-(\d*)$/.exec(range);
  if (!m || (m[1] === '' && m[2] === '')) return cached;
  // 音声は Range で取りに来る。Safari は 200 を受け付けないので、控えから 206 を切り出す。
  const body = await cached.arrayBuffer();
  const size = body.byteLength;
  const start = m[1] === '' ? Math.max(size - Number(m[2]), 0) : Number(m[1]);
  const end = m[1] === '' || m[2] === '' ? size - 1 : Math.min(Number(m[2]), size - 1);
  if (start > end) {
    return new Response(null, { status: 416, headers: { 'Content-Range': `bytes */${size}` } });
  }
  return new Response(body.slice(start, end + 1), {
    status: 206,
    statusText: 'Partial Content',
    headers: {
      'Content-Type': cached.headers.get('Content-Type') || 'application/octet-stream',
      'Content-Range': `bytes ${start}-${end}/${size}`,
      'Content-Length': String(end - start + 1),
      'Accept-Ranges': 'bytes',
    },
  });
}

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  if (!handles(new URL(req.url))) return; // 自オリジンとフォント CDN のみ扱う(他は素通し)。

  event.respondWith((async () => {
    try {
      const res = await fetch(req);
      // 中身の見える正常応答だけ控える(opaque/エラー/部分応答は貯めない)。
      if (res && res.status === 200 && (res.type === 'basic' || res.type === 'cors')) {
        const cache = await caches.open(CACHE);
        cache.put(req, res.clone());
      }
      return res;
    } catch (err) {
      const cached = await fromCache(req);
      if (cached) return cached;
      // ナビゲーションはアプリの入口で受ける(SPA なのでこれで起動できる)。
      if (req.mode === 'navigate') {
        const shell = await caches.match('index.html');
        if (shell) return shell;
      }
      throw err;
    }
  })());
});
