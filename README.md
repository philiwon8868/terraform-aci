# terraform-aci

Sample Terraform Cloud Integration with Cisco ACI Network.

This project is to provide a working sample for those who would like to leverage on ACI's Terraform integration to experience the power of "Infrastructure As Code" - how to provision an ACI application network with a coding approach using Terraform HCL. 

![image](https://user-images.githubusercontent.com/8743281/123520075-80b0fb00-d6e1-11eb-8ec5-909ccd8cfbcc.png)

In this example, our code will provision the followings onto our on-premise ACI private cloud:
* 3 End-Point Groups (EPGs): "Web", "App" and "DB"
* 2 Contracts:
  * Between "App" and "DB": TCP Port 80 (HTTP) and ICMP
  * Between "Web" and "App": permit ALL with a Service Graph
* Service Graph:
  * 2-Arm Routed Mode Unmanaged Firewall with Policy Based Redirect (PBR). The Firewall in this example is a Cisco Virtual ASA Firewall, however, it can be any Firewall.

![image](https://user-images.githubusercontent.com/8743281/123568965-10e16400-d7f8-11eb-9678-8d1c2fd02100.png)

* Associate VMM Domain to all 3 EPGs

## Use Case Description

Describe the problem this code addresses, how your code solves the problem, challenges you had to overcome as pa$

## Installation

Detailed instructions on how to install, configure, and get the project running. Call out any dependencies. This$

## Configuration

If the code is configurable, describe it in detail, either here or in other documentation that you reference.

## Usage

Show users how to use the code. Be specific.
Use appropriate formatting when showing code snippets or command line output.

### DevNet Sandbox

A great way to make your repo easy for others to use is to provide a link to a [DevNet Sandbox](https://develope$

## How to test the software

Provide details on steps to test, versions of components/dependencies against which code was tested, date the co$
If the repo includes automated tests, detail how to run those tests.
If the repo is instrumented with a continuous testing framework, that is even better.


## Known issues

Document any significant shortcomings with the code. If using [GitHub Issues](https://help.github.com/en/article$

## Getting help

Instruct users how to get help with this code; this might include links to an issues list, wiki, mailing list, e$

**Example**

If you have questions, concerns, bug reports, etc., please create an issue against this repository.

## Getting involved

This section should detail why people should get involved and describe key areas you are currently focusing on; $

General instructions on _how_ to contribute should be stated with a link to [CONTRIBUTING](./CONTRIBUTING.md) fi$

## Credits and references

1. Projects that inspired you
2. Related projects
3. Books, papers, talks, or other sources that have meaningful impact or influence on this code

----


The code section composes of mainly 2 files:
1. main.tf 
2. variable.tf

Basically all variables are defined in the file "variable.tf" except for APIC login credential, APIC IP address, the VMM domain name and the target ACI Tenant, which are defined in "Variables" section of the Terraform Cloud environment.
![image](https://user-images.githubusercontent.com/8743281/123569650-505c8000-d7f9-11eb-95e0-52588e2f06ae.png)


We leverage on Terraform Cloud with an on-premise agent to deploy the application on our lab in a private cloud environment. By simply changing the APIC Controller IP address and logon credentials, we can deploy the sample application to any ACI site.

