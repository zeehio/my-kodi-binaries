FROM alpine:edge

RUN apk add --no-cache \
  binutils-gold \
  build-base curl hicolor-icon-theme \
  py3-bluez py3-pillow py3-simplejson \
  python3 xdpyinfo curl-dev ffmpeg-dev \
  flatbuffers-dev fmt-dev freetype-dev \
  fribidi-dev fstrcmp-dev giflib-dev glu-dev \
  gtest-dev libass-dev libcdio-dev libdrm-dev \
  libdvdcss-dev libdvdnav-dev libdvdread-dev \
  libjpeg-turbo-dev lzo-dev mesa-dev openssl-dev \
  pcre-dev rapidjson-dev spdlog-dev sqlite-dev \
  taglib-dev tinyxml-dev zlib-dev libxkbcommon-dev \
  libinput-dev alsa-lib-dev \
  avahi-dev bluez-dev dav1d-dev dbus-dev \
  eudev-dev libbluray-dev libcap-dev \
  libmicrohttpd-dev libnfs-dev libplist-dev \
  libshairport-dev libva-glx-dev libxslt-dev \
  mariadb-connector-c-dev pulseaudio-dev \
  python3-dev samba-dev autoconf automake cmake \
  doxygen graphviz libtool openjdk8-jre-base \
  swig tar wayland-protocols xz

WORKDIR /build

RUN echo "Downloading sources" \
  && wget "https://github.com/xbmc/xbmc/archive/19.1-Matrix.tar.gz" \
  && wget "https://mirrors.kodi.tv/build-deps/sources/crossguid-8f399e8bd4.tar.gz" \
  && echo "...downloaded"

RUN echo "extracting sources" \
  && tar xzf 19.1-Matrix.tar.gz \
  && tar xzf crossguid-8f399e8bd4.tar.gz


COPY fix-musl-incompability.patch /build/
COPY sse-build.patch /build/

RUN echo "Patching sources" \
  && cd "/build/xbmc-19.1-Matrix" \
  && patch -p1 < "/build/fix-musl-incompability.patch" \
  && patch -p1 < "/build/sse-build.patch"


RUN echo "Building Kodi" \
  && export LDFLAGS="$LDFLAGS -Wl,-z,stack-size=1048576" \
  && cd "/build/xbmc-19.1-Matrix" \
  && make -C tools/depends/target/crossguid PREFIX="/opt/kodi" \
  && cmake "/build/xbmc-19.1-Matrix" \
       -DCMAKE_BUILD_TYPE=None \
       -DCMAKE_INSTALL_PREFIX=/usr/local \
       -DCMAKE_INSTALL_LIBDIR=lib \
       -DENABLE_INTERNAL_CROSSGUID=ON \
       -DENABLE_TESTING=OFF \
       -DCROSSGUID_URL="/build/crossguid-8f399e8bd4.tar.gz" \
       -DCORE_PLATFORM_NAME=gbm \
       -DAPP_RENDER_SYSTEM=gles \
  && make  -j$(getconf _NPROCESSORS_ONLN) \
  && make install

RUN echo "Building binary addons" \
  && export LDFLAGS="$LDFLAGS -Wl,-z,stack-size=1048576" \
  && cd "/build/xbmc-19.1-Matrix" \
  && make -C tools/depends/target/binary-addons PREFIX=/usr/local \
  && make install


RUN echo "Compressing binaries" \
  && cd "/" \
  && tar czf kodi-built.tgz /usr/local
