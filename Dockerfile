#FROM python:3-slim-buster
FROM ubuntu:18.04

RUN apt update && apt install --no-install-recommends -y git offlineimap python3-dns python3 ca-certificates python3-dnspython python3-jinja2 sqlite3 python3-progressbar 


RUN apt install -y vim

COPY ./ /dmarc-report

ENTRYPOINT ["/bin/bash"]


