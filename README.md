# DMARC reporting tool
Simple scripts providing an easy way to get a human readable reporting for DMARC

## Dependencies
- offlineimap
- (python3) progressbar2
- (python3) dns
- (python3) jinja2
- (python3) mimetypes
- (python3) socket
- (python3) sqlite3
- (python3) zipfile
- (python3) xml


## Docker
### ENV
 - HOOK_URL
 - MY_IPS
 - IMAPCONF -> config file for offlineimap (default `offlineimaprc`)

### Docker Compose example
```
version: '3'

services:
  dmarc-report:
    image: rvallo/dmarc-report:latest
    container_name: dmarc-report
    environment:
      - HOOK_URL="https://rocket.chat.example/hooks/token"
      - MY_IPS="1.1.1.1 2.2.2.2"
    volumes:
      - /tmp/offlineimaprc:/dmarc-report/offlineimaprc
      - /tmp/db:/dmarc-report/db

```

### K8s Cronjob example
```
---
kind: ConfigMap
apiVersion: v1
metadata:
  name: dmarc-report-imap
data:
  offlineimaprc: |
    [general]
    accounts = DMARC
    ui = Quiet

    [Account DMARC]
    localrepository = Local
    remoterepository = Remote

    [Repository Remote]
    type = IMAP
    remotehost = imap.example.com
    remoteuser = imap_user
    remotepass = imap_password
    ssl = yes
    remoteport= 143
    starttls = yes
    ssl_version = tls1_2
    sslcacertfile = /etc/ssl/certs/ca-certificates.crt

    [Repository Local]
    type = Maildir
    localfolders = ./mails
    restoreatime = yes

---
kind: CronJob
apiVersion: batch/v1beta1
metadata:
  name: dmarc-report
spec:
  schedule: 16 * * * *
  concurrencyPolicy: Forbid
  suspend: false
  jobTemplate:
    spec:
      template:
        spec:
          volumes:
            - name: vol-db
              emptyDir: {}
            - name: config-imap
              configMap:
                name: dmarc-report-imap
                items:
                  - key: offlineimaprc
                    path: offlineimaprc
                defaultMode: 420
          containers:
            - name: dmarc-report
              image: 'rvallo/dmarc-report:stable'
              env:
                - name: HOOK_URL
                  value: >-
                    https://rocket.chat.example.com/hook/token
                - name: IMAPCONF
                  value: /mnt/dmarc/offlineimaprc
                - name: MY_IPS
                  value: '1.1.1.1 2.2.2.2'
              resources: {}
              volumeMounts:
                - name: config-imap
                  mountPath: /mnt/dmarc
                - name: vol-db
                  mountPath: /dmarc-report/db
              terminationMessagePath: /dev/termination-log
              terminationMessagePolicy: File
              imagePullPolicy: Always
          restartPolicy: Never
          terminationGracePeriodSeconds: 130
          dnsPolicy: ClusterFirst
          securityContext:
            fsGroup: 101
          schedulerName: default-scheduler
  successfulJobsHistoryLimit: 1
  failedJobsHistoryLimit: 3

```

## Content
### extract.py
Extracts attachments (zip, gzip) and save them in "reports" directory.

### dmarc.py
Magical script that will read DMARC reports, and inject new records into an sqlite3 DB

### template.j2
Template used to generate the report (report.html). Nothing fancy.

### offlineimaprc.sample
Sample for offlineimap configuration file. You should ensure its mode is set to 0400.
Name *must* be offlineimaprc

### script.sh
The script you want to launch on a regular basis. Will call the other ones in order to
provide you an easy to read report.

### Milligram
[Lightweight CSS framework](https://milligram.io/), under MIT license.

## IPs
The report will highlight when your IPs are listed (red if failed, else green). There are
two ways to provide them:
- either create a "my_ips" file, based on the provided sample
- or let the script detect your MX.

Please note: the script won't check your SPF record, meaning it won't fetch specific
IPs (at least for now). If you have other IPs than your MX, you must provide the full
list using the MY_IPS environment variable.

## License
Shipped under MIT license.

## TODO
- Optimize docker image
- Catch all exceptions and send error to RocketChat