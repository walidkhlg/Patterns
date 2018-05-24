#!/bin/bash
id=$(curl --silent http://169.254.169.254/latest/meta-data/instance-id)
zip -r '$id-logs.zip' /var/log/httpd/
aws s3 cp $id-logs.zip s3://${logs_bucket}
