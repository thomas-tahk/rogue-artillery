FROM ubuntu:24.04
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    xvfb xauth libgl1 libgl1-mesa-dri libglx-mesa0 libxcursor1 libxinerama1 libxrandr2 libxi6 \
    libfontconfig1 libasound2t64 libpulse0 libudev1 ca-certificates curl unzip && rm -rf /var/lib/apt/lists/*
ARG GV=4.7.2-stable
RUN curl -fsSL -o /tmp/g.zip https://github.com/godotengine/godot-builds/releases/download/${GV}/Godot_v${GV}_linux.arm64.zip \
 && unzip -q /tmp/g.zip -d /opt && mv /opt/Godot_v${GV}_linux.arm64 /usr/local/bin/godot && rm /tmp/g.zip
ENV LIBGL_ALWAYS_SOFTWARE=1
WORKDIR /work
