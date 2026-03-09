import React from "react";

const COLORS = {
  cyan: "#00BCD4",
  primary: "#4A90D9",
};

export const HushLogoTransparent: React.FC = () => (
  <div style={{
    width: 1200, height: 1200,
    display: "flex", alignItems: "center", justifyContent: "center",
    background: "transparent",
  }}>
    <svg width="720" height="720" viewBox="0 0 600 600">
      <defs>
        <linearGradient id="hGradLogo" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor={COLORS.cyan} />
          <stop offset="100%" stopColor={COLORS.primary} />
        </linearGradient>
      </defs>
      <rect x="120" y="100" width="55" height="400" rx="27" fill="url(#hGradLogo)" />
      <rect x="425" y="100" width="55" height="400" rx="27" fill="url(#hGradLogo)" />
      <path
        d="M 175 300 Q 210 230, 240 300 Q 270 370, 300 300 Q 330 230, 360 300 Q 390 370, 425 300"
        fill="none" stroke="url(#hGradLogo)" strokeWidth="45" strokeLinecap="round"
      />
    </svg>
  </div>
);
