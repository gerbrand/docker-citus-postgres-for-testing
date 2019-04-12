ARG CITUS_BASE=8-alpine
ARG POSTGRES_DBS
FROM citusdata/citus:$CITUS_BASE

LABEL maintainer="gerbrand@software-creation.nl"

ENV PGDATA /data/citus/master
ENV PG_MAJOR 11

ENV POSTGIS_MAJOR 2.5
ENV POSTGIS_VERSION 2.5.2

# You can define multiple distributed databases, by default no database is created
# Username/password can/should be configured at run-time to avoid having password stored int the image
ENV POSTGRES_DBS ${POSTGRES_DBS}

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

RUN mkdir -p /data/citus /docker-build-initdb.d && chown postgres /data/citus
COPY init-postgis.sql /docker-build-initdb.d/
RUN mv /docker-entrypoint-initdb.d/*.sql /docker-build-initdb.d/
COPY ./create-nodes.sh ./preinit-databases.sh ./docker-entrypoint.sh /
RUN chmod +x ./*.sh

RUN set -ex && apk --no-cache add sudo

# Pre-init the database, no need to initialize the database. Of course
# any password will be stored in the docker-image so only us this for testing
RUN /create-nodes.sh && /preinit-databases.sh

# Expose coordinator. Worker's ports are not exposed
EXPOSE 5432
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD []
