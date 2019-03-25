ARG CITUS_BASE=8.1.1-alpine
FROM citusdata/citus:$CITUS_BASE

LABEL maintainer="gerbrand@software-creation.nl"

# SQL files that are run at build-time, so the result is commit in the docker-image
ARG SQL_BUILD_INIT_FILES=
# You can define multiple distributed databases, by default there's one with name postgres
# Username/password can be configured at run-time
ARG POSTGRES_DBS=postgres

ENV PGDATA /data/citus/master
ENV PG_MAJOR 11

ENV POSTGIS_MAJOR 2.5
ENV POSTGIS_VERSION 2.5.2

ENV POSTGRES_DBS $POSTGRES_DBS

RUN set -ex \
    \
    && apk add --no-cache --virtual .fetch-deps \
        ca-certificates \
        openssl \
        tar \
        sudo \
    \
    && wget -O postgis.tar.gz "https://github.com/postgis/postgis/archive/$POSTGIS_VERSION.tar.gz" \
    && mkdir -p /usr/src/postgis \
    && tar \
        --extract \
        --file postgis.tar.gz \
        --directory /usr/src/postgis \
        --strip-components 1 \
    && rm postgis.tar.gz \
    \
    && apk add --no-cache --virtual .build-deps \
        autoconf \
        automake \
        g++ \
        json-c-dev \
        libtool \
        libxml2-dev \
        make \
        perl \
    \
    && apk add --no-cache --virtual .build-deps-edge \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \    
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
        gdal-dev \
        geos-dev \
        proj4-dev \
        protobuf-c-dev \
    && cd /usr/src/postgis \
    && ./autogen.sh \
# configure options taken from:
# https://anonscm.debian.org/cgit/pkg-grass/postgis.git/tree/debian/rules?h=jessie
    && ./configure \
#       --with-gui \
    && make \
    && make install \
    && apk add --no-cache --virtual .postgis-rundeps \
        json-c \
    && apk add --no-cache --virtual .postgis-rundeps-edge \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \    
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \        
        geos \
        gdal \
        proj4 \
        protobuf-c \
    && cd / \
    && rm -rf /usr/src/postgis \
    && apk del .fetch-deps .build-deps .build-deps-edge

COPY ./update-postgis.sh /usr/local/bin

RUN mkdir -p /data/citus && chown postgres /data/citus
COPY init-postgis.sql $SQL_BUILD_INIT_FILES /docker-entrypoint-initdb.d/
COPY ./docker-entrypoint.sh ./init-databases.sh ./run-cluster.sh /
RUN chmod +x ./*.sh

RUN set -ex && apk --no-cache add sudo

# Pre-init the database, no need to initialize the database. Of course
# any password will be stored in the docker-image so only us this for testing
RUN ./init-databases.sh

# Expose coordinator. Worker's ports are not exposed
EXPOSE 5432
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/run-cluster.sh"]