/*
Secrets list in the form:


 {
  SECRET_NAME_X: "SECRET_VALUE_X"
 },
 {
  SECRET_NAME_Y: "SECRET_VALUE_Y"
 },
 {
  SECRET_NAME_Z: "SECRET_VALUE_Z"
 }

*/

variable "secret_name" {
  type = string
}

variable "secrets_map" {
  type = map
}

variable "secrets_manager_recovery_window" {
  type = number
}

variable "tags" {
  type = map
  default = {}
}
