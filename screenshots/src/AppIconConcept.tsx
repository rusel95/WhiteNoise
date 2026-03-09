import React from "react";

type IconProps = {
  variant: "sound-wave" | "shh-finger" | "sleeping-cloud" | "ripple" | "wave-h";
};

// App design system colors (from GlassDesignSystem.swift)
const COLORS = {
  background: "#0D0D0F",
  surface: "#1C1C1E",
  elevated: "#2C2C2E",
  primary: "#4A90D9",
  secondary: "#6BA3E0",
  cyan: "#00BCD4",    // main accent from screenshots
  purple: "#7C4DFF",  // timer accent
  lightCyan: "#4FC3F7",
};

/**
 * Concept 1: Abstract Sound Wave — concentric arcs fading out
 * Represents "white noise" visually, "hush" = sound fading to silence
 */
const SoundWaveIcon: React.FC = () => (
  <div style={{
    width: 1024, height: 1024, position: "relative",
    background: `
      radial-gradient(ellipse 80% 80% at 50% 55%, ${COLORS.cyan}15 0%, transparent 70%),
      radial-gradient(circle at 50% 50%, #111827 0%, ${COLORS.background} 100%)
    `,
    display: "flex", alignItems: "center", justifyContent: "center",
    overflow: "hidden",
  }}>
    {/* Ambient glow */}
    <div style={{
      position: "absolute", width: 600, height: 600, borderRadius: "50%",
      background: `radial-gradient(circle, ${COLORS.cyan}20 0%, transparent 60%)`,
      filter: "blur(80px)",
    }} />
    {/* Sound wave arcs - 5 concentric, fading outward */}
    {[0, 1, 2, 3, 4].map((i) => {
      const size = 180 + i * 110;
      const opacity = 0.9 - i * 0.17;
      const strokeWidth = 38 - i * 5;
      return (
        <div key={i} style={{
          position: "absolute",
          width: size, height: size,
          borderRadius: "50%",
          border: `${strokeWidth}px solid rgba(0, 188, 212, ${opacity})`,
          // Only show right half (sound emanating)
          clipPath: i < 3 ? undefined : `inset(0 0 0 50%)`,
        }} />
      );
    })}
    {/* Center dot - the "source" */}
    <div style={{
      width: 80, height: 80, borderRadius: "50%",
      background: `linear-gradient(135deg, ${COLORS.cyan}, ${COLORS.primary})`,
      boxShadow: `0 0 40px ${COLORS.cyan}60, 0 0 80px ${COLORS.cyan}30`,
      zIndex: 2,
    }} />
  </div>
);

/**
 * Concept 2: "Shh" Finger — minimalist finger-to-lips silhouette
 * Directly evokes "Hush" meaning. Warm accent on dark base.
 */
const ShhFingerIcon: React.FC = () => (
  <div style={{
    width: 1024, height: 1024, position: "relative",
    background: `
      radial-gradient(ellipse 70% 60% at 50% 65%, ${COLORS.cyan}12 0%, transparent 60%),
      linear-gradient(180deg, #0f1419 0%, ${COLORS.background} 100%)
    `,
    display: "flex", alignItems: "center", justifyContent: "center",
    overflow: "hidden",
  }}>
    {/* Ambient bottom glow */}
    <div style={{
      position: "absolute", bottom: -100, width: 800, height: 400, borderRadius: "50%",
      background: `radial-gradient(circle, ${COLORS.cyan}18 0%, transparent 50%)`,
      filter: "blur(60px)",
    }} />
    {/* Finger silhouette using CSS shapes */}
    <svg width="440" height="600" viewBox="0 0 440 600" style={{ zIndex: 2, marginTop: -40 }}>
      {/* Finger pointing up */}
      <defs>
        <linearGradient id="fingerGrad" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor={COLORS.cyan} />
          <stop offset="100%" stopColor={COLORS.primary} />
        </linearGradient>
      </defs>
      {/* Vertical finger */}
      <rect x="175" y="40" width="90" height="300" rx="45" fill="url(#fingerGrad)" />
      {/* Lips / mouth area - simple curved line */}
      <ellipse cx="220" cy="420" rx="120" ry="60" fill="none"
        stroke="rgba(255,255,255,0.3)" strokeWidth="6" />
      {/* Lower lip accent */}
      <path d="M 130 420 Q 220 490 310 420" fill="none"
        stroke="rgba(255,255,255,0.15)" strokeWidth="4" />
      {/* Small sound waves being silenced - fading */}
      {[0, 1, 2].map((i) => (
        <path key={i}
          d={`M ${320 + i * 30} ${380 - i * 10} Q ${340 + i * 30} ${420} ${320 + i * 30} ${460 + i * 10}`}
          fill="none" stroke={`rgba(0, 188, 212, ${0.4 - i * 0.12})`}
          strokeWidth={`${4 - i}`} strokeLinecap="round"
        />
      ))}
    </svg>
  </div>
);

