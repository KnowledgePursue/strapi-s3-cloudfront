import type { Core } from '@strapi/strapi';

const cdnHost = process.env.CDN_URL ? new URL(process.env.CDN_URL).host : '';

const config: Core.Config.Middlewares = [
  'strapi::errors',
  {
    name: 'strapi::security',
    config: {
      contentSecurityPolicy: {
        useDefaults: true,
        directives: {
          'connect-src': ["'self'", 'https:'],
          'img-src': ["'self'", 'data:', 'blob:', 'dl.airtable.com', cdnHost],
          'media-src': ["'self'", 'data:', 'blob:', 'dl.airtable.com', cdnHost],
          upgradeInsecureRequests: null,
        },
      },
    },
  },
  'strapi::cors',
  'strapi::poweredBy',
  'strapi::logger',
  'strapi::query',
  'strapi::body',
  'strapi::session',
  'strapi::favicon',
  'strapi::public',
];

export default config;
