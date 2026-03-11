/* eslint-disable ts/no-require-imports */
//
import type { Config } from "tailwindcss";

const {
  default: flattenColorPalette,
} = require("tailwindcss/lib/util/flattenColorPalette");
const svgToDataUri = require("mini-svg-data-uri");

const config = {
  darkMode: ["class"],
  content: [
    "./pages/**/*.{ts,tsx}",
    "./components/**/*.{ts,tsx}",
    "./app/**/*.{ts,tsx}",
    "./src/**/*.{ts,tsx}",
  ],
  prefix: "",
  theme: {
    container: {
      center: true,
      padding: "2rem",
      screens: {
        "2xl": "1400px",
      },
    },
    extend: {
      colors: {
        border: "hsl(var(--border))",
        input: "hsl(var(--input))",
        ring: "hsl(var(--ring))",
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        primary: {
          DEFAULT: "hsl(var(--primary))",
          foreground: "hsl(var(--primary-foreground))",
        },
        secondary: {
          DEFAULT: "hsl(var(--secondary))",
          foreground: "hsl(var(--secondary-foreground))",
        },
        destructive: {
          DEFAULT: "hsl(var(--destructive))",
          foreground: "hsl(var(--destructive-foreground))",
        },
        muted: {
          DEFAULT: "hsl(var(--muted))",
          foreground: "hsl(var(--muted-foreground))",
        },
        accent: {
          DEFAULT: "hsl(var(--accent))",
          foreground: "hsl(var(--accent-foreground))",
        },
        popover: {
          DEFAULT: "hsl(var(--popover))",
          foreground: "hsl(var(--popover-foreground))",
        },
        card: {
          DEFAULT: "hsl(var(--card))",
          foreground: "hsl(var(--card-foreground))",
        },
        // Heretek Custom Colors
        rust: {
          50: "hsl(28 60% 95%)",
          100: "hsl(28 60% 90%)",
          200: "hsl(28 60% 80%)",
          300: "hsl(28 65% 70%)",
          400: "hsl(28 70% 55%)",
          500: "hsl(28 75% 45%)",
          600: "hsl(28 80% 38%)",
          700: "hsl(28 75% 30%)",
          800: "hsl(28 70% 22%)",
          900: "hsl(28 65% 15%)",
          950: "hsl(28 60% 8%)",
        },
        brass: {
          50: "hsl(43 50% 92%)",
          100: "hsl(43 55% 85%)",
          200: "hsl(43 60% 75%)",
          300: "hsl(43 65% 62%)",
          400: "hsl(43 70% 50%)",
          500: "hsl(43 65% 45%)",
          600: "hsl(43 60% 38%)",
          700: "hsl(43 55% 30%)",
          800: "hsl(43 50% 22%)",
          900: "hsl(43 45% 15%)",
          950: "hsl(43 40% 8%)",
        },
        copper: {
          50: "hsl(25 50% 92%)",
          100: "hsl(25 55% 85%)",
          200: "hsl(25 60% 75%)",
          300: "hsl(25 65% 62%)",
          400: "hsl(25 70% 50%)",
          500: "hsl(25 75% 42%)",
          600: "hsl(25 80% 35%)",
          700: "hsl(25 75% 28%)",
          800: "hsl(25 70% 20%)",
          900: "hsl(25 65% 14%)",
          950: "hsl(25 60% 7%)",
        },
        corruption: {
          50: "hsl(145 40% 95%)",
          100: "hsl(145 45% 88%)",
          200: "hsl(145 50% 78%)",
          300: "hsl(145 55% 65%)",
          400: "hsl(145 60% 50%)",
          500: "hsl(145 65% 40%)",
          600: "hsl(145 70% 32%)",
          700: "hsl(145 65% 25%)",
          800: "hsl(145 60% 18%)",
          900: "hsl(145 55% 12%)",
          950: "hsl(145 50% 6%)",
        },
        iron: {
          50: "hsl(30 10% 95%)",
          100: "hsl(30 12% 88%)",
          200: "hsl(30 15% 78%)",
          300: "hsl(30 18% 65%)",
          400: "hsl(30 20% 50%)",
          500: "hsl(30 22% 42%)",
          600: "hsl(30 25% 35%)",
          700: "hsl(30 22% 28%)",
          800: "hsl(30 20% 20%)",
          900: "hsl(30 18% 12%)",
          950: "hsl(30 15% 6%)",
        },
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
        sm: "calc(var(--radius) - 4px)",
      },
      keyframes: {
        "accordion-down": {
          from: { height: "0" },
          to: { height: "var(--radix-accordion-content-height)" },
        },
        "accordion-up": {
          from: { height: "var(--radix-accordion-content-height)" },
          to: { height: "0" },
        },
        "shine": {
          from: { backgroundPosition: "200% 0" },
          to: { backgroundPosition: "-200% 0" },
        },
        "gradient": {
          to: {
            backgroundPosition: "var(--bg-size) 0",
          },
        },
        "shine-pulse": {
          "0%": {
            "background-position": "0% 0%",
          },
          "50%": {
            "background-position": "100% 100%",
          },
          "to": {
            "background-position": "0% 0%",
          },
        },
        "moveHorizontal": {
          "0%": {
            transform: "translateX(-50%) translateY(-10%)",
          },
          "50%": {
            transform: "translateX(50%) translateY(10%)",
          },
          "100%": {
            transform: "translateX(-50%) translateY(-10%)",
          },
        },
        "moveInCircle": {
          "0%": {
            transform: "rotate(0deg)",
          },
          "50%": {
            transform: "rotate(180deg)",
          },
          "100%": {
            transform: "rotate(360deg)",
          },
        },
        "moveVertical": {
          "0%": {
            transform: "translateY(-50%)",
          },
          "50%": {
            transform: "translateY(50%)",
          },
          "100%": {
            transform: "translateY(-50%)",
          },
        },
        // Heretek Glitch Animations
        "glitch": {
          "0%, 90%, 100%": {
            transform: "translate(0)",
            filter: "none",
          },
          "91%": {
            transform: "translate(-2px, 1px)",
            filter: "hue-rotate(90deg) saturate(1.5)",
          },
          "92%": {
            transform: "translate(2px, -1px)",
            filter: "hue-rotate(-90deg) saturate(1.5)",
          },
          "93%": {
            transform: "translate(-1px, -1px)",
            filter: "hue-rotate(45deg)",
          },
          "94%": {
            transform: "translate(1px, 1px)",
            filter: "none",
          },
        },
        "glitch-text": {
          "0%, 100%": {
            "text-shadow": "none",
          },
          "1%": {
            "text-shadow": "-2px 0 hsl(145 70% 40%), 2px 0 hsl(0 70% 45%)",
          },
          "2%": {
            "text-shadow": "2px 0 hsl(145 70% 40%), -2px 0 hsl(0 70% 45%)",
          },
          "3%": {
            "text-shadow": "none",
          },
        },
        "flicker": {
          "0%, 100%": { opacity: "1" },
          "92%": { opacity: "1" },
          "93%": { opacity: "0.8" },
          "94%": { opacity: "1" },
          "96%": { opacity: "0.9" },
          "97%": { opacity: "1" },
        },
        "corrupted-pulse": {
          "0%, 100%": {
            "box-shadow": "0 0 10px hsl(145 50% 25% / 0.2), 0 0 20px hsl(145 40% 20% / 0.1)",
          },
          "50%": {
            "box-shadow": "0 0 15px hsl(145 60% 30% / 0.3), 0 0 30px hsl(145 50% 25% / 0.15), 0 0 45px hsl(145 40% 20% / 0.1)",
          },
        },
        "scan-line": {
          "0%": {
            transform: "translateY(-100%)",
          },
          "100%": {
            transform: "translateY(100vh)",
          },
        },
        "rust-fall": {
          "0%": {
            transform: "translateY(-10%) rotate(0deg)",
            opacity: "0",
          },
          "10%": {
            opacity: "1",
          },
          "90%": {
            opacity: "1",
          },
          "100%": {
            transform: "translateY(100vh) rotate(720deg)",
            opacity: "0",
          },
        },
        "metal-shine": {
          "0%": {
            "background-position": "-200% 0",
          },
          "100%": {
            "background-position": "200% 0",
          },
        },
        "heretic-glow": {
          "0%, 100%": {
            "filter": "brightness(1) saturate(1)",
          },
          "50%": {
            "filter": "brightness(1.1) saturate(1.2)",
          },
        },
      },
      animation: {
        "accordion-down": "accordion-down 0.2s ease-out",
        "accordion-up": "accordion-up 0.2s ease-out",
        "shine": "shine 8s ease-in-out infinite",
        "gradient": "gradient 8s linear infinite",
        // Heretek Animations
        "glitch": "glitch 4s infinite",
        "glitch-text": "glitch-text 8s infinite",
        "flicker": "flicker 8s infinite",
        "corrupted-pulse": "corrupted-pulse 3s ease-in-out infinite",
        "scan-line": "scan-line 8s linear infinite",
        "rust-fall": "rust-fall 10s linear infinite",
        "metal-shine": "metal-shine 3s ease-in-out infinite",
        "heretic-glow": "heretic-glow 4s ease-in-out infinite",
      },
      backgroundImage: {
        // Heretek Background Patterns
        "rust-gradient": "linear-gradient(135deg, hsl(28 70% 35%) 0%, hsl(35 50% 25%) 50%, hsl(28 60% 30%) 100%)",
        "corruption-gradient": "linear-gradient(180deg, hsl(145 50% 20%) 0%, hsl(145 60% 30%) 50%, hsl(145 50% 25%) 100%)",
        "metal-surface": "linear-gradient(145deg, hsl(30 15% 15%) 0%, hsl(30 20% 10%) 50%, hsl(30 15% 12%) 100%)",
        "brass-shine": "linear-gradient(90deg, hsl(43 60% 35%) 0%, hsl(43 75% 50%) 50%, hsl(43 60% 35%) 100%)",
      },
    },
  },
  plugins: [
    require(`tailwindcss-animated`),
    require("tailwindcss-animate"),
    addVariablesForColors,
    function ({ matchUtilities, theme }: any) {
      matchUtilities(
        {
          "bg-grid": (value: any) => ({
            backgroundImage: `url("${svgToDataUri(
              `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" width="32" height="32" fill="none" stroke="${value}"><path d="M0 .5H31.5V32"/></svg>`,
            )}")`,
          }),
          "bg-grid-small": (value: any) => ({
            backgroundImage: `url("${svgToDataUri(
              `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" width="8" height="8" fill="none" stroke="${value}"><path d="M0 .5H31.5V32"/></svg>`,
            )}")`,
          }),
          "bg-dot": (value: any) => ({
            backgroundImage: `url("${svgToDataUri(
              `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" width="16" height="16" fill="none"><circle fill="${value}" id="pattern-circle" cx="10" cy="10" r="1.6257413380501518"></circle></svg>`,
            )}")`,
          }),
          // Heretek Pattern Utilities
          "bg-circuit": (value: any) => ({
            backgroundImage: `url("${svgToDataUri(
              `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64" fill="none" stroke="${value}" stroke-width="0.5"><path d="M0 32h20m4 0h16m4 0h20M32 0v20m0 4v16m0 4v20"/><circle cx="32" cy="32" r="4" fill="${value}" fill-opacity="0.3"/><circle cx="24" cy="32" r="2" fill="${value}"/><circle cx="40" cy="32" r="2" fill="${value}"/><circle cx="32" cy="24" r="2" fill="${value}"/><circle cx="32" cy="40" r="2" fill="${value}"/></svg>`,
            )}")`,
          }),
          "bg-rust-texture": (value: any) => ({
            backgroundImage: `url("${svgToDataUri(
              `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100" height="100"><filter id="rust"><feTurbulence type="fractalNoise" baseFrequency="0.8" numOctaves="4" result="noise"/><feColorMatrix type="saturate" values="0.3" in="noise" result="rust"/></filter><rect width="100" height="100" fill="${value}" style="filter:url(#rust)"/></svg>`,
            )}")`,
          }),
        },
        {
          values: flattenColorPalette(theme("backgroundColor")),
          type: "color",
        },
      );
    },
  ],
} satisfies Config;

function addVariablesForColors({ addBase, theme }: any) {
  const allColors = flattenColorPalette(theme("colors"));
  const newVars = Object.fromEntries(
    Object.entries(allColors).map(([key, val]) => [`--${key}`, val]),
  );
  addBase({
    ":root": newVars,
  });
}

export default config;
