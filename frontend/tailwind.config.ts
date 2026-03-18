/* eslint-disable ts/no-require-imports */
//
import type { Config } from "tailwindcss";

const { default: flattenColorPalette } = require("tailwindcss/lib/util/flattenColorPalette");
const svgToDataUri = require("mini-svg-data-uri");

const config = {
  darkMode: ["class"],
  content: ["./pages/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}", "./app/**/*.{ts,tsx}", "./src/**/*.{ts,tsx}"],
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
        // Heretek Custom Colors - Blood & Steel
        blood: {
          50: "hsl(0 60% 95%)",
          100: "hsl(0 65% 90%)",
          200: "hsl(0 70% 80%)",
          300: "hsl(0 75% 65%)",
          400: "hsl(0 80% 55%)",
          500: "hsl(0 85% 45%)",
          600: "hsl(0 80% 38%)",
          700: "hsl(0 75% 30%)",
          800: "hsl(0 70% 22%)",
          900: "hsl(0 65% 15%)",
          950: "hsl(0 60% 8%)",
        },
        steel: {
          50: "hsl(0 5% 95%)",
          100: "hsl(0 8% 88%)",
          200: "hsl(0 10% 78%)",
          300: "hsl(0 12% 65%)",
          400: "hsl(0 15% 50%)",
          500: "hsl(0 18% 42%)",
          600: "hsl(0 20% 35%)",
          700: "hsl(0 18% 28%)",
          800: "hsl(0 15% 20%)",
          900: "hsl(0 12% 12%)",
          950: "hsl(0 10% 6%)",
        },
        void: {
          50: "hsl(0 0% 95%)",
          100: "hsl(0 0% 88%)",
          200: "hsl(0 0% 78%)",
          300: "hsl(0 0% 65%)",
          400: "hsl(0 0% 50%)",
          500: "hsl(0 0% 42%)",
          600: "hsl(0 0% 35%)",
          700: "hsl(0 0% 28%)",
          800: "hsl(0 0% 20%)",
          900: "hsl(0 0% 12%)",
          950: "hsl(0 0% 6%)",
        },
        rust: {
          50: "hsl(0 60% 95%)",
          100: "hsl(0 65% 90%)",
          200: "hsl(0 70% 80%)",
          300: "hsl(0 75% 70%)",
          400: "hsl(0 80% 55%)",
          500: "hsl(0 85% 45%)",
          600: "hsl(0 80% 38%)",
          700: "hsl(0 75% 30%)",
          800: "hsl(0 70% 22%)",
          900: "hsl(0 65% 15%)",
          950: "hsl(0 60% 8%)",
        },
        brass: {
          50: "hsl(45 50% 92%)",
          100: "hsl(45 55% 85%)",
          200: "hsl(45 60% 75%)",
          300: "hsl(45 65% 62%)",
          400: "hsl(45 70% 50%)",
          500: "hsl(45 65% 45%)",
          600: "hsl(45 60% 38%)",
          700: "hsl(45 55% 30%)",
          800: "hsl(45 50% 22%)",
          900: "hsl(45 45% 15%)",
          950: "hsl(45 40% 8%)",
        },
        corruption: {
          50: "hsl(0 40% 95%)",
          100: "hsl(0 45% 88%)",
          200: "hsl(0 50% 78%)",
          300: "hsl(0 55% 65%)",
          400: "hsl(0 60% 50%)",
          500: "hsl(0 65% 40%)",
          600: "hsl(0 70% 32%)",
          700: "hsl(0 65% 25%)",
          800: "hsl(0 60% 18%)",
          900: "hsl(0 55% 12%)",
          950: "hsl(0 50% 6%)",
        },
        iron: {
          50: "hsl(0 5% 95%)",
          100: "hsl(0 8% 88%)",
          200: "hsl(0 10% 78%)",
          300: "hsl(0 12% 65%)",
          400: "hsl(0 15% 50%)",
          500: "hsl(0 18% 42%)",
          600: "hsl(0 20% 35%)",
          700: "hsl(0 18% 28%)",
          800: "hsl(0 15% 20%)",
          900: "hsl(0 12% 12%)",
          950: "hsl(0 10% 6%)",
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
        shine: {
          from: { backgroundPosition: "200% 0" },
          to: { backgroundPosition: "-200% 0" },
        },
        gradient: {
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
          to: {
            "background-position": "0% 0%",
          },
        },
        moveHorizontal: {
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
        moveInCircle: {
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
        moveVertical: {
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
        // Heretek Glitch Animations - Enhanced
        glitch: {
          "0%, 88%, 100%": {
            transform: "translate(0)",
            filter: "none",
          },
          "89%": {
            transform: "translate(-2px, 1px)",
            filter: "hue-rotate(90deg) saturate(1.5)",
          },
          "90%": {
            transform: "translate(2px, -1px)",
            filter: "hue-rotate(-90deg) saturate(1.5)",
          },
          "91%": {
            transform: "translate(-1px, -1px)",
            filter: "hue-rotate(45deg) brightness(1.2)",
          },
          "92%": {
            transform: "translate(1px, 1px)",
            filter: "none",
          },
          "93%": {
            transform: "translate(-2px, 2px)",
            filter: "hue-rotate(-45deg) saturate(1.3)",
          },
          "94%": {
            transform: "translate(2px, -2px)",
            filter: "none",
          },
        },
        "glitch-text": {
          "0%, 100%": {
            "text-shadow": "none",
          },
          "1%": {
            "text-shadow": "-2px 0 hsl(0 80% 50%), 2px 0 hsl(0 90% 60%)",
          },
          "2%": {
            "text-shadow": "2px 0 hsl(0 80% 50%), -2px 0 hsl(0 90% 60%)",
          },
          "3%": {
            "text-shadow": "none",
          },
        },
        flicker: {
          "0%, 100%": { opacity: "1" },
          "90%": { opacity: "1" },
          "91%": { opacity: "0.7" },
          "92%": { opacity: "1" },
          "93%": { opacity: "0.85" },
          "94%": { opacity: "1" },
          "95%": { opacity: "0.9" },
          "96%": { opacity: "1" },
        },
        "corrupted-pulse": {
          "0%, 100%": {
            "box-shadow": "0 0 10px hsl(0 65% 40% / 0.25), 0 0 20px hsl(0 55% 30% / 0.15)",
          },
          "50%": {
            "box-shadow":
              "0 0 15px hsl(0 75% 45% / 0.35), 0 0 30px hsl(0 65% 35% / 0.2), 0 0 45px hsl(0 55% 25% / 0.1)",
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
        "blood-drip": {
          "0%, 100%": {
            height: "0",
            opacity: "0",
          },
          "50%": {
            height: "10px",
            opacity: "1",
          },
          "80%": {
            height: "15px",
            opacity: "0.5",
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
            filter: "brightness(1) saturate(1)",
          },
          "50%": {
            filter: "brightness(1.15) saturate(1.3)",
          },
        },
        // Heretek Enhanced Animations
        "binary-flicker": {
          "0%, 100%": { opacity: "1" },
          "50%": { opacity: "0.95" },
          "52%": { opacity: "1" },
          "54%": { opacity: "0.97" },
        },
        "circuit-flow": {
          "0%": { transform: "translateX(-100%)" },
          "100%": { transform: "translateX(100%)" },
        },
        "spirit-pulse": {
          "0%, 100%": { opacity: "0.4", transform: "scale(1)" },
          "50%": { opacity: "0.7", transform: "scale(1.02)" },
        },
        "stream-scroll": {
          "0%": { transform: "translateY(0)" },
          "100%": { transform: "translateY(20px)" },
        },
        "forge-pulse": {
          "0%, 100%": {
            "box-shadow": "0 0 10px hsl(0 70% 50% / 0.35), 0 0 20px hsl(0 60% 40% / 0.25)",
          },
          "50%": {
            "box-shadow":
              "0 0 15px hsl(0 80% 55% / 0.45), 0 0 30px hsl(0 70% 45% / 0.35), 0 0 45px hsl(0 60% 35% / 0.2)",
          },
        },
        "blood-drift": {
          "0%": { transform: "translateY(0) rotate(0deg)" },
          "100%": { transform: "translateY(-100px) rotate(360deg)" },
        },
        "heretek-shimmer": {
          "0%": { backgroundPosition: "-200% 0" },
          "100%": { backgroundPosition: "200% 0" },
        },
        "static-flash": {
          "0%, 95%, 100%": { opacity: "0" },
          "96%": { opacity: "0.08" },
          "97%": { opacity: "0" },
          "98%": { opacity: "0.05" },
          "99%": { opacity: "0" },
        },
        "terminal-flicker": {
          "0%, 100%": { opacity: "1" },
          "50%": { opacity: "0.98" },
        },
        "void-pulse": {
          "0%, 100%": {
            "box-shadow": "0 0 20px hsl(0 0% 0% / 0.5), inset 0 0 20px hsl(0 0% 0% / 0.3)",
          },
          "50%": {
            "box-shadow": "0 0 40px hsl(0 0% 5% / 0.6), inset 0 0 30px hsl(0 0% 3% / 0.4)",
          },
        },
      },
      animation: {
        "accordion-down": "accordion-down 0.2s ease-out",
        "accordion-up": "accordion-up 0.2s ease-out",
        shine: "shine 8s ease-in-out infinite",
        gradient: "gradient 8s linear infinite",
        // Heretek Animations
        glitch: "glitch 3s infinite",
        "glitch-text": "glitch-text 6s infinite",
        flicker: "flicker 6s infinite",
        "corrupted-pulse": "corrupted-pulse 2.5s ease-in-out infinite",
        "scan-line": "scan-line 6s linear infinite",
        "blood-drip": "blood-drip 3s ease-in-out infinite",
        "metal-shine": "metal-shine 3s ease-in-out infinite",
        "heretic-glow": "heretic-glow 4s ease-in-out infinite",
        // Heretek Enhanced Animations
        "binary-flicker": "binary-flicker 4s infinite",
        "circuit-flow": "circuit-flow 2.5s linear infinite",
        "spirit-pulse": "spirit-pulse 3s ease-in-out infinite",
        "stream-scroll": "stream-scroll 15s linear infinite",
        "forge-pulse": "forge-pulse 2.5s ease-in-out infinite",
        "blood-drift": "blood-drift 25s linear infinite",
        "heretek-shimmer": "heretek-shimmer 3s ease-in-out infinite",
        "static-flash": "static-flash 8s infinite",
        "terminal-flicker": "terminal-flicker 0.1s infinite",
        "void-pulse": "void-pulse 4s ease-in-out infinite",
      },
      backgroundImage: {
        // Heretek Background Patterns
        "blood-gradient": "linear-gradient(135deg, hsl(0 70% 35%) 0%, hsl(0 50% 25%) 50%, hsl(0 60% 30%) 100%)",
        "void-gradient": "linear-gradient(180deg, hsl(0 0% 5%) 0%, hsl(0 0% 3%) 50%, hsl(0 0% 8%) 100%)",
        "steel-surface": "linear-gradient(145deg, hsl(0 5% 12%) 0%, hsl(0 8% 8%) 50%, hsl(0 5% 10%) 100%)",
        "corruption-spread": "linear-gradient(90deg, hsl(0 0% 5%) 0%, hsl(0 60% 30%) 50%, hsl(0 0% 5%) 100%)",
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
          "bg-void-texture": (value: any) => ({
            backgroundImage: `url("${svgToDataUri(
              `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100" height="100"><filter id="void"><feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="4" result="noise"/><feColorMatrix type="saturate" values="0" in="noise" result="void"/></filter><rect width="100" height="100" fill="${value}" style="filter:url(#void)"/></svg>`,
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
  const newVars = Object.fromEntries(Object.entries(allColors).map(([key, val]) => [`--${key}`, val]));
  addBase({
    ":root": newVars,
  });
}

export default config;
