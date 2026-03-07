import React from "react";
import { Img, staticFile } from "remotion";

type Props = {
  headline: string;
  subtitle: string;
  screenshotFile: string;
  accentColor: string;
};

// iPad Pro 13-inch (M4) App Store screenshot canvas: 2064×2752
// If public/ipad_frame.png exists, it will be used as device frame overlay.
// Frame dimensions should match the ipad_frame.png source resolution.
// For a generic frameless layout we use the full canvas directly.

// Frameless layout — scale the phone screenshot to fill a centered panel.
// Replace with actual iPad frame constants once ipad_frame.png is available.
const CANVAS_W = 2064;
const CANVAS_H = 2752;

export const AppStoreScreenshotIPad: React.FC<Props> = ({
  headline,
  subtitle,
  screenshotFile,
  accentColor,
}) => {
  // App screenshot panel: centered, ~70% of canvas width, respects aspect ratio
  const panelW = Math.round(CANVAS_W * 0.72);
  // Use iPhone screenshot aspect (1320×2868 ≈ 0.46) for the inner image
  const panelH = Math.round(panelW * (2868 / 1320));

  return (
    <div
      style={{
        width: CANVAS_W,
        height: CANVAS_H,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "flex-start",
        background: `
          radial-gradient(ellipse 120% 40% at 50% 95%, ${accentColor}20 0%, transparent 60%),
          radial-gradient(ellipse 60% 30% at 30% 60%, ${accentColor}08 0%, transparent 50%),
          linear-gradient(180deg, #0d1117 0%, #111827 30%, #0f172a 60%, #0d1117 100%)
        `,
        overflow: "hidden",
        position: "relative",
      }}
    >
      {/* Ambient glow */}
      <div
        style={{
          position: "absolute",
          width: panelW + 300,
          height: panelH * 0.4,
          borderRadius: "50%",
          background: `radial-gradient(circle, ${accentColor}18 0%, transparent 50%)`,
          filter: "blur(140px)",
          bottom: -100,
          left: "50%",
          transform: "translateX(-50%)",
          pointerEvents: "none",
        }}
      />

      {/* Headline + subtitle */}
      <div
        style={{
          marginTop: 180,
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          gap: 28,
          zIndex: 2,
          paddingLeft: 80,
          paddingRight: 80,
        }}
      >
        <h1
          style={{
            fontSize: 148,
            fontWeight: 800,
            color: "#FFFFFF",
            textAlign: "center",
            margin: 0,
            fontFamily:
              '-apple-system, BlinkMacSystemFont, "SF Pro Display", "Helvetica Neue", system-ui, sans-serif',
            letterSpacing: "-2px",
            lineHeight: 1.1,
          }}
        >
          {headline}
        </h1>
        <p
          style={{
            fontSize: 62,
            fontWeight: 500,
            color: "rgba(255,255,255,0.5)",
            textAlign: "center",
            margin: 0,
            fontFamily:
              '-apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", system-ui, sans-serif',
            letterSpacing: "0.3px",
          }}
        >
          {subtitle}
        </p>
      </div>

      {/* App screenshot panel with rounded corners + drop shadow */}
      <div
        style={{
          marginTop: 90,
          position: "relative",
          width: panelW,
          height: panelH,
          zIndex: 2,
          borderRadius: panelW * 0.04,
          overflow: "hidden",
          filter: `
            drop-shadow(0 40px 80px rgba(0,0,0,0.75))
            drop-shadow(0 0 120px ${accentColor}12)
          `,
        }}
      >
        <Img
          src={staticFile(`screenshots/${screenshotFile}`)}
          style={{
            width: "100%",
            height: "100%",
            objectFit: "cover",
            objectPosition: "top center",
          }}
        />
      </div>
    </div>
  );
};
