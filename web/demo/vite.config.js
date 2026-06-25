import { defineConfig } from "vite";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.dirname(fileURLToPath(import.meta.url));
const generatedNodeModules = path.join(root, "dist", "node_modules");

export default defineConfig({
  resolve: {
    alias: {
      bonsai_android: path.join(generatedNodeModules, "bonsai_android"),
      bonsai_native: path.join(generatedNodeModules, "bonsai_native"),
      melange: path.join(generatedNodeModules, "melange"),
      "melange.js": path.join(generatedNodeModules, "melange.js"),
    },
  },
});
