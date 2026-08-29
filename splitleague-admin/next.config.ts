import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  // Nothing exotic. Every page in this tool is rendered on the server on each request,
  // because the whole point is to show what the database says right now.
  reactStrictMode: true,

  // This project sits inside the splitleague repo, which has its own package-lock.json at
  // the root. Without this Next walks up, finds that lockfile and decides the workspace root
  // is the whole repo - which makes it trace files from splitleague-server and the Flutter
  // app into the build. Pinning it here keeps the build to this directory.
  outputFileTracingRoot: __dirname,
};

export default nextConfig;
