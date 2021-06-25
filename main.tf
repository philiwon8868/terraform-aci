terraform {
  required_providers {
    aci = {
      source = "CiscoDevNet/aci"
    }
  }
}

# Configure the provider with your Cisco APIC credentials.
provider "aci" {
  username = var.user.username
  password = var.user.password
  url      = var.user.url
  insecure = true
}

# Define an ACI Tenant Resource.
resource "aci_tenant" "terraform_tenant" {
    name        = var.tenant.name
    description = "3-Tiers by terraform-aci, Philip."
}

# Define an ACI Tenant VRF Resource.
resource "aci_vrf" "terraform_vrf" {
    tenant_dn   = aci_tenant.terraform_tenant.id
    description = "VRF Created Using terraform-aci"
    name        = var.vrf
}

# Define an ACI Tenant BD Resource.
resource "aci_bridge_domain" "terraform_bd" {
    tenant_dn          = aci_tenant.terraform_tenant.id
    relation_fv_rs_ctx = aci_vrf.terraform_vrf.id
    description        = "BDs Created Using terraform-aci"
    for_each           = var.bds
    name               = each.value.bd_name
}

# Define an ACI Tenant BD Subnet Resource.
resource "aci_subnet" "terraform_bd_subnet" {
    parent_dn   = aci_bridge_domain.terraform_bd[each.key].id
    description = "Subnet Created Using terraform-aci"
    for_each    = var.bds
    ip          = each.value.subnet
}

# Define an ACI Filter Resource.
resource "aci_filter" "terraform_filter" {
    for_each    = var.filters
    tenant_dn   = aci_tenant.terraform_tenant.id
    description = "Filter ${each.key} created by terraform-aci"
    name        = each.value.filter
}

# Define an ACI Filter Entry Resource.
resource "aci_filter_entry" "terraform_filter_entry" {
    for_each      = var.filters
    filter_dn     = aci_filter.terraform_filter[each.key].id
    name          = each.value.entry
    ether_t       = "ipv4"
    prot          = each.value.protocol
    d_from_port   = each.value.port
    d_to_port     = each.value.port
}

# Define an ACI Contract Resource.
resource "aci_contract" "terraform_contract" {
    for_each      = var.contracts
    tenant_dn     = aci_tenant.terraform_tenant.id
    name          = each.value.contract
    description   = "Contract created using terraform-aci"
}

# Define an ACI Contract Subject Resource.
resource "aci_contract_subject" "terraform_contract_subject" {
    for_each                      = var.contracts
    contract_dn                   = aci_contract.terraform_contract[each.key].id
    name                          = each.value.subject
    relation_vz_rs_subj_filt_att  = [aci_filter.terraform_filter[each.value.filter].id]
}

# Define an ACI Application Profile Resource.
resource "aci_application_profile" "terraform_ap" {
    tenant_dn  = aci_tenant.terraform_tenant.id
    name       = var.ap
    description = "App Profile Created Using terraform-aci"
}

# Define an ACI Application EPG Resource.
resource "aci_application_epg" "terraform_epg" {
    for_each                = var.epgs
    application_profile_dn  = aci_application_profile.terraform_ap.id
    name                    = each.value.epg
    relation_fv_rs_bd       = aci_bridge_domain.terraform_bd[each.key].id
    description             = "EPG Created Using terraform-aci"
}

# Associate the EPG Resources with a VMM Domain.
resource "aci_epg_to_domain" "terraform_epg_domain" {
    for_each              = var.epgs
    application_epg_dn    = aci_application_epg.terraform_epg[each.key].id
    tdn   = var.vmm_domain.name
}

# Associate the EPGs with the contrats
resource "aci_epg_to_contract" "terraform_epg_contract" {
    for_each           = var.epg_contracts
    application_epg_dn = aci_application_epg.terraform_epg[each.value.epg].id
    contract_dn        = aci_contract.terraform_contract[each.value.contract].id
    contract_type      = each.value.contract_type
}


# Define the L4-L7 Device inside the tenant.name
resource "aci_rest" "device" {
  for_each = var.FW_Device
  path = "api/node/mo/uni/${aci_tenant.terraform_tenant.id}/lDevVip-${each.value.name}.json"
  payload = <<EOF
{
      "vnsLDevVip":{
		"attributes":{
				"dn":"uni/${aci_tenant.terraform_tenant.id}/lDevVip-${each.value.name}",
				"svcType":"FW",
				"managed":"false",
				"name":${each.value.name},
				"rn":"lDevVip-${each.value.name}",
				"status":"created"
			     },
		"children":[
				{"vnsCDev":{
					"attributes":{
							"dn":"uni/${aci_tenant.terraform_tenant.id}/lDevVip-${each.value.name}/cDev-Device-Interfaces",
							"name":"Device-Interfaces",
							"rn":"cDev-Device-Interfaces",
							"status":"created"
						     },
					"children":[
						    {"vnsCIf":
								{"attributes":{
									"dn":"uni/${aci_tenant.terraform_tenant.id}/lDevVip-${each.value.name}/cDev-Device-Interfaces/cIf-[Inside]",
									"name":"Inside",
									"status":"created"
									},
								 "children":[{
									"vnsRsCIfPathAtt":{
										"attributes":{
											"tDn":"topology/pod-1/paths-301/pathep-[eth1/1]",
											"status":"created,modified"},
										"children":[]}
									    }]
								}},
						    {"vnsCIf":
								{"attributes":{
									"dn":"uni/${aci_tenant.terraform_tenant.id}/lDevVip-${each.value.name}/cDev-Device-Interfaces/cIf-[Outside]",
									"name":"Outside",
									"status":"created"
									},
								"children":[{
									"vnsRsCIfPathAtt":{
										"attributes":{
											"tDn":"topology/pod-1/paths-301/pathep-[eth1/2]",
											"status":"created,modified"},
										"children":[]}
									   }]
							        }}
						 ]}
  				},
				{"vnsLIf":{
					"attributes":{
						"dn":"uni/${aci_tenant.terraform_tenant.id}/lDevVip-${each.value.name}/lIf-Inside",
						"name":"Inside",
						"encap":"vlan-100",
						"status":"created,modified",
						"rn":"lIf-Inside"},
					"children":[
							{"vnsRsCIfAttN":{
								"attributes":{
									"tDn":"uni/${aci_tenant.terraform_tenant.id}/lDevVip-${each.value.name}/cDev-Device-Interfaces/cIf-[Inside]",
									"status":"created,modified"},
								"children":[]}
							}
						   ]
					  }
				},
			      	{"vnsLIf":{
					"attributes":{
						"dn":"uni/${aci_tenant.terraform_tenant.id}/lDevVip-${each.value.name}/lIf-Outside",
						"name":"Outside",
						"encap":"vlan-200",
						"status":"created,modified",
						"rn":"lIf-Outside"},
					"children":[
							{"vnsRsCIfAttN":{
								"attributes":{
									"tDn":"uni/${aci_tenant.terraform_tenant.id}/lDevVip-${each.value.name}/cDev-Device-Interfaces/cIf-[Outside]",
									"status":"created,modified"},
								"children":[]}
							}
						   ]
					}
				},
				{"vnsRsALDevToPhysDomP":{
					"attributes":{
						"tDn":"uni/phys-phys",
						"status":"created"},
					"children":[]
					}
				}
			]
		}
}
EOF
}
