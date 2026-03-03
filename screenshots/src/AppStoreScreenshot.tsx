import React from "react";
import { Img, staticFile } from "remotion";

type Props = {
  headline: string;
  subtitle: string;
  screenshotFile: string;
  accentColor: string;
};

// Koubou high-quality frame: 1470x3000
// Screen area detected at: left=75, top=66, size=1320x2868
const FRAME_W = 1470;
const FRAME_H = 3000;
const SCREEN_LEFT = 75;
const SCREEN_TOP = 66;
const SCREEN_W = 1320;
const SCREEN_H = 2868;

// Scale device to ~75% of canvas width for visible bezel + drop shadow
const DEVICE_SCALE = (1320 * 0.75) / FRAME_W;
const D_W = Math.round(FRAME_W * DEVICE_SCALE);
const D_H = Math.round(FRAME_H * DEVICE_SCALE);
const S_LEFT = Math.round(SCREEN_LEFT * DEVICE_SCALE);
const S_TOP = Math.round(SCREEN_TOP * DEVICE_SCALE);
const S_W = Math.round(SCREEN_W * DEVICE_SCALE);
const S_H = Math.round(SCREEN_H * DEVICE_SCALE);

export const AppStoreScreenshot: React.FC<Props> = ({
  headline,
  subtitle,
  screenshotFile,
  accentColor,
}) => {
  return (
    <div
      style={{
        width: 1320,
        height: 2868,
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
      {/* Ambient glow behind device */}
      <div
        style={{
          position: "absolute",
          width: D_W + 200,
          height: D_H * 0.5,
          borderRadius: "50%",
          background: `radial-gradient(circle, ${accentColor}18 0%, transparent 50%)`,
          filter: "blur(100px)",
          bottom: -80,
          left: "50%",
          transform: "translateX(-50%)",
          pointerEvents: "none",
        }}
      />

      {/* Headline */}
      <div
        style={{
          marginTop: 140,
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          gap: 20,
          zIndex: 2,
        }}
      >
        <h1
          style={{
            fontSize: 108,
            fontWeight: 800,
            color: "#FFFFFF",
            textAlign: "center",
            margin: 0,
            fontFamily:
              '-apple-system, BlinkMacSystemFont, "SF Pro Display", "Helvetica Neue", system-ui, sans-serif',
            letterSpacing: "-1.5px",
            lineHeight: 1.1,
          }}
        >
          {headline}
        </h1>
        <p
          style={{
            fontSize: 46,
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

      {/* Device with drop shadow and glow */}
      <div
        style={{
          marginTop: 70,
          position: "relative",
          width: D_W,
          height: D_H,
          zIndex: 2,
          filter: `
            drop-shadow(0 25px 50px rgba(0,0,0,0.7))
            drop-shadow(0 0 100px ${accentColor}12)
          `,
        }}
      >
        {/* Screenshot inside screen area */}
        <Img
          src={staticFile(`screenshots/${screenshotFile}`)}
          style={{
            position: "absolute",
            left: S_LEFT,
            top: S_TOP,
            width: S_W,
            height: S_H,
            objectFit: "cover",
            objectPosition: "top center",
            borderRadius: S_W * 0.045,
          }}
        />

        {/* High-quality device frame overlay */}
        <Img
          src={staticFile("iphone_frame.png")}
          style={{
            position: "absolute",
            top: 0,
            left: 0,
            width: D_W,
            height: D_H,
            zIndex: 3,
          }}
        />
      </div>
    </div>
  );
};
