# Serves the built website (/) and workspace (/app/) from one small image.
# Build the bundle first:  tool/build.sh   (writes ./dist)
# Then:                    docker build -t omorals .
#                          docker run -p 8080:80 omorals
FROM nginx:1.27-alpine

LABEL org.opencontainers.image.title="OMorals Media"
LABEL org.opencontainers.image.description="OMorals Media website and team workspace (static build served by nginx)."
LABEL org.opencontainers.image.source="https://github.com/ChandraChaan/omorals"
LABEL org.opencontainers.image.url="https://omorals.web.app"

COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY dist/ /usr/share/nginx/html/

EXPOSE 80
