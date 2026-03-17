import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import "@/assets/less/index.less"
import ElementPlus from 'element-plus'
import 'element-plus/dist/index.css'
import * as ElementPlusIconsVue from '@element-plus/icons-vue'
import {createPinia} from "pinia"
import 'katex/dist/katex.min.css'
const app = createApp(App)
const pinia = createPinia()
app.use(ElementPlus)
app.use(pinia)
app.use(router).mount('#app')
for(const [key, component] of Object.entries(ElementPlusIconsVue)){
    app.component(key, component)
}
