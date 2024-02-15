FROM debian:12.5

ENV CLEANIMAGE_VERSION 2.0
ENV CLEANIMAGE_URL https://raw.githubusercontent.com/lhns/docker-cleanimage/$CLEANIMAGE_VERSION/cleanimage

ENV JQ_VERSION 1.7.1
ENV JQ_URL https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-linux-amd64

RUN apt-get update \
 && apt-get install -y \
      ca-certificates \
      curl \
      gnupg \
 && install -m 0755 -d /etc/apt/keyrings \
 && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
 && chmod a+r /etc/apt/keyrings/docker.gpg \
 && echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null \
 && apt-get update \
 && apt-get install -y \
      docker-ce-cli \
 && curl -sSfLo /usr/bin/jq -- "$JQ_URL" \
 && chmod +x /usr/bin/jq \
 && curl -sSfL -- "$CLEANIMAGE_URL" > "/usr/local/bin/cleanimage" \
 && chmod +x "/usr/local/bin/cleanimage" \
 && cleanimage

COPY swarm-dind.sh /

ENTRYPOINT ["/swarm-dind.sh"]
