import { createApp } from 'vue';
import Modernizr from './utils/modernizr.js';
import App from './App.vue';

const app = createApp(App);
app.config.globalProperties.$modernizr = Modernizr;
app.provide('modernizr', Modernizr);
app.mount('#app');
