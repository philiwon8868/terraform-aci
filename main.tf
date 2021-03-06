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
  insecure = true # comment
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
			"allocMode":"static",
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
			"allocMode":"static",
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
    managed                         = "no"
    routing_mode                    = "Redirect"
    sequence_number                 = "0"
    share_encap                     = "no"
    relation_vns_rs_node_to_l_dev   = "${aci_tenant.terraform_tenant.id}/lDevVip-${each.value.name}"
}

# Create L4-L7 Service Graph template T1 connection.
resource "aci_connection" "t1-n1" {
    for_each = var.Devices
    l4_l7_service_graph_template_dn = aci_l4_l7_service_graph_template.ServiceGraph[each.value.name].id
    name           = "C2"
    adj_type       = "L3"
    conn_dir       = "provider"
    conn_type      = "external"
    direct_connect = "no"
    unicast_route  = "yes"
    relation_vns_rs_abs_connection_conns = [
        aci_l4_l7_service_graph_template.ServiceGraph[each.value.name].term_prov_dn,
        aci_function_node.ServiceGraph[each.value.name].conn_provider_dn
    ]
    depends_on = [
    aci_rest.device,
    ]
}

# Create L4-L7 Service Graph template T2 connection.
resource "aci_connection" "n1-t2" {
    for_each = var.Devices
    l4_l7_service_graph_template_dn = aci_l4_l7_service_graph_template.ServiceGraph[each.value.name].id
    name                            = "C1"
    adj_type                        = "L3"
    conn_dir                        = "provider"
    conn_type                       = "external"
    direct_connect                  = "no"
    unicast_route                   = "yes"
    relation_vns_rs_abs_connection_conns = [
        aci_l4_l7_service_graph_template.ServiceGraph[each.value.name].term_cons_dn,
        aci_function_node.ServiceGraph[each.value.name].conn_consumer_dn
    ]
    depends_on = [
    aci_rest.device,
    ]
}

# Create L4-L7 Logical Device Selection Policies / Logical Device Context
resource "aci_logical_device_context" "ServiceGraph" {
    for_each = var.Devices
    tenant_dn                          = aci_tenant.terraform_tenant.id
    ctrct_name_or_lbl                  = each.value.contract
    graph_name_or_lbl                  = format ("%s%s","SG-",each.value.name)
    node_name_or_lbl                   = aci_function_node.ServiceGraph[each.value.name].name
    relation_vns_rs_l_dev_ctx_to_l_dev = "${aci_tenant.terraform_tenant.id}/lDevVip-${each.value.name}"
    #relation_vns_rs_l_dev_ctx_to_l_dev = aci_rest.device[each.value.name].id
    depends_on = [
    aci_rest.device,
    aci_service_redirect_policy.pbr,
    ]
}

# Create L4-L7 Logical Device Interface Contexts for consumer
resource "aci_logical_interface_context" "consumer" {
  for_each = var.Devices
	logical_device_context_dn        = aci_logical_device_context.ServiceGraph[each.value.name].id
	conn_name_or_lbl                 = "consumer"
	l3_dest                          = "yes"
	permit_log                       = "no"
  relation_vns_rs_l_if_ctx_to_l_if = "${aci_tenant.terraform_tenant.id}/lDevVip-${each.value.name}/lIf-${each.value.outside_interface}"
  relation_vns_rs_l_if_ctx_to_bd   = "${aci_tenant.terraform_tenant.id}/BD-${each.value.outside_bd}"
  relation_vns_rs_l_if_ctx_to_svc_redirect_pol = aci_service_redirect_policy.pbr[each.value.outside_pbr].id
  depends_on = [
    aci_rest.device, # wait until the device has been created
    aci_service_redirect_policy.pbr, # wait until the PBRs have been created
  ]
}

