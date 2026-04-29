// https://vitejs.dev/config/
export default {
  server: {
    host: '0.0.0.0',
    proxy: {
      '/api': {
        target: 'http://ecommerce-api:8000',
        changeOrigin: true,
      },
      '/api/auth': {
        target: 'http://auth-api:8001',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api\/auth/, '')
      },
      '/api/payment': {
        target: 'http://payment-api:8002',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api\/payment/, '')
      }
    }
  }
}
