FROM alpine
MAINTAINER Andy Savage <andy@savage.hk>

ENV MOPIDY_CACHE_DIR="/root/.cache/mopidy"
ENV MOPIDY_CONFIG_DIR="/root/.config/mopidy"
ENV MOPIDY_DATA_DIR="/root/.local/share/mopidy"

VOLUME ["/root/.local/mopidy","/root/.config/mopidy"]

ARG LIBSPOTIFY_BASE="/tmp/libspotify-12.1.51-Linux-x86_64"
ARG S6_OVERLAY_VERSION="1.21.4.0"

# Add Files
ADD "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-amd64.tar.gz" /tmp/
RUN tar xzf "/tmp/s6-overlay-amd64.tar.gz" -C /
ADD etc /etc/
ADD mopidy.conf "$MOPIDY_CONFIG_DIR"
ADD "libspotify-12.1.51-Linux-x86_64" "$LIBSPOTIFY_BASE"

ENV MOPIDY_PYTHON_PLUGINS="\
git+https://github.com/pkkid/python-plexapi.git \
git+https://github.com/k0ekk0ek/mopidy_plex.git \
git+https://github.com/jaedb/Iris.git \
git+https://github.com/mopidy/pyspotify.git \
git+https://github.com/mopidy/mopidy-spotify.git \
git+https://github.com/mopidy/mopidy-gmusic.git \
git+https://github.com/pimusicbox/mopidy-musicbox-webclient \
git+https://github.com/tkem/mopidy-mobile.git \
git+https://github.com/pimusicbox/mopidy-websettings.git \
Mopidy-Local-SQLite \
MopidyCLI \
Mopidy-Party \
Mopidy-Material-Webclient \
Mopidy-RNZ \
Mopidy-Dirble \
Mopidy-Podcast \
Mopidy-Podcast-iTunes \
Mopidy-PlaybackDefaults \
Mopidy-Scrobbler \
Mopidy-Youtube \
Mopidy-InternetArchive \
Mopidy-TuneIn \
"

ENV MOPIDY_PLUGINS_EXTRA_PACKAGES=" \
youtube-dl \
"

# Install packages.
RUN echo "Installing Alpine Packages" \
  && apk add --update --no-cache \
        --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ \
        bash ca-certificates shadow \
        gcc g++ make git musl-utils sed \
        mopidy \
        gst-plugins-good0.10 gst-plugins-bad0.10 gst-plugins-ugly0.10 \
        alsa-utils \
        python2-dev python3-dev py-pip py-six \
        libxml2-dev libxslt-dev py-cffi \
        ${MOPIDY_PLUGINS_EXTRA_PACKAGES} \
  && groupmod -g 1000 users \
  && useradd -u 911 -U -d /config -s /bin/false abc \
  && usermod -G users abc \
  && mkdir -p "${MOPIDY_CONFIG_DIR}" \
  && mkdir -p "${MOPIDY_CACHE_DIR}" \
  && mkdir -p "${MOPIDY_DATA_DIR}" \
  && mkdir -p "$LIBSPOTIFY_BASE" \
  && echo "Compiling Libspotify" \
  && mkdir -p "/usr/include/libspotify" \
  && cp "${LIBSPOTIFY_BASE}/include/libspotify/api.h" "/usr/include/libspotify/api.h" \
  && mkdir -p /usr/lib \
  && cp "${LIBSPOTIFY_BASE}/lib/"*.so /usr/lib \
  && ldconfig / \
  && echo "Installing Mopidy Python Plugins" \
  && pip install --upgrade pip \
  && pip install ${MOPIDY_PYTHON_PLUGINS} \
  && echo "Cleaining Up" \
  && apk del \
      gcc g++ make git musl-utils \
      libxml2-dev libxslt-dev \
  #&& rm -rf /tmp/* \
  && rm -rf ~/.cache/pip \
  && rm -rf /var/cache/apk/*

# Server socket.
EXPOSE 6680
EXPOSE 6600

# Install more Mopidy extensions from PyPI.
# RUN pip install Mopidy-MusicBox-Webclient
# RUN pip install Mopidy-Mobile

ENTRYPOINT ["/init"]
