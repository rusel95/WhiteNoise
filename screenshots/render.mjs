import { bundle } from "@remotion/bundler";
import { renderStill, selectComposition } from "@remotion/renderer";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const compositions = ["mix-sounds", "fading-timer", "sound-variants"];
const outputDir = path.join(__dirname, "output");

async function main() {
  console.log("Bundling Remotion project...");
  const bundled = await bundle({
    entryPoint: path.join(__dirname, "src/index.ts"),
    publicDir: path.join(__dirname, "public"),
  });

  for (const compId of compositions) {
    console.log(`Rendering ${compId}...`);
    const composition = await selectComposition({
      serveUrl: bundled,
      id: compId,
    });

    const outputPath = path.join(outputDir, `${compId}.png`);

    await renderStill({
      composition,
      serveUrl: bundled,
      output: outputPath,
      imageFormat: "png",
    });

    console.log(`  ✓ ${outputPath}`);
  }

  console.log("\nAll screenshots rendered!");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
