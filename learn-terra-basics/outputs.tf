# An output block gets resource values after they have the apply. 
# For example, getting a newly assigned floating IP for a new VPC. 

# In this case, the output block assigns the filename attribute of the 
# local_file.learning instance to the varaible outFileName which is then displayed in the cli log. 
output outFileName { value = local_file.learning.filename }
