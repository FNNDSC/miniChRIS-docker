FROM docker

RUN ["apk", "add", "jq", "curl"]
COPY ./plugins.sh /usr/local/bin/plugins.sh

CMD ["/usr/local/bin/plugins.sh"]
