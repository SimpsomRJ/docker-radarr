FROM linuxserver/radarr:latest
RUN apk update && \
      apk add -U --no-cache \
          mkvtoolnix && \
      apk --no-cache upgrade
RUN mkdir /scripts
COPY scripts/ /scripts
RUN chmod 755 /scripts/*.sh
