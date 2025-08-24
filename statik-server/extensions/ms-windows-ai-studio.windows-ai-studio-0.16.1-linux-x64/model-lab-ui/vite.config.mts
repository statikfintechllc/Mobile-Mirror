/// <reference types="vitest" />
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import svgr from "vite-plugin-svgr";
import { viteStaticCopy } from "vite-plugin-static-copy";
import path from "path";


// https://vitejs.dev/config/
export default defineConfig(({ mode }) => {
  return {
    plugins: [
      react(),
      svgr({
        include: "**/*.svg?react",
      }),
      viteStaticCopy({
        targets: [
          {
            src: "node_modules/highlight.js/styles/github.css",
            dest: "assets/hljs/",
          },
          {
            src: "node_modules/highlight.js/styles/github-dark.css",
            dest: "assets/hljs/",
          },
        ],
      }),
    ],
    publicDir: "public",
    build: {
      outDir: "build",
      sourcemap: true,
      minify: mode === "production",
      assetsInlineLimit: 1000000,
      rollupOptions: {
        output: {
          entryFileNames: `assets/[name].js`,
          chunkFileNames: `assets/[name].js`,
          assetFileNames: `assets/[name].[ext]`,
        },
      },
    },
    test: {
      environment: "jsdom",
      globals: true,
      setupFiles: ["src/setupTests.ts"],
      typecheck: {
        enabled: true,
      },
    },
  };
});
