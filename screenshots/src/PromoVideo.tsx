import React from "react";
import {
  AbsoluteFill,
  Img,
  OffthreadVideo,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  Easing,
  Sequence,
} from "remotion";

const ACCENT = "#00BCD4";

// Real simulator bezel frame dimensions
// Frame image: 854x1729, screen: left=48, top=51, size=759x1419
const FRAME_W = 854;
const FRAME_H = 1729;
const SCREEN_LEFT = 48;
const SCREEN_TOP = 51;
const SCREEN_W = 759;
const SCREEN_H = 1419;

// Scale for video canvas (1290x2796) — device takes ~46% of width
const SCALE = 590 / FRAME_W; // ≈0.691
const DEVICE_W = Math.round(FRAME_W * SCALE);
const DEVICE_H = Math.round(FRAME_H * SCALE);
const S_LEFT = Math.round(SCREEN_LEFT * SCALE);
const S_TOP = Math.round(SCREEN_TOP * SCALE);
const S_W = Math.round(SCREEN_W * SCALE);
const S_H = Math.round(SCREEN_H * SCALE);

// Scene text overlays timed to recording content
const scenes = [
  { text: "Mix Sounds", sub: "Layer 9 ambient sounds", start: 0, end: 210 },
  {
    text: "Choose Variants",
    sub: "Multiple sound options",
    start: 270,
    end: 480,
  },
  { text: "Sleep Timer", sub: "Drift off peacefully", start: 540, end: 720 },
];

const TextOverlay: React.FC<{
  text: string;
  sub: string;
  enterFrame: number;
  exitFrame: number;
}> = ({ text, sub, enterFrame, exitFrame }) => {
  const frame = useCurrentFrame();
  const relFrame = frame - enterFrame;
  const duration = exitFrame - enterFrame;

  const opacity = interpolate(
    relFrame,
    [0, 18, duration - 18, duration],
    [0, 1, 1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );

  const translateY = interpolate(relFrame, [0, 22], [30, 0], {
    extrapolateRight: "clamp",
    easing: Easing.out(Easing.cubic),
  });

  const subOpacity = interpolate(
    relFrame,
    [10, 28, duration - 18, duration],
    [0, 1, 1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );

  return (
    <div
      style={{
        position: "absolute",
        bottom: 180,
        left: 0,
        right: 0,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        gap: 10,
        opacity,
        transform: `translateY(${translateY}px)`,
        zIndex: 10,
        pointerEvents: "none",
      }}
    >
      <div
        style={{
          fontSize: 64,
          fontWeight: 800,
          color: "#fff",
          fontFamily:
            '-apple-system, "SF Pro Display", system-ui, sans-serif',
          letterSpacing: "-1px",
          textShadow: `0 0 40px ${ACCENT}50, 0 4px 12px rgba(0,0,0,0.6)`,
        }}
      >
        {text}
      </div>
      <div
        style={{
          fontSize: 32,
          fontWeight: 500,
          color: "rgba(255,255,255,0.55)",
          fontFamily:
            '-apple-system, "SF Pro Text", system-ui, sans-serif',
          opacity: subOpacity,
        }}
      >
        {sub}
      </div>
    </div>
  );
};

export const PromoVideo: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps, durationInFrames } = useVideoConfig();

  // Slow continuous rotation
  const rotateY = interpolate(frame, [0, durationInFrames], [-6, 6], {
    extrapolateRight: "clamp",
  });

  // Gentle floating motion
  const floatY = Math.sin((frame / fps) * 0.7) * 5;

  // Scale: slight zoom-in at start
  const scale = interpolate(frame, [0, 45], [0.93, 1], {
    extrapolateRight: "clamp",
    easing: Easing.out(Easing.cubic),
  });

  return (
    <AbsoluteFill
      style={{
        background: `
          radial-gradient(ellipse 100% 50% at 50% 100%, ${ACCENT}14 0%, transparent 55%),
          radial-gradient(ellipse 70% 40% at 20% 50%, ${ACCENT}06 0%, transparent 50%),
          linear-gradient(180deg, #090c14 0%, #0c1020 30%, #0a0e1a 60%, #080b15 100%)
        `,
        overflow: "hidden",
      }}
    >
      {/* Subtle ambient glow */}
      <div
        style={{
          position: "absolute",
          width: 700,
          height: 700,
          borderRadius: "50%",
          background: `radial-gradient(circle, ${ACCENT}0C 0%, transparent 60%)`,
          filter: "blur(100px)",
          bottom: -150 + Math.sin((frame / fps) * 0.3) * 20,
          left: "50%",
          transform: "translateX(-50%)",
          pointerEvents: "none",
        }}
      />

      {/* Device container with 3D perspective */}
      <div
        style={{
          position: "absolute",
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          display: "flex",
          justifyContent: "center",
          alignItems: "center",
          perspective: 2000,
        }}
      >
        <div
          style={{
            transform: `
              scale(${scale})
              rotateY(${rotateY}deg)
              translateY(${floatY}px)
            `,
            transformStyle: "preserve-3d",
          }}
        >
          {/* Device with real simulator bezel */}
          <div
            style={{
              position: "relative",
              width: DEVICE_W,
              height: DEVICE_H,
            }}
          >
            {/* Video playing inside the screen area */}
            <div
              style={{
                position: "absolute",
                left: S_LEFT,
                top: S_TOP,
                width: S_W,
                height: S_H,
                overflow: "hidden",
                borderRadius: 0,
              }}
            >
              <OffthreadVideo
                src={staticFile("screen_recording.mp4")}
                style={{
                  width: S_W,
                  height: S_H,
                  objectFit: "cover",
                }}
              />
            </div>

            {/* Real iPhone bezel overlay */}
            <Img
              src={staticFile("iphone_frame.png")}
              style={{
                position: "absolute",
                top: 0,
                left: 0,
                width: DEVICE_W,
                height: DEVICE_H,
                zIndex: 3,
              }}
            />
          </div>
        </div>
      </div>

      {/* Text overlays */}
      {scenes.map((scene) => (
        <Sequence
          key={scene.text}
          from={scene.start}
          durationInFrames={scene.end - scene.start}
        >
          <TextOverlay
            text={scene.text}
            sub={scene.sub}
            enterFrame={0}
            exitFrame={scene.end - scene.start}
          />
        </Sequence>
      ))}
    </AbsoluteFill>
  );
};
