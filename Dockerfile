FROM openjdk:17
LABEL maintainer="Guilherme Jr. <falecom@guilhermejr.net>"
ENV TZ=America/Bahia
ARG VAULT_HOST
ARG VAULT_TOKEN
ENV VAULT_HOST=${VAULT_HOST}
ENV VAULT_TOKEN=${VAULT_TOKEN}
COPY sistema-config-server.jar sistema-config-server.jar
ENTRYPOINT ["java","-jar","/sistema-config-server.jar"]
EXPOSE 8888