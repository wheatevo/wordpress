FROM wordpress:fpm-alpine

USER root

COPY healthcheck.sh /root/healthcheck.sh
COPY first_run.sh /root/first_run.sh
RUN chmod a+x /root/*.sh
RUN curl -s https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp
RUN chmod a+x /usr/local/bin/wp

HEALTHCHECK --interval=5s --start-period=10s CMD /root/healthcheck.sh
