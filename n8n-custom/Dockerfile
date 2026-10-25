# Stage 1: get the tools from a known Alpine image
FROM alpine:3.19 AS tools
RUN apk add --no-cache python3 py3-pip curl ffmpeg
RUN pip install --no-cache-dir --break-system-packages yt-dlp

# Stage 2: n8n with copied binaries
FROM n8nio/n8n:latest
USER root

COPY --from=tools /usr/bin/python3       /usr/bin/python3
COPY --from=tools /usr/lib/python3*      /usr/lib/
COPY --from=tools /usr/bin/ffmpeg        /usr/bin/ffmpeg
COPY --from=tools /usr/bin/ffprobe       /usr/bin/ffprobe
COPY --from=tools /usr/bin/yt-dlp        /usr/bin/yt-dlp
COPY --from=tools /usr/bin/curl          /usr/bin/curl
COPY --from=tools /usr/lib/libcurl*      /usr/lib/

USER node