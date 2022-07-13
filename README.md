# Learn Terraform for Wazi aaS basics - by NLopez 
This repo has 2 main folders to help you learn how terraform can be used to create a new wazi aaS instance using you IBM Cloud account. 

The 'learn-terra-basic' give a highlevel overview of the scripting lanugae using local resources.  
The 'learn-terra-wazi' is a more advanced script to create a wazi instance using the 'sepcial' beta release.  


## The basics folder 
This project folder has a few sample *.tf files.  They  provide basic getting started tips on how to use HashiCorp's Terraform HCL scripting language. For more on getting started see https://learn.hashicorp.com/collections/terraform/cli


## [install terraform on windows] 
- Install terra for windows https://releases.hashicorp.com/terraform/1.2.4/  (or any supported OS)
- Add the executable to the path using (Windows) setx PATH ...
- Then run this tewrraform from this project folder script to see how it works.  
- A nice to have is the vsCode extension https://marketplace.visualstudio.com/items?itemName=HashiCorp.terraformthe 

>TIP: In vsCode, run terraform cli by right clicking the project folder and "Open in Intergrated terminal" to run the cli. 

## After the install
Use this project or create your own with any name to hold your .tf scripts. From the cli, run terraform cmds like  -  'terraform init', plan, apply, show, destroy  

>TIP: To skip the interactive "enter yes" prompt during an 'apply', run 'terraform apply -auto-approve'

Terra tracks diff's between applys to keep thing up to date.

To build a cloud resource you'll need to setx  your cloud acct's api as an env var IC_API_Key (or add the key in a script)

To start learning, open the sample main.tf file and follow the notes. 

For more on IBM's Terraform plugin see the VPC infrastructure topic in:
   IBM Cloud plugin is https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs


## The Advanced folder  - Create a Wazi aaS instance for DBB Builds
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


## Example deployment diagram
The default deployment will look something like this:

![Diagram of deployment](vpc-gen2-example.png)
