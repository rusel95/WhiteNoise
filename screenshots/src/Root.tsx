import { Composition } from "remotion";
import { AppStoreScreenshot } from "./AppStoreScreenshot";

// iPhone 6.7" (iPhone 16 Pro Max) App Store screenshot dimensions
const SCREENSHOT_WIDTH = 1320;
const SCREENSHOT_HEIGHT = 2868;

export const screenshotData = [
  {
    id: "mix-sounds",
    headline: "Mix Sounds",
    subtitle: "Layer multiple ambient sounds",
    screenshotFile: "01_main_grid.png",
    accentColor: "#00BCD4",
  },
  {
    id: "fading-timer",
    headline: "Fading Timer",
    subtitle: "Fall asleep with gentle fade-out",
    screenshotFile: "screenshot_2.png",
    accentColor: "#00BCD4",
  },
  {
    id: "sound-variants",
    headline: "Sound Variants",
    subtitle: "Choose from multiple variations",
    screenshotFile: "screenshot_3.png",
    accentColor: "#00BCD4",
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
    </>
  );
};
