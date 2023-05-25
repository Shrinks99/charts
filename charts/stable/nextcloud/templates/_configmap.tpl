{{/* Define the configmap */}}
{{- define "nextcloud.configmaps" -}}

{{- $hosts := "" -}}
{{- if .Values.ingress.main.enabled -}}
  {{- range .Values.ingress -}}
    {{- range $index, $host := .hosts -}}
      {{- if $index -}}
        {{- $hosts = ( printf "%v %v" $hosts $host.host ) -}}
      {{- else -}}
        {{- $hosts = ( printf "%s" $host.host ) -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- $aliasgroup1 := (  printf "http://%s" ( .Values.nextcloud.AccessIP | default ( printf "%v-%v" .Release.Name "nextcloud" ) ) ) -}}
{{- if .Values.ingress.main.enabled -}}
  {{- with (first .Values.ingress.main.hosts) -}}
  {{- $aliasgroup1 = (  printf "https://%s" .host ) -}}
  {{- end -}}
{{- end }}
php-tune:
  enabled: true
  data:
    zz-tune.conf: |
      [www]
      pm.max_children = {{ .Values.nextcloud.php.pm_max_children }}
      pm.start_servers = {{ .Values.nextcloud.php.pm_start_servers }}
      pm.min_spare_servers = {{ .Values.nextcloud.php.pm_min_spare_servers }}}
      pm.max_spare_servers = {{ .Values.nextcloud.php.pm_max_spare_servers }}

redis-session:
  enabled: true
  data:
    redis-session.ini: |
       session.save_path = {{ printf "tcp://%v?auth=%v" .Values.redis.creds.plainport .Values.redis.creds.redisPassword | quote }}
       redis.session.locking_enabled = 1
       redis.session.lock_retries = -1
       redis.session.lock_wait_time = 10000

hpb-config:
  enabled: true
  data:
    NEXTCLOUD_URL: {{ printf "%v:%v" (include "tc.v1.common.lib.chart.names.fullname" $) .Values.service.main.ports.main.port }}
    METRICS_PORT: {{ .Values.service.notify.ports.metrics.port | quote }}

