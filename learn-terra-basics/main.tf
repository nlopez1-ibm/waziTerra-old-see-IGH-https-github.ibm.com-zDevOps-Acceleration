# *** learn terra - notes  nlopez 2022 ***

# [local plugin - section]
# *.tf files contains terraform instructions used to manage cloud resources.
# Terra uses provider plugins to drive its scripts.

# Script naming conventions are main.tf for the main script, provider.tf, variables... and a few others 

# This section uses the terra provider "local" for learning purposes. 
# Use your cloud provider plugin when ready to manage real resources. 

# The 'local' plugin executes cmds only on the local PC 

# Creating a resource.  
# In terra all main objects are defined in resource blocks (enclosed in {})
# The resource below has the name of the plugin "local" delimited by the "_" and followed but a resource type "file".
# Types are normally documented by the provider.  See https://registry.terraform.io/browse/providers
# IBM Cloud plugin is https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs

# The 'local' plugin's "file" type lets you create a local file with some attributes (or arguments) like
# "filename"  and "content". This example uses variables defined in local.tf and varaibles.tf (normal naming convention).

resource "local_file" "learning" { 
     filename = local.myFile  
     content = var.myContent


     # In addition to the local provider, the next block shows how you can embed another provider. 
     # In this case, the terraform provided 'local-exec' plugin runs a powershell cmd to cat 
     # the new files content. 
     # 
     provisioner "local-exec" {
          command = "cat ${local.myFile}"
          interpreter = ["PowerShell", "-Command"]
  }
}

# To test the above run  the cli cmd 'terraform init' followed byt plan and apply.   
# A file is created wit hthe name in the locals file with data propvide by the user. 

# Run destroy to remove all resources - in this case the file will be delete.