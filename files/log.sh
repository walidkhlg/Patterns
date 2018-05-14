id=$(curl --silent http://169.254.169.254/latest/meta-data/instance-id)
sudo zip -r $id-logs.zip /var/log/httpd/
sudo aws s3 cp $id-logs.zip s3://terraform-20180507095426216000000001
