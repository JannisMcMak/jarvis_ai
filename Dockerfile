# syntax=docker/dockerfile:1
FROM ghcr.io/astral-sh/uv:python3.12-trixie

# System deps:
#   ffmpeg / libsndfile1 -> audio decoding for faster-whisper / RealtimeSTT
#   portaudio19-dev      -> RealtimeSTT pulls in pyaudio, which needs this to build
#   build-essential      -> in case any dep needs to compile a wheel for your arch
#   curl                 -> handy for debugging/healthchecks inside the container
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ffmpeg \
    libsndfile1 \
    portaudio19-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app/server

COPY . .

RUN uv sync --locked

# Entrypoint only falls back to the example config at CONTAINER START, and
# only if neither a real config/server.yaml was baked in nor mounted via
# -v. It never fails the build if config/server.example.yaml is missing -
# see entrypoint.sh.
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Pre-download the Whisper model into the image so `docker run` doesn't
# stall 60-90s on first start. Override with --build-arg WHISPER_MODEL=...
# to match whatever you set in server.yaml. Remove this RUN if you'd rather
# cache the model on a mounted volume instead of inside the image.
ARG WHISPER_MODEL=small.en
RUN uv run python -c "from faster_whisper import WhisperModel; WhisperModel('${WHISPER_MODEL}')"

ENV PYTHONUNBUFFERED=1

# HUD (https) + websocket both served on this port per the setup guide
EXPOSE 8765

# TLS certs, config, and secrets should NOT be baked into the image:
#   docker run \
#     -p 8765:8765 \
#     -v $(pwd)/config/server.yaml:/app/server/config/server.yaml:ro \
#     --env-file ~/.hermes/.env \
#     jarvis-voice-server
VOLUME ["/app/server/config"]

CMD ["uv", "run", "server/server.py"]