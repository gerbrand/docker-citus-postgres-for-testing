FROM citusdata/citus:8.1.1

MAINTAINER gerbrand

ENV PGDATA /data/citus/master
ENV PG_MAJOR 11

ENV POSTGIS_MAJOR 2.5

# install the server and initialize db
RUN apt-cache search postgres | grep citus

RUN apt-get update \
      && apt-cache showpkg postgresql-postgis-$POSTGIS_MAJOR \
      && apt-get install -y --no-install-recommends \
           postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR \
           postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR-scripts \
           postgis \
      && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /data/citus && chown postgres /data/citus
COPY init.sql init_for_testing.sh run-databases.sh /
RUN chmod +x /*.sh

EXPOSE 5432
CMD ["/run-databases.sh"]
