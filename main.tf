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
    description = "3-Tiers by terraform-aci."
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
  for_each = var.Devices
  path = "api/node/mo/${aci_tenant.terraform_tenant.id}/lDevVip-${each.value.name}.json"
  payload = <<EOF
{
      "vnsLDevVip":{
		"attributes":{
				"dn":"${aci_tenant.terraform_tenant.id}/lDevVip-${each.value.name}",
				"svcType":"${each.value.device_type}",
				"managed":"${each.value.managed}",
				"name":"${each.value.name}",
				"rn":"lDevVip-${each.value.name}",
				"status":"created"
			     },
		"children":[
				{"vnsCDev":{
					"attributes":{
							"dn":"${aci_tenant.terraform_tenant.id}/lDevVip-${each.value.name}/cDev-${each.value.interface_name}",
							"name":"${each.value.interface_name}",
							"rn":"cDev-${each.value.interface_name}",
							"status":"created"
						     },
					"children":[
						    {"vnsCIf":
								{"attributes":{
									"dn":"${aci_tenant.terraform_tenant.id}/lDevVip-${each.value.name}/cDev-${each.value.interface_name}/cIf-[${each.value.inside_interface}]",
									"name":"${each.value.inside_interface}",
									"status":"created"
									},
								 "children":[{
									"vnsRsCIfPathAtt":{
										"attributes":{
											"tDn":"topology/pod-${each.value.inside_pod}/paths-${each.value.inside_node}/pathep-[eth1/${each.value.inside_eth}]",
											"status":"created,modified"},
										"children":[]}
									    }]
								}},
						    {"vnsCIf":
								{"attributes":{
									"dn":"${aci_tenant.terraform_tenant.id}/lDevVip-${each.value.name}/cDev-${each.value.interface_name}/cIf-[${each.value.outside_interface}]",
									"name":"${each.value.outside_interface}",
									"status":"created"
									},
								"children":[{
									"vnsRsCIfPathAtt":{
										"attributes":{
											"tDn":"topology/pod-${each.value.outside_pod}/paths-${each.value.outside_node}/pathep-[eth1/${each.value.outside_eth}]",
											"status":"created,modified"},
										"children":[]}
									   }]
							        }}
						 ]}
  				},
				{"vnsLIf":{
					"attributes":{
						"dn":"${aci_tenant.terraform_tenant.id}/lDevVip-${each.value.name}/lIf-${each.value.inside_interface}",
						"name":"${each.value.inside_interface}",
						"encap":"vlan-${each.value.inside_vlan}",
						"status":"created,modified",
						"rn":"lIf-${each.value.inside_interface}"},
					"children":[
							{"vnsRsCIfAttN":{
								"attributes":{
									"tDn":"${aci_tenant.terraform_tenant.id}/lDevVip-${each.value.name}/cDev-${each.value.interface_name}/cIf-[${each.value.inside_interface}]",
									"status":"created,modified"},
								"children":[]}
							}
						   ]
					  }
				},
			      	{"vnsLIf":{
					"attributes":{
						"dn":"${aci_tenant.terraform_tenant.id}/lDevVip-${each.value.name}/lIf-${each.value.outside_interface}",
						"name":"${each.value.outside_interface}",
						"encap":"vlan-${each.value.outside_vlan}",
						"status":"created,modified",
						"rn":"lIf-${each.value.outside_interface}"},
					"children":[
							{"vnsRsCIfAttN":{
								"attributes":{
									"tDn":"${aci_tenant.terraform_tenant.id}/lDevVip-${each.value.name}/cDev-${each.value.interface_name}/cIf-[${each.value.outside_interface}]",
									"status":"created,modified"},
								"children":[]}
							}
						   ]
					}
				},
				{"vnsRsALDevToPhysDomP":{
					"attributes":{
						"tDn":"uni/phys-${each.value.phy_domain}",
						"status":"created"},
					"children":[]
					}
				}
			]
		}
}
EOF
}

## adding inside VLAN for interfaces of L4-L7 Devices to VLAN Pools
resource "aci_rest" "inside_vlan" {
  for_each = var.Devices
  path = "/api/node/mo/uni/infra/vlanns-[${each.value.phy_vlan_pool}]-dynamic/from-[vlan-${each.value.inside_vlan}]-to-[vlan-${each.value.inside_vlan}].json"
  payload = <<EOF
  {
	"fvnsEncapBlk":{
		"attributes":{
			"dn":"uni/infra/vlanns-[${each.value.phy_vlan_pool}]-dynamic/from-[vlan-${each.value.inside_vlan}]-to-[vlan-${each.value.inside_vlan}]",
			"from":"vlan-${each.value.inside_vlan}",
			"to":"vlan-${each.value.inside_vlan}",
			"descr":"Interface: ${each.value.inside_interface}",
			"rn":"from-[vlan-${each.value.inside_vlan}]-to-[vlan-${each.value.inside_vlan}]",
			"status":"created"
		             },
		"children":[]
	                }
  }
  EOF
}

## adding outside VLAN for interfaces of L4-L7 Devices to VLAN Pools
resource "aci_rest" "outside_vlan" {
  for_each = var.Devices
  path = "/api/node/mo/uni/infra/vlanns-[${each.value.phy_vlan_pool}]-dynamic/from-[vlan-${each.value.outside_vlan}]-to-[vlan-${each.value.outside_vlan}].json"
  payload = <<EOF
  {
	  "fvnsEncapBlk":{
		"attributes":{
			"dn":"uni/infra/vlanns-[${each.value.phy_vlan_pool}]-dynamic/from-[vlan-${each.value.outside_vlan}]-to-[vlan-${each.value.outside_vlan}]",
			"from":"vlan-${each.value.outside_vlan}",
			"to":"vlan-${each.value.outside_vlan}",
			"descr":"Interface: ${each.value.outside_interface}",
			"rn":"from-[vlan-${each.value.outside_vlan}]-to-[vlan-${each.value.outside_vlan}]",
			"status":"created"
		             },
		"children":[]
	                }
  }
  EOF
}

## Create the L4-L7 Service Graph Template
resource "aci_l4_l7_service_graph_template" "ServiceGraph" {
    for_each = var.Devices
    tenant_dn                         = aci_tenant.terraform_tenant.id
    name                              = format("%s%s","SG-",each.value.name)
    l4_l7_service_graph_template_type = "legacy"
    ui_template_type                  = "UNSPECIFIED"
}

# Create L4-L7 Service Graph Function Node
resource "aci_function_node" "ServiceGraph" {
    for_each = var.Devices
    l4_l7_service_graph_template_dn = aci_l4_l7_service_graph_template.ServiceGraph[each.value.name].id
    name                            = each.value.name
    func_template_type              = "FW_ROUTED"
    func_type                       = "GoTo"
    is_copy                         = "no"
    managed                         = each.value.managed
    routing_mode                    = "Redirect"
    sequence_number                 = "0"
    share_encap                     = "no"
    relation_vns_rs_node_to_l_dev   = aci_tenant.terraform_tenant.id/lDevVip-${each.value.name}
}
