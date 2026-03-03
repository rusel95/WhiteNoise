import { bundle } from "@remotion/bundler";
import { renderStill, selectComposition } from "@remotion/renderer";
import path from "path";
import fs from "fs";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const outputDir = path.join(__dirname, "output");

// Import locales data inline (since we can't import .ts directly in .mjs)
const locales = {
  "en-US": {
    "mix-sounds": { headline: "Mix Sounds", subtitle: "Layer 9 ambient sounds together" },
    "sleep-timer": { headline: "Sleep Timer", subtitle: "Gentle fade-out as you drift off" },
    "rain-variants": { headline: "Rain Variants", subtitle: "From soft drops to car roof drips" },
  },
  "de-DE": {
    "mix-sounds": { headline: "Klänge mixen", subtitle: "9 Umgebungsklänge überlagern" },
    "sleep-timer": { headline: "Schlaf-Timer", subtitle: "Sanftes Ausklingen beim Einschlafen" },
    "rain-variants": { headline: "Regen-Varianten", subtitle: "Von sanftem Regen bis Autodach-Tropfen" },
  },
  "fr-FR": {
    "mix-sounds": { headline: "Mixer les sons", subtitle: "Superposez 9 sons d'ambiance" },
    "sleep-timer": { headline: "Minuterie sommeil", subtitle: "Fondu en douceur pour s'endormir" },
    "rain-variants": { headline: "Variantes pluie", subtitle: "De la pluie douce aux gouttes sur le toit" },
  },
  "es-ES": {
    "mix-sounds": { headline: "Mezcla Sonidos", subtitle: "Combina 9 sonidos ambientales" },
    "sleep-timer": { headline: "Temporizador", subtitle: "Desvanecimiento suave al dormir" },
    "rain-variants": { headline: "Variantes lluvia", subtitle: "De gotas suaves a lluvia en el coche" },
  },
  "ja": {
    "mix-sounds": { headline: "サウンドミックス", subtitle: "9種類の環境音を重ねて" },
    "sleep-timer": { headline: "スリープタイマー", subtitle: "ゆっくりフェードアウト" },
    "rain-variants": { headline: "雨のバリエーション", subtitle: "やさしい雨から車の屋根の雨音まで" },
  },
  "ko": {
    "mix-sounds": { headline: "사운드 믹스", subtitle: "9가지 환경음을 겹쳐보세요" },
    "sleep-timer": { headline: "수면 타이머", subtitle: "부드럽게 페이드아웃" },
    "rain-variants": { headline: "빗소리 변형", subtitle: "부드러운 빗방울부터 차 지붕 위 빗소리까지" },
  },
  "zh-Hans": {
    "mix-sounds": { headline: "混合声音", subtitle: "叠加9种环境声音" },
    "sleep-timer": { headline: "睡眠定时器", subtitle: "温柔淡出，安然入睡" },
    "rain-variants": { headline: "雨声变体", subtitle: "从细雨到车顶雨声" },
  },
  "ru": {
    "mix-sounds": { headline: "Микс Звуков", subtitle: "Наложите 9 звуков природы" },
    "sleep-timer": { headline: "Таймер Сна", subtitle: "Плавное затихание при засыпании" },
    "rain-variants": { headline: "Варианты Дождя", subtitle: "От мягких капель до дождя по крыше" },
  },
  "uk": {
    "mix-sounds": { headline: "Мікс Звуків", subtitle: "Накладіть 9 звуків природи" },
    "sleep-timer": { headline: "Таймер Сну", subtitle: "Плавне затихання при засинанні" },
    "rain-variants": { headline: "Варіанти Дощу", subtitle: "Від легких крапель до дощу по даху" },
  },
  "pt-BR": {
    "mix-sounds": { headline: "Misturar Sons", subtitle: "Combine 9 sons ambientes" },
    "sleep-timer": { headline: "Timer de Sono", subtitle: "Desvanecimento suave ao adormecer" },
    "rain-variants": { headline: "Variantes Chuva", subtitle: "De gotas suaves a chuva no teto" },
  },
  "it": {
    "mix-sounds": { headline: "Mixa i Suoni", subtitle: "Sovrapponi 9 suoni ambientali" },
    "sleep-timer": { headline: "Timer Sonno", subtitle: "Dissolvenza delicata per addormentarsi" },
    "rain-variants": { headline: "Varianti Pioggia", subtitle: "Da gocce lievi a pioggia sul tetto" },
  },
  "tr": {
    "mix-sounds": { headline: "Sesleri Karıştır", subtitle: "9 ortam sesini üst üste ekle" },
    "sleep-timer": { headline: "Uyku Zamanlayıcı", subtitle: "Uykuya dalarken yumuşak geçiş" },
    "rain-variants": { headline: "Yağmur Çeşitleri", subtitle: "Hafif damlalardan araç çatısına" },
  },
  "nl-NL": {
    "mix-sounds": { headline: "Mix Geluiden", subtitle: "Combineer 9 omgevingsgeluiden" },
    "sleep-timer": { headline: "Slaaptimer", subtitle: "Zacht uitfaden bij het inslapen" },
    "rain-variants": { headline: "Regenvarianten", subtitle: "Van zachte druppels tot autodak-regen" },
  },
  "pl": {
    "mix-sounds": { headline: "Miksuj Dźwięki", subtitle: "Nakładaj 9 dźwięków otoczenia" },
    "sleep-timer": { headline: "Timer Snu", subtitle: "Łagodne wyciszanie do snu" },
    "rain-variants": { headline: "Warianty Deszczu", subtitle: "Od delikatnych kropel po deszcz na dachu" },
  },
  "sv": {
    "mix-sounds": { headline: "Mixa Ljud", subtitle: "Blanda 9 omgivande ljud" },
    "sleep-timer": { headline: "Sömntimer", subtitle: "Mjuk uttoning när du somnar" },
    "rain-variants": { headline: "Regnvarianter", subtitle: "Från mjuka droppar till regn på biltak" },
  },
  "zh-Hant": {
    "mix-sounds": { headline: "混合聲音", subtitle: "疊加9種環境聲音" },
    "sleep-timer": { headline: "睡眠計時器", subtitle: "溫柔淡出，安然入睡" },
    "rain-variants": { headline: "雨聲變化", subtitle: "從細雨到車頂雨聲" },
  },
  "ar": {
    "mix-sounds": { headline: "امزج الأصوات", subtitle: "اجمع 9 أصوات محيطة معًا" },
    "sleep-timer": { headline: "مؤقت النوم", subtitle: "تلاشٍ لطيف عند الخلود للنوم" },
    "rain-variants": { headline: "أنواع المطر", subtitle: "من قطرات ناعمة إلى مطر على السقف" },
  },
  "th": {
    "mix-sounds": { headline: "ผสมเสียง", subtitle: "ซ้อนเสียงธรรมชาติ 9 แบบ" },
    "sleep-timer": { headline: "ตั้งเวลานอน", subtitle: "ค่อยๆ เบาลงขณะหลับ" },
    "rain-variants": { headline: "แบบเสียงฝน", subtitle: "จากฝนพรำถึงฝนบนหลังคารถ" },
  },
  "vi": {
    "mix-sounds": { headline: "Trộn Âm Thanh", subtitle: "Kết hợp 9 âm thanh môi trường" },
    "sleep-timer": { headline: "Hẹn Giờ Ngủ", subtitle: "Giảm dần khi chìm vào giấc ngủ" },
    "rain-variants": { headline: "Biến Thể Mưa", subtitle: "Từ mưa nhẹ đến mưa trên nóc xe" },
  },
  "da": {
    "mix-sounds": { headline: "Mix Lyde", subtitle: "Kombiner 9 omgivelseslyde" },
    "sleep-timer": { headline: "Søvntimer", subtitle: "Blid udtonung når du falder i søvn" },
    "rain-variants": { headline: "Regnvarianter", subtitle: "Fra bløde dråber til regn på biltag" },
  },
  "nb": {
    "mix-sounds": { headline: "Miks Lyder", subtitle: "Legg 9 bakgrunnslyder oppå hverandre" },
    "sleep-timer": { headline: "Søvntimer", subtitle: "Myk uttoning når du sovner" },
    "rain-variants": { headline: "Regnvarianter", subtitle: "Fra myke dråper til regn på biltak" },
  },
  "fi": {
    "mix-sounds": { headline: "Yhdistä Ääniä", subtitle: "Yhdistä 9 tunnelmaääntä" },
    "sleep-timer": { headline: "Uniajastin", subtitle: "Pehmeä häivytys nukahtaessa" },
    "rain-variants": { headline: "Sateen Muunnelmat", subtitle: "Hiljaisista pisaroista auton katon sateeseen" },
  },
  "hu": {
    "mix-sounds": { headline: "Hangok Keverése", subtitle: "Rétegezzen 9 háttérhangot" },
    "sleep-timer": { headline: "Elalvásidőzítő", subtitle: "Gyengéd elhalkulás elalváskor" },
    "rain-variants": { headline: "Eső Változatok", subtitle: "Lágy cseppektől az autó tetejéig" },
  },
  "ro": {
    "mix-sounds": { headline: "Mixează Sunete", subtitle: "Combină 9 sunete de ambient" },
    "sleep-timer": { headline: "Timer Somn", subtitle: "Estompare lină la adormire" },
    "rain-variants": { headline: "Variante Ploaie", subtitle: "De la picături delicate la ploaie pe acoperiș" },
  },
  "sk": {
    "mix-sounds": { headline: "Mixuj Zvuky", subtitle: "Vrstvite 9 okolitých zvukov" },
    "sleep-timer": { headline: "Časovač Spánku", subtitle: "Jemné stlmenie pri zaspávaní" },
    "rain-variants": { headline: "Varianty Dažďa", subtitle: "Od jemných kvapiek po dážď na streche" },
  },
  "ca": {
    "mix-sounds": { headline: "Barreja Sons", subtitle: "Superposa 9 sons ambientals" },
    "sleep-timer": { headline: "Temporitzador", subtitle: "Esvaïment suau en adormir-se" },
    "rain-variants": { headline: "Variants Pluja", subtitle: "De gotes suaus a pluja al sostre" },
  },
  "ms": {
    "mix-sounds": { headline: "Campur Bunyi", subtitle: "Gabungkan 9 bunyi persekitaran" },
    "sleep-timer": { headline: "Pemasa Tidur", subtitle: "Pudar lembut semasa tertidur" },
    "rain-variants": { headline: "Variasi Hujan", subtitle: "Dari titisan lembut ke hujan di bumbung" },
  },
  "hr": {
    "mix-sounds": { headline: "Miksaj Zvukove", subtitle: "Kombiniraj 9 ambijentalnih zvukova" },
    "sleep-timer": { headline: "Timer za Spavanje", subtitle: "Nježno stišavanje pri uspavljivanju" },
    "rain-variants": { headline: "Varijante Kiše", subtitle: "Od nježnih kapi do kiše na krovu" },
  },
  "el": {
    "mix-sounds": { headline: "Μίξη Ήχων", subtitle: "Συνδυάστε 9 ήχους περιβάλλοντος" },
    "sleep-timer": { headline: "Χρονόμετρο Ύπνου", subtitle: "Απαλό σβήσιμο κατά τον ύπνο" },
    "rain-variants": { headline: "Παραλλαγές Βροχής", subtitle: "Από απαλές σταγόνες σε βροχή στη στέγη" },
  },
  "cs": {
    "mix-sounds": { headline: "Mixuj Zvuky", subtitle: "Vrstvěte 9 zvuků prostředí" },
    "sleep-timer": { headline: "Časovač Spánku", subtitle: "Jemné ztlumení při usínání" },
    "rain-variants": { headline: "Varianty Deště", subtitle: "Od jemných kapek po déšť na střeše" },
  },
  "id": {
    "mix-sounds": { headline: "Campur Suara", subtitle: "Gabungkan 9 suara ambient" },
    "sleep-timer": { headline: "Timer Tidur", subtitle: "Perlahan memudar saat tertidur" },
    "rain-variants": { headline: "Variasi Hujan", subtitle: "Dari tetes lembut hingga hujan di atap" },
  },
  "he": {
    "mix-sounds": { headline: "מיקס צלילים", subtitle: "שכבו 9 צלילי אווירה יחד" },
    "sleep-timer": { headline: "טיימר שינה", subtitle: "דעיכה עדינה בזמן ההירדמות" },
    "rain-variants": { headline: "סוגי גשם", subtitle: "מטיפות עדינות לגשם על הגג" },
  },
};