nextcloud-config:
  enabled: true
  data:
    {{/* Database */}}
    POSTGRES_DB: {{ .Values.cnpg.main.database | quote }}
    POSTGRES_USER: {{ .Values.cnpg.main.user | quote }}
    POSTGRES_PASSWORD: {{ .Values.cnpg.main.creds.password | trimAll "\"" }}
    POSTGRES_HOST: {{ .Values.cnpg.main.creds.host | trimAll "\"" }}
    {{/* Redis */}}
    NX_REDIS_HOST: {{ .Values.redis.creds.plainhost | trimAll "\"" }}
    NX_REDIS_PASS: {{ .Values.redis.creds.redisPassword | trimAll "\"" }}

    {{/* Nextcloud INITIAL credentials */}}
    NEXTCLOUD_ADMIN_USER: {{ .Values.nextcloud.credentials.initialAdminUser | quote }}
    NEXTCLOUD_ADMIN_PASSWORD: {{ .Values.nextcloud.credentials.initialAdminPassword | quote }}

    {{/* PHP Variables */}}
    PHP_MEMORY_LIMIT: {{ .Values.nextcloud.php.memory_limit | quote }}
    PHP_UPLOAD_LIMIT: {{ .Values.nextcloud.php.upload_limit | quote }}

    {{/* Notify Push */}}
    NX_NOTIFY_PUSH: {{ .Values.nextcloud.notify_push.enabled | quote }}
    # TODO: Verify if this generates the correct url
    NX_NOTIFY_PUSH_ENDPOINT: {{ .Values.chartContext.APPURL }}/push

    {{/* Previews */}}
    NX_PREVIEWS: {{ .Values.nextcloud.previews.enabled | quote }}
    {{- if not (deepEqual .Values.nextcloud.previews.providers (uniq .Values.nextcloud.previews.providers)) }}
      {{- fail (printf "Nextcloud - Expected preview providers to be unique but got [%v]" .Values.nextcloud.previews.providers) }}
    {{- end }}
    NX_PREVIEW_PROVIDERS: {{ join " " .Values.nextcloud.previews.providers }}
    NX_PREVIEW_MAX_X: {{ .Values.nextcloud.previews.max_x | quote }}
    NX_PREVIEW_MAX_Y: {{ .Values.nextcloud.previews.max_y | quote }}
    NX_PREVIEW_MAX_MEMORY: {{ .Values.nextcloud.previews.max_memory | quote }}
    NX_PREVIEW_MAX_FILESIZE_IMAGE: {{ .Values.nextcloud.previews.max_filesize_image | quote }}
    NX_JPEG_QUALITY: {{ .Values.nextcloud.previews.jpeg_quality | quote }}
    NX_PREVIEW_SQUARE_SIZES: {{ .Values.nextcloud.previews.square_sizes | quote }}
    NX_PREVIEW_WIDTH_SIZES: {{ .Values.nextcloud.previews.width_sizes | quote }}
    NX_PREVIEW_HEIGHT_SIZES: {{ .Values.nextcloud.previews.height_sizes | quote }}

    {{/* Imaginary */}}
    NX_IMAGINARY: {{ and .Values.nextcloud.previews.enabled .Values.nextcloud.previews.imaginary | quote }}
    NX_IMAGINARY_URL: http://imaginary:9000 # TODO: Update to svc name

    {{/* Expirations */}}
    NX_ACTIVITY_EXPIRE_DAYS: {{ .Values.nextcloud.expirations.activity_expire_days | quote }}
    NX_TRASH_RETENTION: {{ .Values.nextcloud.expirations.trash_retention | quote }}
    NX_VERSIONS_RETENTION: {{ .Values.nextcloud.expirations.versions_retention | quote }}

    {{/* General */}}
    NX_RUN_OPTIMIZE: {{ .Values.nextcloud.general.run_optimize | quote }}
    NX_DEFAULT_PHONE_REGION: {{ .Values.nextcloud.general.default_phone_region | quote }}

    {{/* Files */}}
    NX_SHARED_FOLDER_NAME: {{ .Values.nextcloud.files.shared_folder_name | quote }}
    NX_MAX_CHUNKSIZE: {{ .Values.nextcloud.files.max_chunksize | quote }}

    {{/* Logging */}}
    NX_LOG_LEVEL: {{ .Values.nextcloud.logging.log_level | quote }}
    NX_LOG_FILE: {{ .Values.nextcloud.logging.log_file | quote }}
    NX_LOG_FILE_AUDIT: {{ .Values.nextcloud.logging.log_file_audit | quote }}
    NX_LOG_DATE_FORMAT: {{ .Values.nextcloud.logging.log_date_format | quote }}
    NX_LOG_TIMEZONE: {{ .Values.TZ | quote }}

    {{/* ClamAV */}}
    NX_CLAMAV: {{ .Values.nextcloud.clamav.enabled | quote }}
    NX_CLAMAV_HOST:  # TODO: Update to svc name
    NX_CLAMAV_PORT: # TODO: Update to svc port
    NX_CLAMAV_STREAM_MAX_LENGTH: {{ .Values.nextcloud.clamav.stream_max_length | quote }}
    NX_CLAMAV_FILE_MAX_SIZE: {{ .Values.nextcloud.clamav.file_max_size | quote }}
    NX_CLAMAV_INFECTED_ACTION: {{ .Values.nextcloud.clamav.infected_action | quote }}

    {{/* Collabora */}}
    NX_COLLABORA: {{ .Values.nextcloud.collabora.enabled | quote }}
    NX_COLLABORA_URL: # TODO: Update to ingress name
    # Haven't managed to get this to work more strict
    NX_COLLABORA_ALLOWLIST: 0.0.0.0/0

    {{/* URLs TODO: */}}
    NX_OVERWRITE_HOST: {{ .Values.chartContext.APPURL | quote }}
    NX_OVERWRITE_PROTOCOL: https
    NX_OVERWRITE_CLI_URL: {{ .Values.chartContext.APPURL | quote }}
    # TODO: Verify what is needed
    NX_TRUSTED_DOMAINS: |
      127.0.0.1
      {{ $hosts }}
      kube.internal.healthcheck
      {{ printf "%s-nextcloud" .Release.Name }}
      {{ printf "%v-nextcloud-backend" .Release.Name }}
      {{ printf "%v-nextcloud:%v" .Release.Name .Values.service.main.ports.main.port }}
      {{ printf "127.0.0.1:%v" .Values.service.main.ports.main.port }}
      {{ .Values.nextcloud.AccessIP | default "localhost" }}
    # TODO: Verify what is needed
    NX_TRUSTED_PROXIES: |
      localhost
      127.0.0.1
      {{ .Values.chartContext.podCIDR }}
      {{ .Values.chartContext.svcCIDR }}

