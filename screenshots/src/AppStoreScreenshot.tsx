import React from "react";
import { Img, staticFile } from "remotion";

type Props = {
  headline: string;
  subtitle: string;
  screenshotFile: string;
  accentColor: string;
};

export const AppStoreScreenshot: React.FC<Props> = ({
  headline,
  subtitle,
  screenshotFile,
  accentColor,
}) => {
  return (
    <div
      style={{
        width: "100%",
        height: "100%",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "flex-start",
        background: `
          radial-gradient(ellipse 80% 50% at 50% 100%, ${accentColor}22 0%, transparent 70%),
          radial-gradient(ellipse 60% 40% at 20% 50%, ${accentColor}15 0%, transparent 60%),
          radial-gradient(ellipse 60% 40% at 80% 30%, ${accentColor}10 0%, transparent 60%),
          linear-gradient(180deg, #0a0e1a 0%, #0d1526 40%, #0a1020 100%)
        `,
        overflow: "hidden",
        position: "relative",
      }}
    >
      {/* Liquid glass orbs in background */}
      <div
        style={{
          position: "absolute",
          width: 600,
          height: 600,
          borderRadius: "50%",
          background: `radial-gradient(circle, ${accentColor}18 0%, transparent 70%)`,
          filter: "blur(80px)",
          top: -100,
          right: -200,
        }}
      />
      <div
        style={{
          position: "absolute",
          width: 500,
          height: 500,
          borderRadius: "50%",
          background: `radial-gradient(circle, ${accentColor}12 0%, transparent 70%)`,
          filter: "blur(60px)",
          bottom: 200,
          left: -150,
        }}
      />

      {/* Headline Section */}
      <div
        style={{
          marginTop: 160,
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          gap: 20,
          zIndex: 2,
        }}
      >
        <h1
          style={{
            fontSize: 96,
            fontWeight: 800,
            color: "#FFFFFF",
            textAlign: "center",
            margin: 0,
            fontFamily:
              '-apple-system, BlinkMacSystemFont, "SF Pro Display", system-ui, sans-serif',
            letterSpacing: "-1px",
            textShadow: `0 0 60px ${accentColor}40, 0 2px 4px rgba(0,0,0,0.3)`,
          }}
        >
          {headline}
        </h1>
        <p
          style={{
            fontSize: 44,
            fontWeight: 500,
            color: "rgba(255,255,255,0.65)",
            textAlign: "center",
            margin: 0,
            fontFamily:
              '-apple-system, BlinkMacSystemFont, "SF Pro Text", system-ui, sans-serif',
            letterSpacing: "0.5px",
          }}
        >
          {subtitle}
        </p>
      </div>

      {/* Device Frame with Liquid Glass effect */}
      <div
        style={{
          marginTop: 80,
          position: "relative",
          zIndex: 2,
          display: "flex",
          justifyContent: "center",
        }}
      >
        {/* Glow behind device */}
        <div
          style={{
            position: "absolute",
            width: "80%",
            height: "60%",
            bottom: -50,
            left: "10%",
            background: `radial-gradient(ellipse, ${accentColor}25 0%, transparent 70%)`,
            filter: "blur(50px)",
            zIndex: -1,
          }}
        />

        {/* Glass card container */}
        <div
          style={{
            padding: 16,
            borderRadius: 70,
            background:
              "linear-gradient(135deg, rgba(255,255,255,0.08) 0%, rgba(255,255,255,0.02) 100%)",
            backdropFilter: "blur(20px)",
            border: "1px solid rgba(255,255,255,0.1)",
            boxShadow: `
              0 20px 60px rgba(0,0,0,0.4),
              0 0 80px ${accentColor}15,
              inset 0 1px 0 rgba(255,255,255,0.1)
            `,
          }}
        >
          {/* Phone screenshot */}
          <Img
            src={staticFile(`screenshots/${screenshotFile}`)}
            style={{
              width: 900,
              height: "auto",
              borderRadius: 56,
              display: "block",
            }}
          />
        </div>
      </div>
    </div>
  );
};
