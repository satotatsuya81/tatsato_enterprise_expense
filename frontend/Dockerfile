# Multi-stage Dockerfile for Next.js frontend

FROM node:18-alpine AS base

# Install dependencies only when needed
FROM base AS deps
# Check https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine to understand why libc6-compat might be needed.
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Copy package files
COPY package.json package-lock.json* ./

# Install dependencies
RUN npm ci --only=production

# Development stage
FROM base AS development

# Install development dependencies
RUN apk add --no-cache libc6-compat curl

WORKDIR /app

# Create app user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# Copy package files
COPY package.json package-lock.json* ./

# Install all dependencies (including dev)
RUN npm ci

# Copy source code
COPY . .

# Change ownership
RUN chown -R nextjs:nodejs /app

# Switch to non-root user
USER nextjs

# Expose port
EXPOSE 3000

# Set environment variable for Next.js telemetry
ENV NEXT_TELEMETRY_DISABLED 1

# Command for development with hot reload
CMD ["npm", "run", "dev"]

# Builder stage
FROM base AS builder
WORKDIR /app

# Copy dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules

# Copy source code
COPY . .

# Generate build
RUN npm run build

# Production stage
FROM base AS production

# Install curl for health checks
RUN apk add --no-cache curl

WORKDIR /app

# Create app user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# Set the correct permission for prerender cache
RUN mkdir .next
RUN chown nextjs:nodejs .next

# Copy built application from builder stage
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=builder --chown=nextjs:nodejs /app/public ./public

# Switch to non-root user
USER nextjs

# Expose port
EXPOSE 3000

# Set environment variables
ENV PORT 3000
ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/api/health || exit 1

# Run the application
CMD ["node", "server.js"]