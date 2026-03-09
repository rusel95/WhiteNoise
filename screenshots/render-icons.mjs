import { bundle } from "@remotion/bundler";
import { renderStill, selectComposition } from "@remotion/renderer";
import path from "path";
import fs from "fs";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const outputDir = path.join(__dirname, "output", "icons");

if (!fs.existsSync(outputDir)) fs.mkdirSync(outputDir, { recursive: true });

const variants = ["sound-wave", "shh-finger", "sleeping-cloud", "ripple", "wave-h"];

console.log("Bundling...");
const bundleLocation = await bundle({
  entryPoint: path.resolve(__dirname, "src/index.ts"),
});

for (const v of variants) {
  const compositionId = `icon-${v}`;
  console.log(`Rendering ${compositionId}...`);
  
  const composition = await selectComposition({
    serveUrl: bundleLocation,
    id: compositionId,
  });

  await renderStill({
    composition,
    serveUrl: bundleLocation,
    output: path.join(outputDir, `${v}.png`),
    imageFormat: "png",
  });
  
  console.log(`✓ ${v}.png`);
}

console.log(`\nDone! Icons at: ${outputDir}`);
