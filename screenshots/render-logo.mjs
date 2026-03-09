import { bundle } from "@remotion/bundler";
import { renderStill, selectComposition } from "@remotion/renderer";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

console.log("Bundling...");
const bundleLocation = await bundle({
  entryPoint: path.resolve(__dirname, "src/index.ts"),
});

const composition = await selectComposition({
  serveUrl: bundleLocation,
  id: "hush-logo-transparent",
});

await renderStill({
  composition,
  serveUrl: bundleLocation,
  output: path.join(__dirname, "..", "WhiteNoise", "Assets.xcassets", "HushLogo.imageset", "hush-logo.png"),
  imageFormat: "png",
  transparent: true,
});

console.log("✓ Transparent logo rendered");
