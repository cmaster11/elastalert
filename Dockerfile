FROM python:3.6-alpine

LABEL description="ElastAlert suitable for Kubernetes and Helm"
LABEL maintainer="Alberto Marchetti (cmaster11 at gmail.com)"

RUN apk --update upgrade && \
    apk add gcc libffi-dev musl-dev python-dev openssl-dev tzdata libmagic && \
    rm -rf /var/cache/apk/*

ADD ./elastalert /app/elastalert
ADD ./setup.py /app/setup.py

RUN pip install /app && \
    rm -rf /app && \
    apk del gcc libffi-dev musl-dev python-dev openssl-dev

RUN mkdir -p /opt/elastalert/config && \
    mkdir -p /opt/elastalert/rules && \
    echo "#!/bin/sh" >> /opt/elastalert/run.sh && \
    echo "elastalert-create-index --config /opt/config/elastalert_config.yaml" >> /opt/elastalert/run.sh && \
    echo "exec elastalert --config /opt/config/elastalert_config.yaml \"\$@\"" >> /opt/elastalert/run.sh && \
    chmod +x /opt/elastalert/run.sh

ENV TZ "UTC"

VOLUME [ "/opt/config", "/opt/rules" ]
WORKDIR /opt/elastalert
ENTRYPOINT ["/opt/elastalert/run.sh"]
