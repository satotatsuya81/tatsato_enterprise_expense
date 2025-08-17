/** @type {import('next').NextConfig} */
const nextConfig = {
  // App Router configuration
  experimental: {
    // Enable the new App Router
    appDir: true,
    // Server Components optimization
    serverComponentsExternalPackages: ['@prisma/client'],
  },

  // Compiler options
  compiler: {
    // Remove console logs in production
    removeConsole: process.env.NODE_ENV === 'production' ? { exclude: ['error'] } : false,
  },

  // Environment variables
  env: {
    CUSTOM_KEY: process.env.CUSTOM_KEY,
  },

  // Public runtime config
  publicRuntimeConfig: {
    API_URL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8001',
  },

  // Image optimization
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'images.unsplash.com',
      },
      {
        protocol: 'https',
        hostname: 'avatars.githubusercontent.com',
      },
    ],
  },

  // Internationalization (i18n) - placeholder for future
  // i18n: {
  //   locales: ['en', 'ja'],
  //   defaultLocale: 'en',
  // },

  // Security headers
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          {
            key: 'X-Frame-Options',
            value: 'DENY',
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
          {
            key: 'Referrer-Policy',
            value: 'strict-origin-when-cross-origin',
          },
          {
            key: 'Permissions-Policy',
            value: 'camera=(), microphone=(), geolocation=()',
          },
        ],
      },
    ]
  },

  // Rewrites for API proxy (development)
  async rewrites() {
    if (process.env.NODE_ENV === 'development') {
      return [
        {
          source: '/api/auth/:path*',
          destination: 'http://localhost:8001/api/v1/auth/:path*',
        },
        {
          source: '/api/users/:path*',
          destination: 'http://localhost:8001/api/v1/users/:path*',
        },
      ]
    }
    return []
  },

  // Bundle analyzer (development)
  webpack: (config, { buildId, dev, isServer, defaultLoaders, nextRuntime, webpack }) => {
    // Bundle analyzer
    if (process.env.ANALYZE === 'true') {
      const { BundleAnalyzerPlugin } = require('@next/bundle-analyzer')({
        enabled: true,
      })
      config.plugins.push(
        new BundleAnalyzerPlugin({
          analyzerMode: 'static',
          openAnalyzer: false,
        })
      )
    }

    // Optimize builds
    if (!dev && !isServer) {
      config.resolve.alias = {
        ...config.resolve.alias,
        '@/components': require('path').resolve(__dirname, 'src/components'),
        '@/lib': require('path').resolve(__dirname, 'src/lib'),
        '@/types': require('path').resolve(__dirname, 'src/types'),
      }
    }

    return config
  },

  // Output configuration
  output: 'standalone',

  // Performance optimization
  poweredByHeader: false,
  generateEtags: false,
  compress: true,

  // Redirects
  async redirects() {
    return [
      {
        source: '/login',
        destination: '/auth/login',
        permanent: true,
      },
      {
        source: '/register',
        destination: '/auth/register',
        permanent: true,
      },
    ]
  },
}

module.exports = nextConfig