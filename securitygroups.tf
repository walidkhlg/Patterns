####### Security Groups ####################

resource "aws_security_group" "sg-elb" {
  name   = "allow_web"
  vpc_id = "${aws_vpc.pattern1.id}"

  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "sg-elb-walid"
  }
}

resource "aws_security_group" "sg-private" {
  name   = "sg_private-walid"
  vpc_id = "${aws_vpc.pattern1.id}"

  ingress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "sg_private-walid"
  }
}

resource "aws_security_group" "rds-sg" {
  name   = "rds-sg-walid"
  vpc_id = "${aws_vpc.pattern1.id}"

  ingress {
    from_port       = 3306
    protocol        = "tcp"
    to_port         = 3306
    security_groups = ["${aws_security_group.sg-private.id}"]
  }

  tags {
    Name = "rds-sg-walid"
  }
}