/**
 * Concept 3: Sleeping Cloud — minimal cloud with closed eyes, subtle waves
 * Friendly, approachable. Similar vibe to SleepSounds but distinctive.
 */
const SleepingCloudIcon: React.FC = () => (
  <div style={{
    width: 1024, height: 1024, position: "relative",
    background: `
      radial-gradient(ellipse 90% 70% at 50% 60%, ${COLORS.primary}15 0%, transparent 60%),
      linear-gradient(180deg, #111827 0%, ${COLORS.background} 100%)
    `,
    display: "flex", alignItems: "center", justifyContent: "center",
    overflow: "hidden",
  }}>
    <div style={{
      position: "absolute", bottom: -80, width: 700, height: 350, borderRadius: "50%",
      background: `radial-gradient(circle, ${COLORS.primary}15 0%, transparent 50%)`,
      filter: "blur(60px)",
    }} />
    <svg width="650" height="500" viewBox="0 0 650 500" style={{ zIndex: 2, marginTop: 30 }}>
      <defs>
        <linearGradient id="cloudGrad" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#6BA3E0" />
          <stop offset="100%" stopColor="#4A90D9" />
        </linearGradient>
      </defs>
      {/* Cloud body */}
      <ellipse cx="325" cy="280" rx="220" ry="120" fill="url(#cloudGrad)" opacity="0.9" />
      <circle cx="200" cy="240" r="100" fill="url(#cloudGrad)" opacity="0.9" />
      <circle cx="400" cy="230" r="110" fill="url(#cloudGrad)" opacity="0.9" />
      <circle cx="300" cy="200" r="120" fill="url(#cloudGrad)" opacity="0.9" />
      {/* Closed eyes - gentle arcs */}
      <path d="M 240 260 Q 260 275 280 260" fill="none" stroke="rgba(13,13,15,0.6)" strokeWidth="8" strokeLinecap="round" />
      <path d="M 350 260 Q 370 275 390 260" fill="none" stroke="rgba(13,13,15,0.6)" strokeWidth="8" strokeLinecap="round" />
      {/* Subtle smile */}
      <path d="M 290 300 Q 325 320 360 300" fill="none" stroke="rgba(13,13,15,0.4)" strokeWidth="5" strokeLinecap="round" />
      {/* Sound waves emanating downward (like rain/noise falling) */}
      {[0, 1, 2].map((i) => (
        <path key={i}
          d={`M ${240 + i * 85} 380 Q ${255 + i * 85} 410 ${240 + i * 85} 440`}
          fill="none" stroke={`rgba(74, 144, 217, ${0.5 - i * 0.12})`}
          strokeWidth="5" strokeLinecap="round"
        />
      ))}
    </svg>
  </div>
);

/**
 * Concept 4: Ripple — a single drop creating expanding rings
 * Zen, minimal, suggests the calming effect of ambient sound.
 * Matches the glass morphism / dark UI of the app.
 */
