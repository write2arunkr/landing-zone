TF_VERSION               = "1.0"
prefix                   = "slz-arun"
region                   = "us-south"
ssh_public_key           = "ssh-rsa AAAAB4NzaC1yc2EAAAADAQABAAABgQClCvte792bvfRCQ1AGEPy/gKoiIBEGuB7cvIXWnPKz6juDfiuGovU/7af72FWDEcWLzM8z2ljgPCCvY4FYPYc+geVJAahvSESO/9JkSzChbfilDvxxNr0kocYgm2YOLKZ+ac5APS9Yocq0hHHjzqikFXENIQGb13j+LUw+RWb6yZg31m+sIRwlw0nNUvlR4/Klm4McZqMQoDwEKEbT4692ttRfjFY+yxNqidkCtbTjo3IZ3+kbzihd4Z/4iw8uff3IVvuJLuNaGwTZNDmg9o41+LIsbuSlgS9swpEkLAQLpULHtOMjmH77xDdPA2YJ+bK0yIzS/VQiqmgx84Te86InO6AtExwcA48q5kjH6S70I1IIcOnvbVGnlpOCawptLosvkzwhDXfYJO6MNrz+djmI4M8kIWVHRZGLZWD/ClFCbkJ60szpZ2qmXe3sdGFVNSzKdJL2uhGn82aIqe9gmsuKCPaXHZopN2GbdKoLr4Dg39BWzaabqKgoirc86d+hDBU= arun@aruns-mbp.in.ibm.com"
tags                     = []
vpcs                     = ["management", "workload"]
enable_transit_gateway   = true
add_atracker_route       = true
hs_crypto_instance_name  = null
hs_crypto_resource_group = null
vsi_image_name           = "ibm-ubuntu-18-04-6-minimal-amd64-2"
vsi_instance_profile     = "cx2-4x8"
vsi_per_subnet           = 1
override                 = false

##############################################################################
# F5 Deployment variables
##############################################################################
add_edge_vpc                        = false
provision_teleport_in_f5            = false
create_f5_network_on_management_vpc = false
vpn_firewall_type                   = null
f5_image_name                       = "f5-bigip-15-1-5-1-0-0-14-all-1slot"
f5_instance_profile                 = "cx2-4x8"
hostname                            = "f5-ve-01"
domain                              = "local"
tmos_admin_password                 = null
enable_f5_external_fip              = true

##############################################################################
# Bastion Host deployment
##############################################################################
use_existing_appid        = false
appid_name                = "slz-appid"
appid_resource_group      = null
teleport_instance_profile = "cx2-4x8"
teleport_vsi_image_name   = "ibm-ubuntu-18-04-6-minimal-amd64-2"
teleport_license          = null
https_cert                = null
https_key                 = null
teleport_hostname         = null
teleport_domain           = null
message_of_the_day        = null
teleport_admin_email      = null
teleport_management_zones = 0
