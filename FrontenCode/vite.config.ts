import { defineConfig } from "vite";
import vue from "@vitejs/plugin-vue";
import { fileURLToPath, URL } from "node:url";
// https://vite.dev/config/
export default defineConfig({
  plugins: [vue()],
  //这个resolve是别名
  resolve: {
    alias: {
      "@": fileURLToPath(new URL("./src", import.meta.url)),
    },
  },
  server: {
    proxy: {
      //约定:所有以/api开头的请求都转发到后端
      "/api": {
        // target:'http://localhost:8080',
        target: "http://127.0.0.1:8000",
        changeOrigin: true,
        //如果后端没有/api前缀,而前端像保留/api,则删掉rewrite
        rewrite: (path) => path.replace(/^\/api/, ""),
      },
      "/docs": {
        // target:'http://localhost:8080',
        target: "http://127.0.0.1:8000",
        changeOrigin: true,
      },
      "/query": {
        target: "http://127.0.0.1:8000",
        changeOrigin: true,
      },
      "/requirements": {
        target: "http://localhost:8000",
        changeOrigin: true,
      },
    },
  },
});