# Create L4-L7 Logical Device Interface Contexts for provider
resource "aci_logical_interface_context" "provider" {
  for_each = var.Devices
	logical_device_context_dn        = aci_logical_device_context.ServiceGraph[each.value.name].id
	conn_name_or_lbl                 = "provider"
	l3_dest                          = "yes"
	permit_log                       = "no"
  relation_vns_rs_l_if_ctx_to_l_if = "${aci_tenant.terraform_tenant.id}/lDevVip-${each.value.name}/lIf-${each.value.inside_interface}"
  relation_vns_rs_l_if_ctx_to_bd   = "${aci_tenant.terraform_tenant.id}/BD-${each.value.inside_bd}"
  relation_vns_rs_l_if_ctx_to_svc_redirect_pol = aci_service_redirect_policy.pbr[each.value.inside_pbr].id
  depends_on = [
    aci_rest.device,
    aci_service_redirect_policy.pbr,
  ]
}

# Associate subject to Service Graph
resource "aci_contract_subject" "subj" {
  for_each = var.Devices
  contract_dn = "${aci_tenant.terraform_tenant.id}/brc-${each.value.contract}"
  name = "${each.value.contract}"
  relation_vz_rs_subj_graph_att = aci_l4_l7_service_graph_template.ServiceGraph[each.value.name].id
}

# Create IP SLA Monitoring Policy - Using REST-API call to APIC controller
resource "aci_rest" "ipsla" {
    for_each = var.PBRs
    path    = "api/node/mo/${aci_tenant.terraform_tenant.id}/ipslaMonitoringPol-${each.value.ipsla}.json"
    payload = <<EOF
{
	"fvIPSLAMonitoringPol": {
		"attributes": {
			"dn": "${aci_tenant.terraform_tenant.id}/ipslaMonitoringPol-${each.value.ipsla}",
			"name": "${each.value.ipsla}",
			"rn": "ipslaMonitoringPol-${each.value.ipsla}",
			"status": "created"
		},
		"children": []
	}
}
EOF  
}

# Create Redirect Health Group for PBRs - Using REST-API call to APIC controller
resource "aci_rest" "rh" {
    for_each = var.PBRs
    path    = "api/node/mo/${aci_tenant.terraform_tenant.id}/svcCont/redirectHealthGroup-${each.value.redirect_health}.json"
    payload = <<EOF
{
	"vnsRedirectHealthGroup": {
		"attributes": {
			"dn": "${aci_tenant.terraform_tenant.id}/svcCont/redirectHealthGroup-${each.value.redirect_health}",
			"name": "${each.value.redirect_health}",
			"rn": "redirectHealthGroup-${each.value.redirect_health}",
			"status": "created"
		},
		"children": []
	}
}
EOF
}

# Associate IPSLA monitoring policy to the PBRs
resource "aci_service_redirect_policy" "pbr" {
  for_each = var.PBRs
  tenant_dn = aci_tenant.terraform_tenant.id
  name = each.value.name
  dest_type = each.value.dest_type
  max_threshold_percent = each.value.max_threshold_percent
  description = each.value.description
  threshold_enable = each.value.threshold_enable
  relation_vns_rs_ipsla_monitoring_pol = "${aci_tenant.terraform_tenant.id}/ipslaMonitoringPol-${each.value.ipsla}"
  depends_on = [ #wait until IPSLA has been completed
    aci_rest.ipsla,
  ]
}

# Associate Redirect Health Group to the PBRs
resource "aci_destination_of_redirected_traffic" "pbr" {
  for_each = var.PBRs
  service_redirect_policy_dn = aci_service_redirect_policy.pbr[each.value.name].id
  ip = each.value.ip
  mac = each.value.mac
  relation_vns_rs_redirect_health_group = "${aci_tenant.terraform_tenant.id}/svcCont/redirectHealthGroup-${each.value.redirect_health}"
  depends_on = [ #wait until Redirect Health Group has been completed
    aci_rest.rh,
  ]
}
