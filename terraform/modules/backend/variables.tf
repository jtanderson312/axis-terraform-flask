variable "namespace" {
  type        = "string"
  description = "Namespace (e.g. eg)"
}

variable "stage" {
  type        = "string"
  description = "Stage (e.g. `prod`, `dev`, `staging`)"
}

variable "attributes" {
  type        = "list"
  default     = []
  description = "Additional attributes (e.g. `1`)"
}

variable "tags" {
  type        = "map"
  default     = {}
  description = "Additional tags (e.g. map(`BusinessUnit`,`XYZ`)"
}

variable "vpc_id" {
  type = "string"
}

variable "subnet_ids" {
  type = "list"
}

variable "region" {
  type = "string"
}

variable "domain_name" {
  type        = "string"
  default     = "example.com"
  description = "DNS Domain name registered with route53"
}

variable "redis_port" {
  type = "string"
  default = "6379"  
}

variable "certificate_arn" {
  type = "string"
}

variable "container_port" {
  type = "string"
  default = "5000"
  description = "Container port"
}