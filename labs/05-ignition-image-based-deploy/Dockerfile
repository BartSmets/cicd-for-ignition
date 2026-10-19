ARG IGNITION_VERSION=8.3.8
FROM inductiveautomation/ignition:${IGNITION_VERSION}

ARG GATEWAY_DATA_PATH=/usr/local/bin/ignition/data

COPY --chown=2003:0 third-party-modules/  /third-party-modules/

RUN sha256sum /third-party-modules/*.modl \
    && echo "Verifying modules (stand-in for signature/AV scan)…" \
    && sleep 5

COPY --chown=2003:0 services/modules.json ${GATEWAY_DATA_PATH}/modules.json

COPY --chown=2003:0 services/config/      ${GATEWAY_DATA_PATH}/config/

RUN sed -i 's/"defaultAuthProfileCreated": true/"defaultAuthProfileCreated": false/' \
      ${GATEWAY_DATA_PATH}/config/resources/core/com.inductiveautomation.opcua/one-time/config.json

COPY --chown=2003:0 projects/             ${GATEWAY_DATA_PATH}/projects/

ARG GIT_SHA=unknown
ARG IMAGE_SOURCE=https://github.com/Mustry-Academy/cicd-for-ignition
LABEL org.opencontainers.image.revision="${GIT_SHA}" \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.title="cicd-lab-05-ignition" \
      org.opencontainers.image.description="Ignition 8.3 gateway with its project, config, and modules"
