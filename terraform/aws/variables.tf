variable "name" {
  type    = string
  default = "nginx"
}

variable "tags" {
  type    = map(string)
  default = {}
}
