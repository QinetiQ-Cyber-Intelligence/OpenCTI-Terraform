"""Imported modules that are part of the Python Lambda runtime environment"""
import os
import json
import logging
import urllib3
import boto3


log_level = os.getenv("LOG_LEVEL")
secrets_arn = os.getenv("SECRETS_ARN")
rabbitmq_endpoint = os.getenv("RABBITMQ_ENDPOINT")
rabbitmq_metric_name = os.getenv("RABBITMQ_METRIC_NAME")
rabbitmq_namespace = os.getenv("RABBITMQ_NAMESPACE")


log = logging.getLogger()
log.setLevel(log_level)
try:
    handler = log.handlers[0]
except IndexError:
    handler = logging.StreamHandler()
log.addHandler(handler)
log_format = "[%(asctime)s Level: %(levelname)s] %(name)s: %(message)s \n"
handler.setFormatter(logging.Formatter(log_format, "%Y-%m-%d %H:%M:%S"))


def lambda_handler(event, context):
    """Lambda entry point
    This function will publish metric data from RabbitMQ to CloudWatch Metrics,
    enabling autoscaling to occur on OpenCTI Workers.

    :param event: Invoke information not used
    :type event: JSON
    :param context: Context Invoke information from AWS
    :type context: JSON
    """
    secretsmanager_client = boto3.client("secretsmanager")
    secret = json.loads(secretsmanager_client.get_secret_value(SecretId=secrets_arn)["SecretString"])
    try:
        secret_username = secret["username"]
        secret_password = secret["password"]
    except Exception as e:
        log.info(f"Error parsing Secret: {e}")
        raise e
    http = urllib3.PoolManager()
    auth_headers = urllib3.util.make_headers(basic_auth=f"{secret_username}:{secret_password}")
    response = http.request("GET",f"{rabbitmq_endpoint}/api/overview", headers=auth_headers)
    if 200 <= response.status < 300:
        log.debug(f"Status Code: {response.status}")
        try:
            rabbitmq_total_messages = int(
                json.loads(response.data.decode("utf-8"))["queue_totals"][
                    "messages"
                ]
            )
        except Exception as e:
            log.debug(f"Response Exception: {e}")
            rabbitmq_total_messages = 0
        cloudwatch_client = boto3.client("cloudwatch")
        cloudwatch_client.put_metric_data(
            Namespace=rabbitmq_namespace,
            MetricData=[
                {
                    "MetricName": rabbitmq_metric_name,
                    "Value": rabbitmq_total_messages,
                    "Unit": "Count",
                    "StorageResolution": 60,
                },
            ],
        )
        log.info(
            f"Pushing metric (Total Messages: {rabbitmq_total_messages}) to CloudWatch"
        )
    else:
        log.info(f"RabbitMQ Invalid Response: {response.status}")
