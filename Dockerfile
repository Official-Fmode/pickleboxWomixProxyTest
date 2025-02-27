FROM node:16-alpine as builder

# Install dependencies
RUN apk add git python3 make gcc musl-dev libc-dev g++

# Copy project files
COPY . /opt/womginx

WORKDIR /opt/womginx

# Ensure git is properly initialized
RUN rm -rf .git && git init

WORKDIR /opt/womginx/public
RUN rm -rf wombat && git submodule add https://github.com/webrecorder/wombat

WORKDIR /opt/womginx/public/wombat
# Locking the Wombat version due to WebSocket issues
RUN git checkout 78813ad

RUN npm install --legacy-peer-deps && npm run build-prod

# Delete unnecessary files to reduce image size
RUN mv dist .. && rm -rf * .git && mv ../dist/ .

# Modify nginx.conf
WORKDIR /opt/womginx

# Grant execute permissions before running the script
RUN chmod +x docker-sed.sh && ./docker-sed.sh

FROM nginx:stable-alpine

# Default environment variables
ENV PORT=80
# Uncomment to enable safe browsing
# ENV SAFE_BROWSING=1

# Copy files from builder stage
COPY --from=builder /opt/womginx /opt/womginx

# Use the modified nginx.conf
RUN cp /opt/womginx/nginx.conf /etc/nginx/nginx.conf

# Ensure docker-entrypoint.sh is executable
RUN chmod +x /opt/womginx/docker-entrypoint.sh

# Verify nginx.conf syntax
RUN nginx -t

CMD ["/opt/womginx/docker-entrypoint.sh"]
