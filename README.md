# Learn Wazi aaS with terraform  <span style="font-size:small"> by Nelson Lopez (IBM DevOps Acceleration Team) </span>
This repo explains how to create a new Wazi aaS(WaaS) zOS cloud instance using Terraform scripts. Its meant for mainframe developers with little to no Cloud or scripting experience. It requires the installation of Terraform on Windows, a Cloud account with access to a WaaS Image and SSH access to a development zOS host. 


2 folders are included to explain how to create an [IBM Cloud Wazi aaS](https://www.ibm.com/cloud/wazi-as-a-service):
> `learn-terra-basic` provides a basic overview of Terraform scripting. 
> `learn-terra-wazi` an advanced example that creates a new WaaS instance using the 'experimental' release.  This folder also includes a prototype **Application IaC** windows script to demonstrate how to replicate an application's runtime from one zOS like a development LPAR to a new virtual zOS for building and testing. 


## The Folder - 'learn-terra-basics'
This folder has sample *.tf terraform files.  They include getting started tips and notes on using HashiCorp's terraform scripting language. For more details see https://learn.hashicorp.com/collections/terraform/cli
&nbsp;

#### First steps 
- Clone this repo 
- Install terraform for your OS https://releases.hashicorp.com/terraform/1.2.4/  (these notes are for Windows) 
- Add the terraform executable to your local path.  In a Windows terminal run `SETX PATH ...`


>TIPS: 
   >+ A nice to have is the HCL vsCode extension https://marketplace.visualstudio.com/items?itemName=HashiCorp.terraformthe 
   >+ In vsCode, open a terminal to run terraform commands by right clicking the project folder and selecting "Open in Integrated terminal". 

#### After the install
Use an editor like vsCode and open main.tf script and review it.  From a DOS terminal, run the terraform lifecycle:
| cmd  | desc | 
| --- | --- | 
| `terraform init` | Download all IBM Cloud provider plugins |
| `terraform plan` | Optional step to validate your script |
| `terraform apply` | Run  |
| `terraform show` | Review an existing run  |
| `terraform destroy` | Remove an instance |


For more on IBM's terraform plugin, scroll to the "VPC infrastructure" topic in https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs

---


## The Folder - 'learn-terra-wazi'
The main.tf script is derived from [IBM Sample terraform repo](https://cloud.ibm.com/docs/ibm-cloud-provider-for-terraform?topic=ibm-cloud-provider-for-terraform-sample_vpc_config) to create a zOS instance. You will need a pre-defined local ssh-key and an IBM Cloud account API key that has access to the WaaS image (Allow list). 

In Windows, run the ssh-keygen cmd and [add your public key to your cloud acct](https://cloud.ibm.com/docs/ssh-keys?topic=ssh-keys-adding-an-ssh-key). Then [add your cloud API key](https://www.ibm.com/docs/en/app-connect/containers_cd?topic=servers-creating-cloud-api-key) as a local environment varaiable. In a windows terminal use `SETX IC_API_Key=<apikey>` (or add the key in a script - but thats not recommended)


After that, review the main.tf and adjust the BASENAME local variable. Then open a terminal and run terraform init and apply.  

> Some tweaks made to the IBM sample
+ Due to permission restrictions in the demo Cloud acct, a few extra vars were added  like; resource group, image name and a pre-existing ssh key plus a few more.  
+ Most resource blocks have been updated to include the resource group id.
+ The IBM sample does not adhere to normal terraform file naming conventions. For example it calls the main script `vpc.tf`.  I changed it to `main.tf`.  But terraform really doesnt care what you call the file as long as it ends in .tf 

[**FYI: This is a link to IBM terraform plugin Doc](https://cloud.ibm.com/docs/ibm-cloud-provider-for-terraform?topic=ibm-cloud-provider-for-terraform-provider-template#code-snippets)



### Application IaC - Demo on 'replicating an Application Runtime image' 
This folder also includes a sample IaC Windows script `App-IaC/postinit.bat` to demostrate how to replicate an application's build and runtime files on a new zOS instance. The script runs IBM utilities to copy (dump) your joblibs, CICS RPL libs, CNTL Cards, JCL...  It then transmits the dump and restores the files on the new instance.  My demo app has batch and CICS code. Once restored this code is ready to run under the default IBMUSER acct. 

![From Dev to VSI Runtime Replication](App_IaC.png)

**The postinit script:**
   -  Runs `App-IaC/APPDUMP.jcl` (found in this folder) on your Dev LPAR. It copies __your__ application image using your SSH acct. You'll need to edit this jcl before running it.  See the jcl for details
   - SFTPs the image to the new zOS instance and restores the files using `App-IaC/APPREST.jcl`
   - Runs `App-IaC/CICSDEF.jcl` to define your App's CICS definitions. The definitions are extracted by the APPDUMP job using a sample CICS GROUP called "DAT". Change that before running. 
   - Replaces the stock CICS STC JCL with your own copy to include your restored RPL libs using `App-IaC/CICSTS56.jcl`   You'll need to edit this jcl before running it.  See the jcl for details
   - The script also aids with optional configurations like installing a local CERT for 3270 access... Just follow the prompt 
   - The CICS steps can be removed to demo just a batch environment. 
&nbsp;
      After running `terraform apply`, main.tf will prompt you to start the postinit script. 
---


## Tech Notes 
The experimental Wazi image (as of June 2022) is configured with CICS, DB2, TN3270, SSH, Git, DBB, RSE, RSEAPI, z/OSMF, GO, ZOAU, Python and BASH. Standard support for IDz, Zowe and Open Editor for VScode  is provided. 


### Default User ID, IP & Ports
The terra script creates a new floating IP which is used to access the system after the IPL. You can view the IPL state from your Cloud account by selecting the VSI's `action` menu item `view serial term`.  You can also re-ipl from that menu. 

**User ID**
The default RACF user is IBMUSER and password is SYS1. On the first logon you will need to reset the password. To reset it, run this from a Windows term:
 ` ssh IBMUSER@<ip> tsocmd 'ALTUSER IBMUSER PASSWORD(sys1)' `

If you have trouble accessing the system try a re-IPL.  

**Ports**
- **3270=992** require a 3270 emulator that supports certs on port 992 using TLS and MS-CAPI (Windows). PCOM and IDz's Host term dont seem to work reliablity - I use [Vista](https://www.tombrennansoftware.com/).   The postinit.bat script aids in installing the cert on Windows.
- **RSE=8137**
- **RSEAPI=8195**
- **zOSMF=10443** 
- **CICS REGION CICSTS56, CMCI=8154**

**DBB & pipelines**
Git and DBB are pre-installed. The postinit script installs a customize DBB/zappbuild environment from [GitHub](https://github.com/nlopez1-ibm/waziDBB). build.groovy is cloned into /u/ibmuser/waziDBB/dbb-zappbuild.  The DBB Daemon is not needed as JAVA performance is not an issue (BIG YEAH!!!). 

Pipelines can be configured with the instance's IP, IBMUSER userid and its public SSH key.  The key is pre-generated by the postinit script.  It is also used for remote git access.  


**Example Wazi Topology**
![Diagram of deployment](vpc-gen2-example.png)


# A word on Ansible  
Anisble is a scripting language used to configure systems. Where terraform is a scripting lanuage suited to manage cloud resources. The 2 provide compilentary features to initialize and configure a new zOS instance. The prior section decribed how to use a simple Windows script to perform the application configuration steps.  If your interested in learning Ansible and replacing the postinit prototype, refer to https://www.ibm.com/docs/en/cloud-paks/z-modernization-stack/2022.2?topic=developing-setting-up-ansible-wazi 


