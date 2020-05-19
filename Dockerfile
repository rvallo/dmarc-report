#FROM python:3-slim-buster
FROM ubuntu:18.04

RUN apt update && apt install --no-install-recommends -y git offlineimap python3-dns python3 ca-certificates python3-dnspython python3-jinja2 sqlite3 python3-progressbar 

RUN adduser --system --shell /bin/bash --group --gecos "dmarc-report" --disabled-password dmarc

COPY --chown=dmarc:dmarc ./ /dmarc-report
USER dmarc

WORKDIR "/dmarc-report"
ENTRYPOINT ["/bin/bash"]
CMD ["/dmarc-report/script.sh"]
