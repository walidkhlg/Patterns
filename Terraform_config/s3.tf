resource "aws_s3_bucket" "logs_bucket" {
  bucket_prefix = "web-ec2-logs-"
tags {
  Name = "Instance_log_bucket"
}
}

data "template_file" "rendered_log_script" {
  template = "${file("./files/log.sh")}"
  vars {
    logs_bucket = "${aws_s3_bucket.logs_bucket.id}"
  }
}
resource "aws_s3_bucket_object" "logs_script" {
  bucket = "${aws_s3_bucket.logs_bucket.id}"
  key    = "log.sh"
  source = "${data.template_file.rendered_log_script.rendered}"
  etag   = "${md5(file("./files/log.sh"))}"
}
