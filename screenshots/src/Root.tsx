import { Composition } from "remotion";
import { AppStoreScreenshot } from "./AppStoreScreenshot";
import { AppStoreScreenshotIPad } from "./AppStoreScreenshotIPad";
import { PromoVideo } from "./PromoVideo";
import { AppIconConcept } from "./AppIconConcept";
import { HushLogoTransparent } from "./HushLogoTransparent";

// iPhone 6.7" (iPhone 16 Pro Max) App Store screenshot dimensions
const SCREENSHOT_WIDTH = 1320;
const SCREENSHOT_HEIGHT = 2868;

// iPad Pro 13-inch (M4) App Store screenshot dimensions
const IPAD_SCREENSHOT_WIDTH = 2048;
const IPAD_SCREENSHOT_HEIGHT = 2732;

// App Preview dimensions for iPhone 6.7" — iPhone 15 Pro Max native (1290×2796).
// Note: screenshot canvas above uses iPhone 16 Pro Max (1320×2868).
const VIDEO_WIDTH = 1290;
const VIDEO_HEIGHT = 2796;
const VIDEO_FPS = 30;
const VIDEO_DURATION_FRAMES = 25 * VIDEO_FPS; // 25 seconds

export const screenshotData = [
  {
    id: "mix-sounds",
    headline: "Mix Sounds",
    subtitle: "Layer 9 ambient sounds together",
    screenshotFile: "01_main_grid_playing.png",
    accentColor: "#00BCD4",
  },
  {
    id: "sleep-timer",
    headline: "Sleep Timer",
    subtitle: "Gentle fade-out as you drift off",
    screenshotFile: "02_timer_modal.png",
    accentColor: "#7C4DFF",
  },
  {
    id: "rain-variants",
    headline: "Rain Variants",
    subtitle: "From soft drops to car roof drips",
    screenshotFile: "03_variant_picker_rain.png",
    accentColor: "#4FC3F7",
  },
];

export const RemotionRoot: React.FC = () => {
  return (
    <>
      {screenshotData.map((data) => (
        <Composition
          key={data.id}
          id={data.id}
          component={AppStoreScreenshot}
          durationInFrames={1}
          fps={1}
          width={SCREENSHOT_WIDTH}
          height={SCREENSHOT_HEIGHT}
          defaultProps={{
            headline: data.headline,
            subtitle: data.subtitle,
            screenshotFile: data.screenshotFile,
            accentColor: data.accentColor,
          }}
        />
      ))}
      {screenshotData.map((data) => (
        <Composition
          key={`ipad-${data.id}`}
          id={`ipad-${data.id}`}
          component={AppStoreScreenshotIPad}
          durationInFrames={1}
          fps={1}
          width={IPAD_SCREENSHOT_WIDTH}
          height={IPAD_SCREENSHOT_HEIGHT}
          defaultProps={{
            headline: data.headline,
            subtitle: data.subtitle,
            screenshotFile: data.screenshotFile,
            accentColor: data.accentColor,
          }}
        />
      ))}
      {/* App Icon Concepts — 1024×1024 */}
      {(["sound-wave", "shh-finger", "sleeping-cloud", "ripple", "wave-h"] as const).map((v) => (
        <Composition
          key={`icon-${v}`}
          id={`icon-${v}`}
          component={AppIconConcept}
          durationInFrames={1}
          fps={1}
          width={1024}
          height={1024}
          defaultProps={{ variant: v }}
        />
      ))}
      <Composition
        id="hush-logo-transparent"
        component={HushLogoTransparent}
        durationInFrames={1}
        fps={1}
        width={1200}
        height={1200}
      />
      <Composition
        id="promo-video"
        component={PromoVideo}
        durationInFrames={VIDEO_DURATION_FRAMES}
        fps={VIDEO_FPS}
        width={VIDEO_WIDTH}
        height={VIDEO_HEIGHT}
      />
    </>
  );
};
