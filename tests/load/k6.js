import http from 'k6/http';
import { sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 20 },
    { duration: '1m30s', target: 10 },
    { duration: '20s', target: 0 },
  ],
};

export default function () {
  const routes = [
    { method: 'GET', url: 'http://ecommerce-api:8000/products' },
    { method: 'POST', url: 'http://ecommerce-api:8000/cart/add' },
    { method: 'POST', url: 'http://ecommerce-api:8000/checkout' },
  ];

  const route = routes[Math.floor(Math.random() * routes.length)];
  http.request(route.method, route.url);
  sleep(1);
}
