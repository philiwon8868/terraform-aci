variable "user" {
  description = "Login information"
  type        = map
  default     = {
    username = "admin"
    password = "C1sc0123"
    url      = "https://10.74.202.95"
  }
}

variable "tenant" {
    type    = string
    default = "Infra_As_Code"
}

variable "vrf" {
    type    = string
    default = "VRF1"
}
variable "bd" {
    type    = string
    default = "prod_bd"
}

variable "bd-web" {
    type    = string
    default = "bd-web"
}
variable "bd-app" {
    type    = string
    default = "bd-app"
}
variable "bd-db" {
    type    = string
    default = "bd-db"
}

variable "subnet" {
    type    = string
    default = "10.4.1.254/24"
}

variable "subnet-web" {
    type    = string
    default = "10.1.1.254/24"
}

variable "subnet-app" {
    type    = string
    default = "10.1.1.254/24"
}

variable "subnet-db" {
    type    = string
    default = "10.3.1.254/24"
}

variable "filters" {
  description = "Create filters with these names and ports"
  type        = map
  default     = {
    filter_https = {
      filter   = "http",
      entry    = "http",
      protocol = "tcp",
      port     = "80"
    },
    filter_icmp = {
      filter   = "icmp",
      entry    = "icmp",
      protocol = "icmp",
      port     = "0"
    }
  }
}
variable "contracts" {
  description = "Create contracts with these filters"
  type        = map
  default     = {
    contract_web = {
      contract = "web",
      subject  = "https",
      filter   = "filter_https"
    },
    contract_icmp = {
      contract = "icmp",
      subject  = "icmp",
      filter   = "filter_icmp"
    }
  }
}
variable "ap" {
    description = "Create application profile"
    type        = string
    default     = "3T-App"
}
variable "epgs" {
    description = "Create epg"
    type        = map
    default     = {
        web_epg = {
            epg   = "web",
            bd    = "bd-web",
            encap = "1020"
        },
        app_epg = {
            epg   = "app",
            bd    = "bd-app",
            encap = "1021"
        },
        db_epg = {
            epg   = "db",
            bd    = "bd-db",
            encap = "1022"
        }
    }
}
variable "epg_contracts" {
    description = "epg contracts"
    type        = map
    default     = {
        terraform_one = {
            epg           = "web_epg",
            contract      = "contract_web",
            contract_type = "provider" 
        },
        terraform_two = {
            epg           = "web_epg",
            contract      = "contract_icmp",
            contract_type = "consumer" 
        },
        terraform_three = {
            epg           = "db_epg",
            contract      = "contract_icmp",
            contract_type = "provider" 
        }
    }
}
