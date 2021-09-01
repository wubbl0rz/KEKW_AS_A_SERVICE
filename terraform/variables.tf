
variable "hcloud_token" {
  description = "Hetzner API Token"
  sensitive   = true # Requires terraform >= 0.14
}

variable "num" {
  description = "Number of Servers"
  default     = 3
}
variable "ip_range" {
  description = "IP Range for internal network"
  default     = "10.0.1.0/24"
}

variable "ssh_pub_key_path" {
  description = "Path to the pub ssh key. Same key need to be used to upload using ansible"
}
