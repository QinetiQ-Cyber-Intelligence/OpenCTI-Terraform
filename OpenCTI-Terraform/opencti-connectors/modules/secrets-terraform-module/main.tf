/*

Create secrets and return the name and ARN of the secrets in output variable.

Input via var.secrets_map:

{
  "SECRET_NAME_X": "SECRET_VALUE_X",
  "SECRET_NAME_Y": "SECRET_VALUE_Y"
}

Output via output.secrets_list:

[
  {
    name = "SECRET_NAME_X",
    valueFrom = <ARN of the secret>,
  {
    name = "SECRET_NAME_Y",
    valueFrom = <ARN of the secret>
  }
]

*/


resource "aws_secretsmanager_secret" "secret" {
  name                    = var.secret_name
  recovery_window_in_days = var.secrets_manager_recovery_window
  tags                    = var.tags  
}

resource "aws_secretsmanager_secret_version" "secret_version" {
  secret_id     = aws_secretsmanager_secret.secret.id
  secret_string = jsonencode(var.secrets_map)
}
