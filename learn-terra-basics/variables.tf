# Using variables - https://learn.hashicorp.com/tutorials/terraform/aws-variables
# This form of the var function asks the user for a value 
# when no default value is give terra will prompt the user for a value
variable myContent {
  description = "Enter some data for the new file"
  type        = string  
  #default     = "Some data"
}