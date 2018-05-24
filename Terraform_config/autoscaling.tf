############# launch config ######
data "template_file" "userdata" {
  template = "${file("./files/userdata.web")}"

  vars {
    bucket_name = "${var.bucket_name}"
    dbhost      = "${aws_rds_cluster.db-cluster.endpoint}"
    dbuser      = "${var.db_user}"
    dbpass      = "${var.db_password}"
    dbname      = "${var.db_name}"
    dbreadname  = "${aws_rds_cluster.db-cluster.reader_endpoint}"
    cloudfront  = "${aws_cloudfront_distribution.walid-web.domain_name}"
  }
}

resource "aws_launch_configuration" "web-lc" {
  name_prefix          = "web-lc-"
  image_id             = "${var.launch_ami}"
  instance_type        = "${var.instance_type}"
  security_groups      = ["${aws_security_group.sg-private.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.web_s3_profile.id}"

  user_data = "${data.template_file.userdata.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

################### Autoscaling Group###############

resource "aws_autoscaling_group" "web-asg" {
  max_size                  = "${var.asg_max}"
  min_size                  = "${var.asg_min}"
  desired_capacity          = "${var.asg_capacity}"
  health_check_grace_period = "${var.asg_grace}"
  health_check_type         = "ELB"
  force_delete              = true
  load_balancers            = ["${aws_elb.web-elb.id}"]
  vpc_zone_identifier       = ["${aws_subnet.public1_subnet.id}", "${aws_subnet.public2_subnet.id}"]

  launch_configuration = "${aws_launch_configuration.web-lc.name}"

  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "asg-web-walid"
  }
}

##################### scale policy ##############
resource "aws_autoscaling_policy" "cpu-policy" {
  name                   = "cpu-policy"
  autoscaling_group_name = "${aws_autoscaling_group.web-asg.name}"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "1"
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "cpu-alarm" {
  alarm_name          = "cpu-alarm"
  alarm_description   = "cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "70"

  dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.web-asg.name}"
  }

  alarm_actions = ["${aws_autoscaling_policy.cpu-policy.arn}"]
}

# scale down alarm
resource "aws_autoscaling_policy" "cpu-policy-scaledown" {
  name                   = "cpu-policy-scaledown"
  autoscaling_group_name = "${aws_autoscaling_group.web-asg.name}"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "-1"
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "cpu-alarm-scaledown" {
  alarm_name          = "cpu-alarm-scaledown"
  alarm_description   = "cpu-alarm-scaledown"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "30"

  dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.web-asg.name}"
  }

  actions_enabled = true
  alarm_actions   = ["${aws_autoscaling_policy.cpu-policy-scaledown.arn}"]
}

############"IAM ROLE ##################""
resource "aws_iam_role" "ec2_s3" {
  name = "ec2_s3_walid"

  assume_role_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
  {
    "Action": "sts:AssumeRole",
    "Principal": {
      "Service": "ec2.amazonaws.com"
    },
    "Effect": "Allow",
    "Sid": ""
  }
]
}
EOF
}

resource "aws_iam_role_policy" "iam_policy" {
  name = "s3_web"
  role = "${aws_iam_role.ec2_s3.id}"

  policy = <<EOF
{
  "Version" : "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListObjects",
        "s3:ListBucket",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::${var.bucket_name}",
        "arn:aws:s3:::${var.bucket_name}/*",
        "arn:aws:s3:::terraform-20180507095426216000000001/*",
        "arn:aws:s3:::terraform-20180507095426216000000001"
      ]
    }
  ]
  }
EOF
}

######## instance profile ########################

resource "aws_iam_instance_profile" "web_s3_profile" {
  name = "web_s3_profile"
  role = "${aws_iam_role.ec2_s3.id}"
}
