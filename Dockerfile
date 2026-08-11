# Isolated install + run for TanStack Start (pnpm).
# Dev:   docker compose up dev
# Prod:  docker compose up app

ARG NODE_VERSION=22

FROM node:${NODE_VERSION}-bookworm-slim AS base
ENV PNPM_HOME="/pnpm" \
    PATH="/pnpm:$PATH" \
    CI=true
RUN corepack enable && corepack prepare pnpm@11.20.0 --activate
WORKDIR /app

FROM base AS deps
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile

FROM deps AS dev
COPY . .
EXPOSE 8080
# Bind 0.0.0.0 so the port is reachable from the host
CMD ["pnpm", "exec", "vite", "dev", "--port", "8080", "--host", "0.0.0.0"]

FROM deps AS build
COPY . .
RUN pnpm build

FROM node:${NODE_VERSION}-bookworm-slim AS app
ENV NODE_ENV=production \
    HOST=0.0.0.0 \
    PORT=3000
WORKDIR /app

RUN groupadd --system --gid 1001 nodejs \
  && useradd --system --uid 1001 --gid nodejs appuser

COPY --from=build --chown=appuser:nodejs /app/.output ./.output

USER appuser
EXPOSE 3000
CMD ["node", ".output/server/index.mjs"]
