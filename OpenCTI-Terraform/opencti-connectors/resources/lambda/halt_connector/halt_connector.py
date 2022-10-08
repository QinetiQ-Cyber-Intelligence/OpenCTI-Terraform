"""Imported modules that are part of the Python Lambda runtime environment"""
import logging
import boto3

log = logging.getLogger()
log.setLevel("INFO")
try:
    handler = log.handlers[0]
except IndexError:
    handler = logging.StreamHandler()
log.addHandler(handler)
log_format = "[%(asctime)s Level: %(levelname)s] %(name)s: %(message)s \n"
handler.setFormatter(logging.Formatter(log_format, "%Y-%m-%d %H:%M:%S"))


def lambda_handler(event, context):
    """ Lambda entry point
    This function will parse the event data sent to Lambda and perform actions based
    off this information: either stop or start the targeted connector detailed in
    the event parameter.

    :param event: Invocation Event information containing the action and details
    :type event: JSON
    :param context: Context Invoke information from AWS
    :type context: JSON
    """
    ecs_client = boto3.client("ecs")
    service_target = event["service_target"]
    if event["action"] == "stop":
        log.info(f"Received EventBridge event to stop connector {service_target}")
        response = ecs_client.update_service(
                            cluster=event["cluster"],
                            service=service_target,
                            desiredCount=0
                            )
        log.info(response)
    elif event["action"] == "start":
        log.info(f"Received EventBridge event to start connector {service_target}")
        response = ecs_client.update_service(
                            cluster=event["cluster"],
                            service=service_target,
                            desiredCount=1
                            )
        log.info(response)
    else:
        log.info(f"Requested action not supported {event}")
