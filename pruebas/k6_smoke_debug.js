import http from 'k6/http';
import { check } from 'k6';

export const options = {
  vus: 1,
  iterations: 1,
};

export default function () {
  const res = http.get('http://127.0.0.1:3000/login');

  console.log('STATUS=' + res.status);
  console.log('URL=' + res.url);
  console.log('BODY=' + ((res.body || '').substring(0, 200)));

  check(res, {
    'respuesta 2xx o 3xx': function (r) {
      return r.status >= 200 && r.status < 400;
    },
  });
}