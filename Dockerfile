FROM alpine
MAINTAINER Andy Savage <andy@savage.hk>

VOLUME ["/etc/mopidy"]

ENV MOPIDY_CONFIG_FILES="/etc/mopidy/mopidy.conf"
ENV MOPIDY_PYTHON_PLUGINS="\
MopidyCLI \
Mopidy-BeetsLocal \
Mopidy-RNZ \
Mopidy-Tachikoma \
Mopidy-Party \
Mopidy-Podcast \
Mopidy-WebSettings \
Mopidy-Dirble \
Mopidy-Mobile \
Mopidy-PlaybackDefaults \
Mopidy-Scrobbler \
Mopidy-Youtube \
Mopidy-InternetArchive \
Mopidy-Plex \
Mopidy-Webhooks \
Mopidy-radio-de \
Mopidy-GMusic \
Mopidy-MusicBox-Webclient \
Mopidy-Iris \
Mopidy-Local-SQLite \
Mopidy-Material-Webclient \
Mopidy-TuneIn \
Mopidy-Podcast-gpodder.net \
Mopidy-Podcast-iTunes \
"

# Install packages.
RUN echo "Installing Alpine Packages" \
  && apk add --update --no-cache \
        --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ \
        tini bash \
        gcc g++ make \
        mopidy \
        gst-plugins-good0.10 gst-plugins-bad0.10 gst-plugins-ugly0.10 \
        alsa-utils \
        python2-dev py-pip py-six \
        libxml2-dev libxslt-dev

RUN echo "Installing Mopidy Python Plugins" \
  && pip install --upgrade pip \
  && pip install ${MOPIDY_PYTHON_PLUGINS} \
  && echo "Cleaining Up" \
  && apk del gcc g++ make \
  && rm -rf ~/.cache/pip \
  && rm -rf /var/cache/apk/*

# Server socket.
EXPOSE 6680

# Install more Mopidy extensions from PyPI.
# RUN pip install Mopidy-MusicBox-Webclient
# RUN pip install Mopidy-Mobile

# Add the configuration file.
# RUN mkdir -p $(dirname "${MOPIDY_CONFIG_FILES}")
ADD mopidy.conf /etc/mopidy/mopidy.conf

ENTRYPOINT ["/sbin/tini","--"]
CMD ["mopidy","--config","${MOPIDY_CONFIG_FILES}"]
