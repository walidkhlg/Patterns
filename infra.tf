provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

############# RDS ##############

resource "aws_rds_cluster" "db-cluster" {
  cluster_identifier = "web-db-walid"
  database_name          = "${var.db_name}"
  master_username        = "${var.db_user}"
  master_password        = "${var.db_password}"
  db_subnet_group_name   = "${aws_db_subnet_group.rds_subnetgroup.name}"
  availability_zones     = ["${data.aws_availability_zones.available.names[0]}", "${data.aws_availability_zones.available.names[1]}"]
  skip_final_snapshot    = true
  vpc_security_group_ids = ["${aws_security_group.rds-sg.id}"]
}

resource "aws_rds_cluster_instance" "cluster-instance1" {
  identifier           = "aurora-cluster-web-walid-0"
  instance_class       = "${var.db_instance_class}"
  db_subnet_group_name = "${aws_db_subnet_group.rds_subnetgroup.name}"
  cluster_identifier   = "${aws_rds_cluster.db-cluster.id}"

  tags {
    Name = "web-db-walid0"
  }
}

resource "aws_rds_cluster_instance" "cluster-instance2" {
  identifier           = "aurora-cluster-web-walid-1"
  instance_class       = "${var.db_instance_class}"
  db_subnet_group_name = "${aws_db_subnet_group.rds_subnetgroup.name}"
  cluster_identifier   = "${aws_rds_cluster.db-cluster.id}"

  tags {
    Name = "web-db-walid1"
  }
}

resource "aws_rds_cluster_instance" "cluster-instance3" {
  identifier           = "aurora-cluster-web-walid-2"
  instance_class       = "${var.db_instance_class}"
  db_subnet_group_name = "${aws_db_subnet_group.rds_subnetgroup.name}"
  cluster_identifier   = "${aws_rds_cluster.db-cluster.id}"

  tags {
    Name = "web-db-walid2"
  }
}

################ elb #############

resource "aws_elb" "web-elb" {
  name            = "web-elb"
  subnets         = ["${aws_subnet.public1_subnet.id}", "${aws_subnet.public2_subnet.id}"]
  security_groups = ["${aws_security_group.sg-elb.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = "2"
    interval            = "30"
    target              = "TCP:80"
    timeout             = "3"
    unhealthy_threshold = "2"
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "web-elb-walid"
  }
}

#################### CloudFront ############################
resource "aws_cloudfront_distribution" "walid-web" {
  "default_cache_behavior" {
    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods  = ["GET", "HEAD", "OPTIONS"]

    "forwarded_values" {
      "cookies" {
        forward = "none"
      }

      query_string = false
    }

    target_origin_id       = "s3-${var.bucket_name}"
    viewer_protocol_policy = "allow-all"
  }

  enabled = true

  "origin" {
    domain_name = "${var.bucket_name}.s3.amazonaws.com"
    origin_id   = "s3-${var.bucket_name}"
  }

  "restrictions" {
    "geo_restriction" {
      restriction_type = "none"
    }
  }

  "viewer_certificate" {
    cloudfront_default_certificate = true
  }
}

output "elb-address" {
  value = "${aws_elb.web-elb.dns_name}"
}
output "cloudfront"{
 value ="${aws_cloudfront_distribution.walid-web.domain_name}"
}
