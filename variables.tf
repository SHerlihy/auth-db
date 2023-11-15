variable "server_ip" {
  type    = string
}

variable "admin_pass" {
  type      = string
  sensitive = true
}

variable "user_pass" {
  type      = string
  sensitive = true
}
