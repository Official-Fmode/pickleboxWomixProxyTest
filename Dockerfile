FROM node:16-alpine as builder

RUN apk add --no-cache git python3 make gcc musl-dev libc-dev g++
COPY . /opt/womginx

WORKDIR /opt/womginx
RUN rm -rf .git && git init
WORKDIR /opt/womginx/public
RUN rm -rf wombat && git submodule add https://github.com/webrecorder/wombat
WORKDIR /opt/womginx/public/wombat
RUN git checkout 78813ad

RUN npm install --legacy-peer-deps
RUN npm run build-prod

# Ensure permission for scripts
WORKDIR /opt/womginx
RUN chmod +x docker-sed.sh docker-entrypoint.sh
RUN ./docker-sed.sh

FROM nginx:stable-alpine

ENV PORT=80

COPY --from=builder /opt/womginx /opt/womginx
RUN cp /opt/womginx/nginx.conf /etc/nginx/nginx.conf

RUN nginx -t

CMD ["/opt/womginx/docker-entrypoint.sh"]
