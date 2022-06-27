variable "network_cidr" {
    description = "CIDR block to be used on VPC"
    type = string
}

variable "infra_name" {
  description = "infrastructure name to apply to resources"
  type = string
}

variable "n_subnets" {
  description = "Number of subnets to be used"
  type = string
  default     =  "6"
}

variable "tags" {
  description = "A map of tags to apply to all resources"
  type        = map
  default     = {} 
}
