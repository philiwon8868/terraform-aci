variable "tenant" {
    type    = string
    default = "Infra_As_Code"
}

variable "vrf" {
    type    = string
    default = "VRF1"
}

variable "bds" {
    description = "List of bridge domains to be created"
    type = map
    default = {
      web = {
        bd_name = "bd-web"
        subnet  = "10.1.1.254/24"
      },
      app = {
        bd_name = "bd-web"
        subnet  = "10.1.1.254/24"
      },
      db = {
        bd_name = "bd-db"
        subnet = "10.3.1.254/24"
      },
      inside = {
        bd_name = "bd-inside"
        subnet = "1.1.1.1/24"
      },
      outside = {
        bd_name = "bd-outside"
        subnet = "2.2.2.1/24"
      }
    }
}

variable "filters" {
  description = "Create filters with these names and ports"
  type        = map
  default     = {
    filter_http = {
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
    contract_http = {
      contract = "http",
      subject  = "http",
      filter   = "filter_http"
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
        web     = {
            epg   = "web",
            bd    = "bd-web",
            encap = "1020"
        },
        app     = {
            epg   = "app",
            bd    = "bd-web",
            encap = "1021"
        },
        db      = {
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
            epg           = "app",
            contract      = "contract_http",
            contract_type = "consumer" 
        },
        terraform_two = {
            epg           = "app",
            contract      = "contract_icmp",
            contract_type = "consumer" 
        },
        terraform_three = {
            epg           = "db",
            contract      = "contract_icmp",
            contract_type = "provider" 
        },
        terraform_4 = {
            epg           = "db",
            contract      = "contract_http",
            contract_type = "provider" 
        }
    }
}
