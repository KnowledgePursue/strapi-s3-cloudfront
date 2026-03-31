# ============================================
# STAGE 1: Dependencies
# ============================================
FROM node:20-alpine AS deps
RUN apk update && apk add --no-cache build-base gcc autoconf automake zlib-dev libpng-dev vips-dev git

WORKDIR /opt/
COPY package.json package-lock.json ./
RUN npm install -g node-gyp
RUN npm config set fetch-retry-maxtimeout 600000 -g && npm install --prefer-offline

# Instala providers extras sem precisar mexer no sistema de arquivos
# Uso: docker compose build --build-arg EXTRA_DEPS="@strapi/provider-upload-aws-s3@5.40.0"
ARG EXTRA_DEPS=""
RUN if [ -n "$EXTRA_DEPS" ]; then npm install $EXTRA_DEPS; fi

# ============================================
# STAGE 2: Build (com limites de memória para t3.medium)
# ============================================
FROM node:20-alpine AS build
RUN apk update && apk add --no-cache build-base gcc autoconf automake zlib-dev libpng-dev vips-dev git

ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}

# Limita o heap do Node para não explodir a RAM da t3.medium (4GB)
ENV NODE_OPTIONS="--max-old-space-size=1536"

WORKDIR /opt/
COPY --from=deps /opt/node_modules ./node_modules

WORKDIR /opt/app
COPY . .

RUN ln -sf /opt/node_modules /opt/app/node_modules
ENV PATH=/opt/node_modules/.bin:$PATH

RUN npm run build

# ============================================
# STAGE 3: Production image (enxuta)
# ============================================
FROM node:20-alpine
RUN apk add --no-cache vips-dev

ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}

# Limita memória em runtime também
ENV NODE_OPTIONS="--max-old-space-size=1536"

WORKDIR /opt/
COPY --from=build /opt/node_modules ./node_modules

WORKDIR /opt/app
COPY --from=build /opt/app ./

# Remove arquivos desnecessários em produção
RUN rm -rf /opt/app/src /opt/app/.cache

ENV PATH=/opt/node_modules/.bin:$PATH

RUN chown -R node:node /opt/app
USER node
EXPOSE 1337
CMD ["npm", "run", "start"]
