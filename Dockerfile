FROM alpine
MAINTAINER Andy Savage <andy@savage.hk>

ENV MOPIDY_CACHE_DIR="/root/.cache/mopidy" \
		MOPIDY_CONFIG_DIR="/root/.config/mopidy" \
		MOPIDY_DATA_DIR="/root/.local/share/mopidy"

VOLUME ["/root/.local/mopidy","/root/.config/mopidy"]

ENV MOPIDY_PYTHON_PLUGINS="\
git+https://github.com/pkkid/python-plexapi.git \
git+https://github.com/k0ekk0ek/mopidy_plex.git \
git+https://github.com/jaedb/Iris.git \
git+https://github.com/mopidy/pyspotify.git \
git+https://github.com/mopidy/mopidy-spotify.git \
git+https://github.com/mopidy/mopidy-gmusic.git \
MopidyCLI \
Mopidy-Party \
Mopidy-Mobile \
Mopidy-Webhooks \
Mopidy-WebSettings \
Mopidy-MusicBox-Webclient \
Mopidy-Material-Webclient \
Mopidy-Local-SQLite \
Mopidy-RNZ \
Mopidy-Tachikoma \
Mopidy-Dirble \
Mopidy-Podcast \
Mopidy-Podcast-iTunes \
Mopidy-PlaybackDefaults \
Mopidy-Scrobbler \
Mopidy-Youtube \
Mopidy-InternetArchive \
Mopidy-radio-de \
Mopidy-TuneIn \
"

ENV MOPIDY_PLUGINS_EXTRA_PACKAGES=" \
youtube-dl \
"

ARG INSTALL_LIBSPOTIFY="yes"
ARG LIBSPOTIFY_BASE="/tmp/libspotify-12.1.51-Linux-x86_64"

# Install packages.
RUN echo "Installing Alpine Packages" \
  && apk add --update --no-cache \
        --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ \
        tini bash ca-certificates \
        gcc g++ make git musl-utils sed \
        mopidy \
        gst-plugins-good0.10 gst-plugins-bad0.10 gst-plugins-ugly0.10 \
        alsa-utils \
        python2-dev python3-dev py-pip py-six \
        libxml2-dev libxslt-dev py-cffi \
        ${MOPIDY_PLUGINS_EXTRA_PACKAGES} \
  && mkdir -p "${MOPIDY_CONFIG_DIR}" \
  && mkdir -p "${MOPIDY_CACHE_DIR}" \
  && mkdir -p "${MOPIDY_DATA_DIR}" \
  && mkdir -p "$LIBSPOTIFY_BASE"

# Add Files
ADD mopidy.conf "${MOPIDY_CONFIG_DIR}"
ADD "libspotify-12.1.51-Linux-x86_64" "$LIBSPOTIFY_BASE"

RUN echo "Compiling Libspotify" \
  && mkdir -p "/usr/include/libspotify" \
  && cp "${LIBSPOTIFY_BASE}/include/libspotify/api.h" "/usr/include/libspotify/api.h" \
  && mkdir -p /usr/lib \
  && cp "${LIBSPOTIFY_BASE}/lib/"*.so /usr/lib \
  && ldconfig /

RUN echo "Installing Mopidy Python Plugins" \
  && pip install --upgrade pip \
  && pip install ${MOPIDY_PYTHON_PLUGINS}

# Add the configuration file.
# RUN mkdir -p $(dirname "${MOPIDY_CONFIG_FILES}")
RUN echo "Fixing up Mopidy Config" \
  && sed -i \
  	-e "s#%MOPIDY_CACHE_DIR%#$MOPIDY_CACHE_DIR#g" \
  	-e "s#%MOPIDY_DATA_DIR%#$MOPIDY_DATA_DIR#g" \
  	-e "s#%MOPIDY_CONFIG_DIR%#$MOPIDY_CONFIG_DIR#g" \
    ${MOPIDY_CONFIG_DIR}/mopidy.conf

RUN echo "Cleaining Up" \
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

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["mopidy", "--config","${MOPIDY_CONFIG_DIR}"]
