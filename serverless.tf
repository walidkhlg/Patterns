resource "aws_lambda_function" "func1" {
  function_name = "insertuserdata"
  s3_bucket     = "${var.lambda_s3_bucket}"
  s3_key        = "${var.lambda_zip_file_name}"
  handler       = "main.handler"
  runtime       = "${var.lambda_runtime}"
  role          = "${aws_iam_role.lambda_exec.arn}"

  vpc_config {
    subnet_ids         = ["${aws_subnet.public1_subnet.id}", "${aws_subnet.public2_subnet.id}"]
    security_group_ids = ["${aws_security_group.sg-private.id}"]
  }

  environment {
    variables = {
      DB_HOST     = "${aws_rds_cluster.db-cluster.endpoint}"
      DB_NAME     = "${var.db_name}"
      DB_USER     = "${var.db_user}"
      DB_PASS     = "${var.db_password}"
      
    }
  }
}

resource "aws_lambda_function" "func2" {
  function_name = "showhistory"
  s3_bucket     = "${var.lambda_s3_bucket}"
  s3_key        = "${var.lambda_zip_file_name}"
  handler       = "main.handler2"
  runtime       = "python3.6"
  role          = "${aws_iam_role.lambda_exec.arn}"

  vpc_config {
    subnet_ids         = ["${aws_subnet.public1_subnet.id}", "${aws_subnet.public2_subnet.id}"]
    security_group_ids = ["${aws_security_group.sg-private.id}"]
  }

  environment {
    variables = {
      DB_HOST     = "${aws_rds_cluster.db-cluster.reader_endpoint}"
      DB_NAME     = "${var.db_name}"
      DB_USER     = "${var.db_user}"
      DB_PASS     = "${var.db_password}"
      CLOUD_FRONT = "${aws_cloudfront_distribution.walid-web.domain_name}"
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_web_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lambda_exec_policy" {
  name = "vpc_lambda"
  role = "${aws_iam_role.lambda_exec.id}"

  policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
  {
    "Action": [
           "ec2:DescribeInstances",
           "ec2:CreateNetworkInterface",
           "ec2:AttachNetworkInterface",
           "ec2:DescribeNetworkInterfaces",
           "ec2:DeleteNetworkInterface"
    ],
    "Effect": "Allow",
    "Resource": "*"
  }
]
}
EOF
}

resource "aws_api_gateway_rest_api" "API_GW" {
  name = "${var.rest_api_name}"
}

resource "aws_api_gateway_resource" "resource1" {
  rest_api_id = "${aws_api_gateway_rest_api.API_GW.id}"
  parent_id   = "${aws_api_gateway_rest_api.API_GW.root_resource_id}"
  path_part   = "web"
}

resource "aws_api_gateway_resource" "resource2" {
  rest_api_id = "${aws_api_gateway_rest_api.API_GW.id}"
  parent_id   = "${aws_api_gateway_rest_api.API_GW.root_resource_id}"
  path_part   = "history"
}

resource "aws_api_gateway_method" "gw_method1" {
  rest_api_id   = "${aws_api_gateway_rest_api.API_GW.id}"
  resource_id   = "${aws_api_gateway_resource.resource1.id}"
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "gw_method2" {
  rest_api_id   = "${aws_api_gateway_rest_api.API_GW.id}"
  resource_id   = "${aws_api_gateway_resource.resource2.id}"
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "intergration1" {
  rest_api_id = "${aws_api_gateway_rest_api.API_GW.id}"
  resource_id = "${aws_api_gateway_method.gw_method1.resource_id}"
  http_method = "${aws_api_gateway_method.gw_method1.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.func1.invoke_arn}"
}

resource "aws_api_gateway_integration" "intergration2" {
  rest_api_id = "${aws_api_gateway_rest_api.API_GW.id}"
  resource_id = "${aws_api_gateway_method.gw_method2.resource_id}"
  http_method = "${aws_api_gateway_method.gw_method2.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.func2.invoke_arn}"
}

resource "aws_api_gateway_method_response" "response_method1" {
  rest_api_id = "${aws_api_gateway_rest_api.API_GW.id}"
  resource_id = "${aws_api_gateway_resource.resource1.id}"
  http_method = "${aws_api_gateway_integration.intergration1.http_method}"
  status_code = "200"

  response_models {
    "application/json" = "${aws_api_gateway_model.model1.name}"
  }
}

resource "aws_api_gateway_model" "model1" {
  rest_api_id  = "${aws_api_gateway_rest_api.API_GW.id}"
  name         = "userdata"
  content_type = "application/json"

  schema = <<EOF
  {
  "$schema": "http://json-schema.org/draft-04/schema#",
  "title": "userdata",
  "type": "object",
  "properties": {

    "user_ip": {
      "type": "string"
    },
    "user_agent": {
      "type": "string"
    },
    "req_time": {
      "type": "string"
    }
  }
}
EOF
}

resource "aws_api_gateway_method_response" "response_method2" {
  rest_api_id = "${aws_api_gateway_rest_api.API_GW.id}"
  resource_id = "${aws_api_gateway_resource.resource2.id}"
  http_method = "${aws_api_gateway_integration.intergration1.http_method}"
  status_code = "200"

  response_models {
    "application/json" = "${aws_api_gateway_model.model2.name}"
  }
}

resource "aws_api_gateway_model" "model2" {
  rest_api_id  = "${aws_api_gateway_rest_api.API_GW.id}"
  name         = "userdatalist"
  content_type = "application/json"

  schema = <<EOF
  {
     "$schema":"http://json-schema.org/draft-04/schema#",
     "title":"userdata_list",
     "type":"object",
     "properties":{
        "usr":{
           "type":"array",
           "items":{
              "type":"object",
              "properties":{
                 "id":{
                    "type":"integer"
                 },
                 "user_ip":{
                    "type":"string"
                 },
                 "user_agent":{
                    "type":"string"
                 },
                 "req_time":{
                    "type":"string"
                 }
              }
           }
        }
     }
  }
EOF
}

resource "aws_api_gateway_integration_response" "response_method_integration1" {
  rest_api_id = "${aws_api_gateway_rest_api.API_GW.id}"
  resource_id = "${aws_api_gateway_resource.resource1.id}"
  http_method = "${aws_api_gateway_method_response.response_method1.http_method}"
  status_code = "${aws_api_gateway_method_response.response_method1.status_code}"
}

resource "aws_api_gateway_integration_response" "response_method_integration2" {
  rest_api_id = "${aws_api_gateway_rest_api.API_GW.id}"
  resource_id = "${aws_api_gateway_resource.resource2.id}"
  http_method = "${aws_api_gateway_method_response.response_method2.http_method}"
  status_code = "${aws_api_gateway_method_response.response_method2.status_code}"
}

resource "aws_api_gateway_deployment" "API_dep" {
  depends_on = [
    "aws_api_gateway_integration.intergration1",
    "aws_api_gateway_integration.intergration2",
  ]

  rest_api_id = "${aws_api_gateway_rest_api.API_GW.id}"
  stage_name  = "${var.deployment_stage}"
}

resource "aws_lambda_permission" "lambda_permission1" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.func1.arn}"
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.API_GW.id}/*/*/*"
}

resource "aws_lambda_permission" "lambda_permission2" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.func2.arn}"
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.API_GW.id}/*/*/*"
}

output "invoke_url" {
  value = "${aws_api_gateway_deployment.API_dep.invoke_url}"
}
