# terraform-aci

Sample Terraform Cloud Integration with Cisco ACI.

This sample will provision an ACI Tenant with a common 3-Tier Application Profile.

The objective is to provide a working sample for those who would like to leverage on ACI's Terraform integration to experience the power of "Infrastructure As Code".

![image](https://user-images.githubusercontent.com/8743281/123520075-80b0fb00-d6e1-11eb-8ec5-909ccd8cfbcc.png)

In this example, we have 3 End-Point Groups (EPGs): "Web", "App" and "DB"

Between "App" and "DB", there are 2 Contracts - one is for granting access of TCP 80 and the other is for granting ICMP

Between "Web" and "App", we have provisioned a 2-Arm Routed Mode Unmanaged Mode Firewall Service Graph with Policy Based Redirect (PBR). The Firewall in this example is a Cisco Virtual ASA Firewall, however, it can be any Firewall.

The code section composes of mainly 2 files:
1. main.tf 
2. variable.tf

Basically all variables are defined in the file "variable.tf" except for APIC login credential which is defined in "Variables" section of the Terraform Cloud environment.

We leverage on Terraform Cloud with an on-premise agent to deploy the application on our lab in a private cloud environment. By simply changing the APIC Controller IP address and logon credentials, we can deploy the sample application to any ACI site.

