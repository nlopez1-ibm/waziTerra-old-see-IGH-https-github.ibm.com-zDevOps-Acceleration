# todo
# + fix hosts echo - cant have dups and must be first 
# + bad port rules plus missing outboud rules 

# locals and date blocks added here as per the sample 
locals {
    BASENAME    = "nelson-dbb-terra2"
    ZONE        = "br-sao-3"
    SSH_Key     = "nelsons-pub-ssh-key" 
    image_name  = "ibm-zos-2-4-s390x-dev-test-wazi-1"
    group       = "wazi-demo-rg"  
}

# Set these data objects using the above locals  
data "ibm_is_image" "wazi"             { name = local.image_name  }
data "ibm_is_ssh_key" "ssh_key_id"     { name = local.SSH_Key }
data "ibm_resource_group" "group"      { name = local.group }

###
# define the resources 
###
resource "ibm_is_vpc" "vpc" { 
    name = "${local.BASENAME}"
    resource_group  = data.ibm_resource_group.group.id 
}

resource "ibm_is_security_group" "sg1" {
    name = "${local.BASENAME}-sg1"
    vpc  = ibm_is_vpc.vpc.id
    resource_group  = data.ibm_resource_group.group.id 
}

resource "ibm_is_subnet" "subnet1" {
    name                     = "${local.BASENAME}-subnet1"
    vpc                      = ibm_is_vpc.vpc.id
    resource_group           = data.ibm_resource_group.group.id

    zone                     = local.ZONE    
    total_ipv4_address_count = 256
}

resource "ibm_is_floating_ip" "fip1" {
    name   = "${local.BASENAME}-fip1"
    resource_group  = data.ibm_resource_group.group.id
    target = ibm_is_instance.vsi1.primary_network_interface[0].id
}


# allow all incoming network traffic from port 21 on
resource "ibm_is_security_group_rule" "ingress_ssh_all" {
    group     = ibm_is_security_group.sg1.id    
    direction = "inbound"
    remote    = "0.0.0.0/0"    
    tcp {
      port_min = 21
      port_max = 65352
    }
}

resource ibm_is_security_group_rule all_out {
    group     = ibm_is_security_group.sg1.id    
    direction = "outbound"
    remote    = "0.0.0.0/0"
}



resource "ibm_is_instance" "vsi1" {
    name    = "${local.BASENAME}-vsi1"    
    vpc     = ibm_is_vpc.vpc.id
    resource_group   = data.ibm_resource_group.group.id
    zone    = local.ZONE
    
    keys    = [data.ibm_is_ssh_key.ssh_key_id.id]
    image   = data.ibm_is_image.wazi.id
    profile = "mz2o-2x16"

    primary_network_interface {
        subnet          = ibm_is_subnet.subnet1.id
        security_groups = [ibm_is_security_group.sg1.id]
    }

    
}



### Post init stuff by Nelson 
### add the new IP to my local hosts as mywazi. Use copy to move the new IP to the top
output "Info" {
  value = <<EOT
  
    Your new VSI(${local.BASENAME}-vsi1) IP is ${ibm_is_floating_ip.fip1.address}. The IPL has started and takes about 5 mins.
    From your cloud UI, use the VSI action/serial term to view the MCS and IPL state.
    Run "terraform show" to redisplay these instructions.

    A special DEMO script (postinit) has been created to initialize a dev runtime on the new instance.
    
    The App Config script can be run from you terminal using this command"  
       call App-Iac/postinit  ${ibm_is_floating_ip.fip1.address}  

    The README.md file has more details.        
  EOT
  }     
