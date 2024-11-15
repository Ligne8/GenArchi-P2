FROM ubuntu:24.04

COPY ./scripts/frontend.sh /init.sh
RUN chmod +x /init.sh

ENTRYPOINT ["/init.sh"]