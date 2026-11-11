// Ham dung chung cho seed.js va export.js: dang nhap Firebase Auth qua REST
// roi goi Firestore REST bang idToken (rules yeu cau phai dang nhap).
const fs = require('fs');
const path = require('path');

const PROJECT = 'khotaphoa-huyln23it102';
const API_KEY = 'AIzaSyAqYGZZLQFb9BcRMqYXTiYYZQWAN7bH8Qc'; // web apiKey trong lib/firebase_options.dart
const DOCS = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents`;
const tk = JSON.parse(fs.readFileSync(path.join(__dirname, 'taikhoan_test.json'), 'utf8'));

async function goiAuth(hanhDong, body) {
  const r = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:${hanhDong}?key=${API_KEY}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ ...body, returnSecureToken: true }),
  });
  return { ok: r.ok, data: await r.json() };
}

/** Dang nhap bang tai khoan test, neu chua co thi tao moi. Tra ve idToken. */
async function layToken({ taoNeuChuaCo = false } = {}) {
  let r = await goiAuth('signInWithPassword', { email: tk.email, password: tk.matKhau });
  if (!r.ok && taoNeuChuaCo) {
    console.log('Chua co tai khoan, tao moi:', tk.email);
    r = await goiAuth('signUp', { email: tk.email, password: tk.matKhau });
  }
  if (!r.ok) throw new Error('Dang nhap that bai: ' + JSON.stringify(r.data.error));
  console.log('Da dang nhap:', r.data.email);
  return r.data.idToken;
}

// Doi qua lai giua kieu Firestore REST va JSON thuong
function tuFirestore(v) {
  if ('stringValue' in v) return v.stringValue;
  if ('integerValue' in v) return Number(v.integerValue);
  if ('doubleValue' in v) return v.doubleValue;
  if ('booleanValue' in v) return v.booleanValue;
  if ('nullValue' in v) return null;
  return v;
}
function sangFirestore(x) {
  if (typeof x === 'string') return { stringValue: x };
  if (Number.isInteger(x)) return { integerValue: String(x) };
  return { doubleValue: x };
}

module.exports = { PROJECT, DOCS, tk, layToken, tuFirestore, sangFirestore };
