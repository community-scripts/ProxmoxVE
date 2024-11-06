/** @type {import('next').NextConfig} */
const nextConfig = {
  webpack: (config) => {
    config.resolve.alias.canvas = false;

    return config;
  },
  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: "**",
      },
    ],
  },

  env: {
    BASE_PATH: "ProxmoxVE",
  },

  output: "export",
  basePath: `/ProxmoxVE`,
};

export default nextConfig;
