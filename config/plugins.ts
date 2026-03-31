export default ({ env }: { env: any }) => ({
  upload: {
    config: {
      provider: 'aws-s3',
      providerOptions: {
        s3Options: {
          credentials: {
            accessKeyId: env('AWS_ACCESS_KEY_ID'),
            secretAccessKey: env('AWS_ACCESS_SECRET'),
          },
          region: env('AWS_REGION'),
          params: {
            Bucket: env('AWS_BUCKET'),
            ACL: null, // bucket privado — null impede o envio do header ACL para a AWS
          },
        },
        baseUrl: env('CDN_URL'), // URL do CloudFront ex: https://xxxx.cloudfront.net
        rootPath: env('CDN_ROOT_PATH', ''), // opcional, ex: 'media'
      },
      actionOptions: {
        upload: {},
        uploadStream: {},
        delete: {},
      },
    },
  },
});