const screenshots = ["mix-sounds", "sleep-timer", "rain-variants"];
const screenshotFiles = {
  "mix-sounds": "01_main_grid_playing.png",
  "sleep-timer": "02_timer_modal.png",
  "rain-variants": "03_variant_picker_rain.png",
};
const accentColors = {
  "mix-sounds": "#00BCD4",
  "sleep-timer": "#7C4DFF",
  "rain-variants": "#4FC3F7",
};

// Parse CLI args: --locale=en-US or --all
const args = process.argv.slice(2);
const localeArg = args.find((a) => a.startsWith("--locale="));
const renderAll = args.includes("--all");
const targetLocales = localeArg
  ? [localeArg.split("=")[1]]
  : renderAll
    ? Object.keys(locales)
    : ["en-US"];

async function main() {
  console.log("Bundling Remotion project...");
  const bundled = await bundle({
    entryPoint: path.join(__dirname, "src/index.ts"),
    publicDir: path.join(__dirname, "public"),
  });

  let totalRendered = 0;

  for (const locale of targetLocales) {
    const texts = locales[locale];
    if (!texts) {
      console.warn(`  ⚠ No translations for ${locale}, skipping`);
      continue;
    }

    const localeDir = path.join(outputDir, locale);
    fs.mkdirSync(localeDir, { recursive: true });

    for (const compId of screenshots) {
      const { headline, subtitle } = texts[compId];
      const composition = await selectComposition({
        serveUrl: bundled,
        id: compId,
        inputProps: {
          headline,
          subtitle,
          screenshotFile: screenshotFiles[compId], // placeholder for composition selection
          accentColor: accentColors[compId],
        },
      });

      const outputPath = path.join(localeDir, `${compId}.png`);
      // Use locale-specific screenshot if available, else fall back to default
      const localeScreenshot = `${locale}/${screenshotFiles[compId]}`;
      const defaultScreenshot = screenshotFiles[compId];
      const screenshotExists = fs.existsSync(
        path.join(__dirname, "public", "screenshots", locale, screenshotFiles[compId])
      );
      const screenshotFile = screenshotExists ? localeScreenshot : defaultScreenshot;

      await renderStill({
        composition,
        serveUrl: bundled,
        output: outputPath,
        imageFormat: "png",
        inputProps: {
          headline,
          subtitle,
          screenshotFile,
          accentColor: accentColors[compId],
        },
      });

      totalRendered++;
      console.log(`  ✓ [${locale}] ${compId}`);
    }
  }

  console.log(
    `\nRendered ${totalRendered} screenshots for ${targetLocales.length} locale(s)`
  );
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
