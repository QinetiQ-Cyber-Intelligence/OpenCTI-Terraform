/*

Secret list in an output variable in the form:

[
  {
    name = "SECRET_NAME_X",
    valueFrom = <arn of this secret resource>,
  }
  {
    name = "SECRET_NAME_Y",
    valueFrom = <arn of this secret resource>,
  }
]

*/

# Use this to determine if secrets have changed
output "version_id" {
  value = aws_secretsmanager_secret_version.secret_version.version_id
}

output "secrets_list" {
  value = [
    for key in keys(var.secrets_map) : tomap({"name": key, "valueFrom": "${aws_secretsmanager_secret.secret.arn}:${key}::"})
  ]
}
