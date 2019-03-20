FROM citusdata/citus:8.1.1

MAINTAINER gerbrand

ENV PGDATA /var/lib/postgresql/data

ENV POSTGIS_MAJOR 2.5

RUN apt-get update \
      && apt-cache showpkg postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR \
      && apt-get install -y --no-install-recommends \
           postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR \
           postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR-scripts \
           postgis \
      && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/docker-entrypoint.sh"]

COPY init-citus-cluster.sh init_for_testing.sh /
RUN chmod +x /init-citus-cluster.sh /init_for_testing.sh

COPY run-workers.sh init.sql /docker-entrypoint-initdb.d/
RUN chmod +x /docker-entrypoint-initdb.d/run-workers.sh

USER postgres
RUN /bin/bash -c '/init-citus-cluster.sh'
USER root

EXPOSE 5432
CMD ["postgres"]