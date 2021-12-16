FROM debian:11

ARG USER_ID=1000
COPY ci/user.sh .
RUN ./user.sh $USER_ID

RUN apt-get update && apt-get install -y wget gnupg2 make libxml-parser-perl openjdk-17-jdk-headless git python3-distutils

# Accept all OSes
ENV UNSUPPORTED=y
RUN wget https://repository.rudder.io/tools/rudder-setup && sh ./rudder-setup setup-agent latest || true
