// Nap san pham mau vao collection "sanpham".
// Chay: node scripts/seed.js
// Moi document chi co 4 truong: name, price, soluong, image (anh JPEG base64).
const fs = require('fs');
const path = require('path');
const { DOCS, layToken, sangFirestore } = require('./_firebase');

// [ten, gia, so luong, file anh trong scripts/anh_mau]
const HANG = [
  ['Mì xào khô Indomie (gói 80g)', 6000, 120, 'mi_indomie.jpg'],
  ['Cà phê Arabica Mr.Viet 250g', 85000, 14, 'caphe_mrviet.jpg'],
  ['Trứng gà (hộp 6 quả)', 22000, 4, 'trung_ga.jpg'],
  ['Gạo thơm túi 5kg', 120000, 9, 'gao.jpg'],
  ['Nước ngọt Sierra Mist lon 355ml', 12000, 0, 'nuoc_ngot.jpg'],
  ['Dầu đậu phộng chai 1L', 68000, 3, 'dau_phong.jpg'],
  ['Nước mắm Red Boat 40°N 500ml', 150000, 25, 'nuoc_mam.jpg'],
];

(async () => {
  const token = await layToken({ taoNeuChuaCo: true });
  const headers = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };

  const hienCo = await (await fetch(`${DOCS}/sanpham?pageSize=300`, { headers })).json();
  const daCo = new Set((hienCo.documents || []).map((d) => d.fields.name.stringValue));

  for (const [name, price, soluong, file] of HANG) {
    if (daCo.has(name)) { console.log('Bo qua (da co):', name); continue; }
    const image = fs.readFileSync(path.join(__dirname, 'anh_mau', file)).toString('base64');
    const sp = { name, price, soluong, image };
    const fields = Object.fromEntries(Object.entries(sp).map(([k, v]) => [k, sangFirestore(v)]));
    const r = await fetch(`${DOCS}/sanpham`, { method: 'POST', headers, body: JSON.stringify({ fields }) });
    const j = await r.json();
    console.log(r.ok ? `Da them ${j.name.split('/').pop()}:` : `LOI ${r.status}`, name, r.ok ? '' : JSON.stringify(j.error));
  }
})().catch((e) => { console.error(e.message); process.exit(1); });
