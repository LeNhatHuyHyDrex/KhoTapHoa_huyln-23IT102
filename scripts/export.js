// Xuat toan bo collection "sanpham" tren Firestore ra file JSON de nop bai.
// Firebase (goi Spark) khong co nut export Firestore ra JSON, nen script nay
// doc tung document qua Firestore REST API roi ghi lai.
// Chay: node scripts/export.js   ->  database/sanpham.json
const fs = require('fs');
const path = require('path');
const { PROJECT, DOCS, layToken, tuFirestore } = require('./_firebase');

(async () => {
  const token = await layToken();
  let docs = [], pageToken = '';
  do {
    const url = `${DOCS}/sanpham?pageSize=300${pageToken ? '&pageToken=' + pageToken : ''}`;
    const j = await (await fetch(url, { headers: { Authorization: `Bearer ${token}` } })).json();
    if (j.error) throw new Error(JSON.stringify(j.error));
    docs = docs.concat(j.documents || []);
    pageToken = j.nextPageToken || '';
  } while (pageToken);

  const sanpham = {};
  for (const d of docs) {
    const f = d.fields || {};
    // giu dung thu tu 4 truong theo de bai
    sanpham[d.name.split('/').pop()] = {
      name: tuFirestore(f.name || { stringValue: '' }),
      price: tuFirestore(f.price || { integerValue: '0' }),
      soluong: tuFirestore(f.soluong || { integerValue: '0' }),
      image: tuFirestore(f.image || { stringValue: '' }),
    };
  }

  const dir = path.join(__dirname, '..', 'database');
  fs.mkdirSync(dir, { recursive: true });
  const out = path.join(dir, 'sanpham.json');
  fs.writeFileSync(out, JSON.stringify({ sanpham }, null, 2), 'utf8');
  const kb = (fs.statSync(out).size / 1024).toFixed(0);
  console.log(`Project: ${PROJECT}`);
  console.log(`Da xuat ${docs.length} san pham -> database/sanpham.json (${kb} KB)`);
  for (const [id, sp] of Object.entries(sanpham)) {
    console.log(`  ${id}  ${sp.name} | ${sp.price} | SL ${sp.soluong} | anh ${(sp.image.length / 1024).toFixed(0)}KB base64`);
  }
})().catch((e) => { console.error(e.message); process.exit(1); });
