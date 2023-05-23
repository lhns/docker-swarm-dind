FROM debian

ENV CLEANIMAGE_VERSION 2.0
ENV CLEANIMAGE_URL https://raw.githubusercontent.com/lhns/docker-cleanimage/$CLEANIMAGE_VERSION/cleanimage

ENV GOJQ_VERSION v0.12.12
ENV GOJQ_FILE gojq_${GOJQ_VERSION}_linux_amd64
ENV GOJQ_URL https://github.com/itchyny/gojq/releases/download/$GOJQ_VERSION/${GOJQ_FILE}.tar.gz

RUN apt-get update \
 && apt-get install -y \
      ca-certificates \
      curl \
      gnupg \
 && install -m 0755 -d /etc/apt/keyrings \
 && curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
 && chmod a+r /etc/apt/keyrings/docker.gpg \
 && echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null \
 && apt-get update \
 && apt-get install -y \
      docker-ce-cli \
 && curl -sSfL -- "$GOJQ_URL" | tar -xzf - \
 && mv "$GOJQ_FILE/gojq" /usr/bin/jq \
 && rm -Rf "$GOJQ_FILE" \
 && curl -sSfL -- "$CLEANIMAGE_URL" > "/usr/local/bin/cleanimage" \
 && chmod +x "/usr/local/bin/cleanimage" \
 && cleanimage

COPY swarm-dind.sh /

CMD /swarm-dind.sh
