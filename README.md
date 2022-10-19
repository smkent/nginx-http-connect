# nginx-http-connect: Container for nginx with HTTP CONNECT support

[![Build](https://img.shields.io/github/checks-status/smkent/nginx-http-connect/main?label=build)][gh-actions]
[![GitHub stars](https://img.shields.io/github/stars/smkent/nginx-http-connect?style=social)][repo]

# Features

* Support for HTTP CONNECT via [ngx_http_proxy_connect_module][patch]
* Automatic reload when the SSL certificates or config templates change
* Optional mapped host names available as nginx variables
* [`tini`][tini] as `init`

# Usage with docker-compose

Example `docker-compose.yaml`:

```yaml
version: '3.7'

services:
  nginx:
    image: ghcr.io/smkent/nginx-http-connect:latest
    ports:
      - "80:80"
      - "443:443"
    environment:
      # NGINX_INOTIFY_RELOAD: no    # Uncomment to disable reload on config changes
    # extra_hosts:        # Uncomment to map extra host names to nginx variables
    #   gw: host-gateway  # Uncomment to map "$gw" to the Docker host IP
    restart: unless-stopped
    volumes:
      - path/to/certbot/data:/etc/letsencrypt:ro    # Optional
      - path/to/templates:/etc/nginx/templates:ro   # nginx config templates
```

---

Created from [smkent/cookie-docker][cookie-docker] using
[cookiecutter][cookiecutter]

[cookie-docker]: https://github.com/smkent/cookie-docker
[cookiecutter]: https://github.com/cookiecutter/cookiecutter
[gh-actions]: https://github.com/smkent/nginx-http-connect/actions?query=branch%3Amain
[repo]: https://github.com/smkent/nginx-http-connect
[tini]: https://github.com/krallin/tini
[patch]: https://github.com/chobits/ngx_http_proxy_connect_module
