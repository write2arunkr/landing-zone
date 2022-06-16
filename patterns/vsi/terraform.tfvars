TF_VERSION               = "1.0"
prefix                   = "slz-arun"
region                   = "us-south"
ssh_public_key           = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCx+OX7RaDXKP0ZbqJ4GdNrZ6z2U8RDXb8sy+eG1K1lyERblS9RE1B1V75zCjukEoarwKOoasM5ApM9SJ5tzqr6R0aIjk4/BUESNmMCB99e3jttwNCFf50MpSA43inFU+iFBPAL3ZVE2HBrCVyz+OBW14Fjpo/J2yZr989XOy96VpfwGYXN/ZYgGO8y3+iikU5GvwnOvLguGjTaRi0GlHdatY9HWBEa+qYa2i6xfMlVQMxPH0qqcRLW1LMCmcvKtcsK4yB2DKspzuH3Bn6Wef3SJIzGbd3+ZFE+sHoAwfiYqlHji90dckf5UQesFtlDNeBSjrWqtSV23frbCLMzlN97 root@livecrosswalks"
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