nginx-config:
  enabled: true
  data:
    nginx.conf: |
      worker_processes auto;

      error_log  /var/log/nginx/error.log warn;

      # Set to /tmp so it can run as non-root
      pid        /tmp/nginx.pid;

      events {
          worker_connections  1024;
      }

      http {
          # Set to /tmp so it can run as non-root
          client_body_temp_path /tmp/nginx/client_temp;
          proxy_temp_path       /tmp/nginx/proxy_temp_path;
          fastcgi_temp_path     /tmp/nginx/fastcgi_temp;
          uwsgi_temp_path       /tmp/nginx/uwsgi_temp;
          scgi_temp_path        /tmp/nginx/scgi_temp;
          proxy_cache_path      /tmp/nginx/cache

          include       /etc/nginx/mime.types;
          default_type  application/octet-stream;

          log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                            '$status $body_bytes_sent "$http_referer" '
                            '"$http_user_agent" "$http_x_forwarded_for"';

          access_log  /var/log/nginx/access.log  main;

          sendfile        on;
          #tcp_nopush     on;

          # Prevent nginx HTTP Server Detection
          server_tokens   off;

          keepalive_timeout  65;

          #gzip  on;

          upstream php-handler {
              server 127.0.0.1:9000;
          }

          server {
              listen {{ .Values.service.main.ports.main.port }};
              absolute_redirect off;

              # HSTS settings
              # WARNING: Only add the preload option once you read about
              # the consequences in https://hstspreload.org/. This option
              # will add the domain to a hardcoded list that is shipped
              # in all major browsers and getting removed from this list
              # could take several months.
              #add_header Strict-Transport-Security "max-age=15768000; includeSubDomains; preload;" always;

              # set max upload size
              client_max_body_size {{ .Values.nextcloud.php.upload_limit | default "512M" }};
              fastcgi_buffers 64 4K;

              # Enable gzip but do not remove ETag headers
              gzip on;
              gzip_vary on;
              gzip_comp_level 4;
              gzip_min_length 256;
              gzip_proxied expired no-cache no-store private no_last_modified no_etag auth;
              gzip_types application/atom+xml application/javascript application/json application/ld+json application/manifest+json application/rss+xml application/vnd.geo+json application/vnd.ms-fontobject application/x-font-ttf application/x-web-app-manifest+json application/xhtml+xml application/xml font/opentype image/bmp image/svg+xml image/x-icon text/cache-manifest text/css text/plain text/vcard text/vnd.rim.location.xloc text/vtt text/x-component text/x-cross-domain-policy;

              # Pagespeed is not supported by Nextcloud, so if your server is built
              # with the `ngx_pagespeed` module, uncomment this line to disable it.
              #pagespeed off;

              # HTTP response headers borrowed from Nextcloud `.htaccess`
              add_header Referrer-Policy                      "no-referrer"       always;
              add_header X-Content-Type-Options               "nosniff"           always;
              add_header X-Download-Options                   "noopen"            always;
              add_header X-Frame-Options                      "SAMEORIGIN"        always;
              add_header X-Permitted-Cross-Domain-Policies    "none"              always;
              add_header X-Robots-Tag                         "noindex, nofollow" always;
              add_header X-XSS-Protection                     "1; mode=block"     always;

              # Remove X-Powered-By, which is an information leak
              fastcgi_hide_header X-Powered-By;

              # Path to the root of your installation
              root /var/www/html;

              # Specify how to handle directories -- specifying `/index.php$request_uri`
              # here as the fallback means that Nginx always exhibits the desired behaviour
              # when a client requests a path that corresponds to a directory that exists
              # on the server. In particular, if that directory contains an index.php file,
              # that file is correctly served; if it doesn't, then the request is passed to
              # the front-end controller. This consistent behaviour means that we don't need
              # to specify custom rules for certain paths (e.g. images and other assets,
              # `/updater`, `/ocm-provider`, `/ocs-provider`), and thus
              # `try_files $uri $uri/ /index.php$request_uri`
              # always provides the desired behaviour.
              index index.php index.html /index.php$request_uri;

              # Rule borrowed from `.htaccess` to handle Microsoft DAV clients
              location = / {
                  if ( $http_user_agent ~ ^DavClnt ) {
                      return 302 /remote.php/webdav/$is_args$args;
                  }
              }

              location = /robots.txt {
                  allow all;
                  log_not_found off;
                  access_log off;
              }

              # Make a regex exception for `/.well-known` so that clients can still
              # access it despite the existence of the regex rule
              # `location ~ /(\.|autotest|...)` which would otherwise handle requests
              # for `/.well-known`.
              location ^~ /.well-known {
                  # The rules in this block are an adaptation of the rules
                  # in `.htaccess` that concern `/.well-known`.

                  location = /.well-known/carddav { return 301 /remote.php/dav/; }
                  location = /.well-known/caldav  { return 301 /remote.php/dav/; }

                  # According to the documentation these two lines are not necessary,
                  # but some users are still receiving errors
                  location = /.well-known/webfinger   { return 301 /index.php$uri; }
                  location = /.well-known/nodeinfo   { return 301 /index.php$uri; }

                  location /.well-known/acme-challenge    { try_files $uri $uri/ =404; }
                  location /.well-known/pki-validation    { try_files $uri $uri/ =404; }

                  # Let Nextcloud's API for `/.well-known` URIs handle all other
                  # requests by passing them to the front-end controller.
                  return 301 /index.php$request_uri;
              }

              # Rules borrowed from `.htaccess` to hide certain paths from clients
              location ~ ^/(?:build|tests|config|lib|3rdparty|templates|data)(?:$|/)  { return 404; }
              location ~ ^/(?:\.|autotest|occ|issue|indie|db_|console)                { return 404; }

              # Ensure this block, which passes PHP files to the PHP process, is above the blocks
              # which handle static assets (as seen below). If this block is not declared first,
              # then Nginx will encounter an infinite rewriting loop when it prepends `/index.php`
              # to the URI, resulting in a HTTP 500 error response.
              location ~ \.php(?:$|/) {
                  # Required for legacy support
                  rewrite ^/(?!index|remote|public|cron|core\/ajax\/update|status|ocs\/v[12]|updater\/.+|oc[ms]-provider\/.+|.+\/richdocumentscode\/proxy) /index.php$request_uri;

                  fastcgi_split_path_info ^(.+?\.php)(/.*)$;
                  set $path_info $fastcgi_path_info;

                  try_files $fastcgi_script_name =404;

                  include fastcgi_params;
                  fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                  fastcgi_param PATH_INFO $path_info;
                  #fastcgi_param HTTPS on;

                  fastcgi_param modHeadersAvailable true;         # Avoid sending the security headers twice
                  fastcgi_param front_controller_active true;     # Enable pretty urls
                  fastcgi_pass php-handler;

                  fastcgi_intercept_errors on;
                  fastcgi_request_buffering off;

                  proxy_send_timeout 3600s;
                  proxy_read_timeout 3600s;
                  fastcgi_send_timeout 3600s;
                  fastcgi_read_timeout 3600s;
              }

              location ~ \.(?:css|js|svg|gif)$ {
                  try_files $uri /index.php$request_uri;
                  expires 6M;         # Cache-Control policy borrowed from `.htaccess`
                  access_log off;     # Optional: Don't log access to assets
              }

              location ~ \.woff2?$ {
                  try_files $uri /index.php$request_uri;
                  expires 7d;         # Cache-Control policy borrowed from `.htaccess`
                  access_log off;     # Optional: Don't log access to assets
              }

              # Rule borrowed from `.htaccess`
              location /remote {
                  return 301 /remote.php$request_uri;
              }

              location / {
                  try_files $uri $uri/ /index.php$request_uri;
              }
          }
      }

collabora-config:
  enabled: true
  data:
    aliasgroup1: {{ $aliasgroup1 }}
{{- end -}}
