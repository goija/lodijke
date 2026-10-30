import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';
import path from 'path';

export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    host: '127.0.0.1',
    port: 5173,
    strictPort: true,
    proxy: {
      '/api/graphql': {
        target: 'http://127.0.0.1:8082',
        changeOrigin: true,
        secure: false,
      },
      '/graphql': {
        target: 'http://127.0.0.1:8082',
        changeOrigin: true,
        secure: false,
      },
      '/api/pdok': {
        target: 'https://api.pdok.nl',
        changeOrigin: true,
        rewrite: (p) => p.replace(/^\/api\/pdok/, ''),
      }
    }
  }
});
