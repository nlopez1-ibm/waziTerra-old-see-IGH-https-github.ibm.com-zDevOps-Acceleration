# Learn Terraform for Wazi aaS basics - by NLopez 
This repo has 2 main folders to help you learn how terraform can be used to create a new Wazi aaS instance using you IBM Cloud account. 

``` learn-terra-basic ``` gives a highlevel overview of the scripting lanugae using local resources.  

``` learn-terra-wazi ``` is a more advanced script to create a wazi instance using the 'special' beta release.  


## The basics folder 
This project folder has a few sample *.tf files.  They  provide basic getting started tips on how to use HashiCorp's Terraform HCL scripting language. For more on getting started see https://learn.hashicorp.com/collections/terraform/cli


### install terraform on windows
- Install terra for windows https://releases.hashicorp.com/terraform/1.2.4/  (or any supported OS)
- Add the executable to the path using (Windows) ``` SETX PATH ...```
- A nice to have is the vsCode extension https://marketplace.visualstudio.com/items?itemName=HashiCorp.terraformthe 

>TIP: In vsCode, open a terminal to run terraform cli by right clicking the project folder and selecting "Open in Intergrated terminal". 

## After the install
Use the baics project folder or create your own with any name to hold your .tf scripts. From the cli, run terraform cmds like  -  'terraform init', plan, apply, show, destroy  

>TIP: To skip the interactive prompt "enter yes" during an 'apply', run 'terraform apply -auto-approve'

Terra tracks diff's between applys to keep resources up to date.

In windows, to build a cloud resource you'll first need to SETX your cloud acct's api as an environment var IC_API_Key (or add the key in a script - but thats not recommended)

To start learning, open the sample main.tf script and follow the notes. 

For more on IBM's Terraform plugin, see the VPC infrastructure topic in:
   IBM Cloud plugin is https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs


## The Advanced project folder  "Create a Wazi aaS instance for DBB Builds"
This terraform sample is derived from [IBM Sample terraform repo](https://cloud.ibm.com/docs/ibm-cloud-provider-for-terraform?topic=ibm-cloud-provider-for-terraform-sample_vpc_config)

This sample uses a pre-defined local ssh-key and a cloud account api key with access to the current wazi VSI. 
Run terraform CLI from this project folder using the standard flow 
   - **init**
   - **plan**
   - **apply**  
   - and eventualy **destroy**
   - **show** to view your current state 

>tweaks to the IBM sample
+ A few extra local vars were added due to permission restrictions in the cloud acct used for these samples  like; resource group, image name for the wazi test image and my ssh key pre-added to my acct plus a few more.. 
+ needed to extend most resource blocks to pass the resource group id
+ The IBM sample does not adhere to normal terraform file naming conventions. For example it calls the main script vpc.tf.  I changed it to main.tf.  But terraform really doesnt care what you call the file as long as it ends in .tf 

[This is a link to IBM terraform plugin Doc](https://cloud.ibm.com/docs/ibm-cloud-provider-for-terraform?topic=ibm-cloud-provider-for-terraform-provider-template#code-snippets)

## Tech Notes
The experimental Wazi image (as of June 2022) is configured with Git, DBB, RSE and zoSMF. 

After the IPL you can setup IDz, Zowe and 3270 access.  The advanced folder has a helping windows batch script to help to finalize several one-time setup steps. 

### User ID, IP & Ports

The terra script creates a floating IP which is used to access the system after the IPL. You can view the IPL state from your Cloud account by selecting the new VSI 'action' menu item 'view serial term'.  You can also re-ipl from that menu. 

**User ID**
The default is RACGH user is IBMUSER and password is SYS1. If you have trouble accessing the system try a re-IPL.  

**Ports**
- **3270=992** you need a 3270 emulator that accepts certs on port 992 using TLS and MS-CAPI (windows). PCOM and IDz Host term dont seem to work reliablity - I use Vista.   The postinit.bat script installs the cert from z/OS to your local windows registry (review windows MMC certificate snap-on for more advanced cert related features). 
- **RSE=8137**
- **RSEAPI=8195**
- **zOSMF=10443** 

**Example Wazi Topology**
![Diagram of deployment](vpc-gen2-example.png)
