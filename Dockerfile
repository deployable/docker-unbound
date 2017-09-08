FROM debian:9

RUN set -uex; \
    apt-get update; \
    apt-get install -y unbound;

COPY unbound.conf /etc/unbound/unbound.conf

CMD unbound -d

