/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  experimental: {
    appDir: true,
  },
  env: {
    JULIAOS_API_URL: process.env.JULIAOS_API_URL || 'http://localhost:8052/api/v1',
  },
  async rewrites() {
    return [
      {
        source: '/api/:path*',
        destination: `${process.env.JULIAOS_API_URL || 'http://localhost:8052/api/v1'}/:path*`,
      },
    ]
  },
}

module.exports = nextConfig