const RippleIcon: React.FC = () => (
  <div style={{
    width: 1024, height: 1024, position: "relative",
    background: `
      radial-gradient(ellipse 80% 80% at 50% 45%, ${COLORS.cyan}10 0%, transparent 60%),
      linear-gradient(180deg, #0d1117 0%, ${COLORS.background} 100%)
    `,
    display: "flex", alignItems: "center", justifyContent: "center",
    overflow: "hidden",
  }}>
    {/* Subtle ambient glow */}
    <div style={{
      position: "absolute", width: 500, height: 500, borderRadius: "50%",
      background: `radial-gradient(circle, ${COLORS.cyan}15 0%, transparent 55%)`,
      filter: "blur(60px)",
    }} />
    {/* Ripple rings - expanding from center */}
    {[0, 1, 2, 3, 4].map((i) => {
      const size = 100 + i * 140;
      const opacity = 0.7 - i * 0.14;
      const strokeW = 6 - i * 0.8;
      return (
        <div key={i} style={{
          position: "absolute",
          width: size, height: size * 0.45,
          borderRadius: "50%",
          border: `${Math.max(strokeW, 2)}px solid rgba(0, 188, 212, ${opacity})`,
          marginTop: i * 25,
        }} />
      );
    })}
    {/* Drop / center point */}
    <div style={{
      position: "absolute",
      width: 40, height: 60,
      marginTop: -180,
      background: `linear-gradient(180deg, transparent 0%, ${COLORS.cyan} 100%)`,
      clipPath: "polygon(50% 0%, 0% 100%, 100% 100%)",
      borderRadius: "0 0 50% 50%",
      zIndex: 3,
    }} />
    {/* Splash point */}
    <div style={{
      width: 30, height: 30, borderRadius: "50%",
      background: COLORS.cyan,
      boxShadow: `0 0 30px ${COLORS.cyan}50, 0 0 60px ${COLORS.cyan}20`,
      marginTop: -60,
      zIndex: 3,
    }} />
  </div>
);

/**
 * Concept 5: Wave H — The letter "H" formed by sound waveform
 * Brandable, unique, combines typography with the sound concept.
 */
const WaveHIcon: React.FC = () => (
  <div style={{
    width: 1024, height: 1024, position: "relative",
    background: `
      radial-gradient(ellipse 70% 70% at 50% 50%, ${COLORS.cyan}12 0%, transparent 60%),
      linear-gradient(180deg, #0d1117 0%, ${COLORS.background} 100%)
    `,
    display: "flex", alignItems: "center", justifyContent: "center",
    overflow: "hidden",
  }}>
    <div style={{
      position: "absolute", width: 600, height: 400, borderRadius: "50%",
      background: `radial-gradient(circle, ${COLORS.cyan}15 0%, transparent 50%)`,
      filter: "blur(80px)",
    }} />
    <svg width="600" height="600" viewBox="0 0 600 600" style={{ zIndex: 2 }}>
      <defs>
        <linearGradient id="hGrad" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor={COLORS.cyan} />
          <stop offset="100%" stopColor={COLORS.primary} />
        </linearGradient>
      </defs>
      {/* Left vertical bar of H */}
      <rect x="120" y="100" width="55" height="400" rx="27" fill="url(#hGrad)" />
      {/* Right vertical bar of H */}
      <rect x="425" y="100" width="55" height="400" rx="27" fill="url(#hGrad)" />
      {/* Middle bar as a sound waveform */}
      <path
        d="M 175 300
           Q 210 230, 240 300
           Q 270 370, 300 300
           Q 330 230, 360 300
           Q 390 370, 425 300"
        fill="none" stroke="url(#hGrad)" strokeWidth="45" strokeLinecap="round"
      />
    </svg>
  </div>
);

export const AppIconConcept: React.FC<IconProps> = ({ variant }) => {
  switch (variant) {
    case "sound-wave": return <SoundWaveIcon />;
    case "shh-finger": return <ShhFingerIcon />;
    case "sleeping-cloud": return <SleepingCloudIcon />;
    case "ripple": return <RippleIcon />;
    case "wave-h": return <WaveHIcon />;
  }
};
