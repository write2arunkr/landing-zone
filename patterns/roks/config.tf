##############################################################################
# Create Pattern Dynamic Variables
# > Values are created inside the `dynamic_modules/` module to allow them to
#   be tested
##############################################################################

module "dynamic_values" {
  source                              = "./dynamic_values"
  prefix                              = var.prefix
  region                              = var.region
  tags                                = var.tags
  network_cidr                        = var.network_cidr
  vpcs                                = var.vpcs
  enable_transit_gateway              = var.enable_transit_gateway
  add_atracker_route                  = var.add_atracker_route
  hs_crypto_instance_name             = var.hs_crypto_instance_name
  hs_crypto_resource_group            = var.hs_crypto_resource_group
  cluster_zones                       = var.cluster_zones
  kube_version                        = var.kube_version
  flavor                              = var.flavor
  workers_per_zone                    = var.workers_per_zone
  entitlement                         = var.entitlement
  wait_till                           = var.wait_till
  update_all_workers                  = var.update_all_workers
  add_edge_vpc                        = var.add_edge_vpc
  create_f5_network_on_management_vpc = var.create_f5_network_on_management_vpc
  provision_teleport_in_f5            = var.provision_teleport_in_f5
  vpn_firewall_type                   = var.vpn_firewall_type
  f5_image_name                       = var.f5_image_name
  f5_instance_profile                 = var.f5_instance_profile
  app_id                              = var.app_id
  enable_f5_management_fip            = var.enable_f5_management_fip
  enable_f5_external_fip              = var.enable_f5_external_fip
  teleport_management_zones           = var.teleport_management_zones
  use_existing_appid                  = var.use_existing_appid
  appid_resource_group                = var.appid_resource_group
  teleport_instance_profile           = var.teleport_instance_profile
  teleport_vsi_image_name             = var.teleport_vsi_image_name
  domain                              = var.domain
  hostname                            = var.hostname
}

##############################################################################


##############################################################################
# Dynamically Create Default Configuration
##############################################################################

locals {
  # If override is true, parse the JSON from override.json otherwise parse empty string
  # Empty string is used to avoid type conflicts with unary operators
  override = jsondecode(var.override ? file("./override.json") : "{}")

  ##############################################################################
  # Dynamic configuration for landing zone environment
  ##############################################################################

  config = {

    ##############################################################################
    # Cluster Config
    ##############################################################################
    clusters = [
      # Dynamically create identical cluster in each VPC
      for network in var.vpcs :
      {
        name     = "${network}-cluster"
        vpc_name = network
        subnet_names = [
          # For the number of zones in zones variable, get that many subnet names
          for zone in range(1, var.cluster_zones + 1) :
          "vsi-zone-${zone}"
        ]
        kms_config = {
          crk_name         = "${var.prefix}-roks-key"
          private_endpoint = true
        }
        workers_per_subnet = var.workers_per_zone
        machine_type       = var.flavor
        kube_type          = "openshift"
        kube_version       = var.kube_version
        resource_group     = "${var.prefix}-${network}-rg"
        update_all_workers = var.update_all_workers
        cos_name           = "cos"
        entitlement        = var.entitlement
        # By default, create dedicated pool for logging
        worker_pools = [
          # {
          #   name     = "logging-worker-pool"
          #   vpc_name = network
          #   subnet_names = [
          #     for zone in range(1, var.cluster_zones + 1) :
          #     "vsi-zone-${zone}"
          #   ]
          #   entitlement        = var.entitlement
          #   workers_per_subnet = var.workers_per_zone
          #   flavor             = var.flavor
          # }
        ]
      }
    ]
    ##############################################################################

    ##############################################################################
    # Activity tracker
    ##############################################################################
    atracker = {
      resource_group        = "${var.prefix}-service-rg"
      receive_global_events = true
      collector_bucket_name = "atracker-bucket"
      add_route             = var.add_atracker_route
    }
    ##############################################################################

    ##############################################################################
    # Default SSH key
    ##############################################################################
    ssh_keys = var.teleport_management_zones > 0 || var.provision_teleport_in_f5 ? [
      {
        name       = "ssh-key"
        public_key = var.ssh_public_key
      }
    ] : []
    ##############################################################################

    ##############################################################################
    # VPE
    ##############################################################################
    virtual_private_endpoints = [{
      service_name = "cos"
      service_type = "cloud-object-storage"
      vpcs = [
        # Create VPE for each VPC in VPE tier
        for network in module.dynamic_values.vpc_list :
        {
          name    = network
          subnets = ["vpe-zone-1", "vpe-zone-2", "vpe-zone-3"]
        }
      ]
    }]
    ##############################################################################

    ##############################################################################
    # Deployment Configuration From Dynamic Values
    ##############################################################################

    resource_groups                = module.dynamic_values.resource_groups
    vpcs                           = module.dynamic_values.vpcs
    enable_transit_gateway         = true
    transit_gateway_resource_group = "${var.prefix}-service-rg"
    transit_gateway_connections    = module.dynamic_values.vpc_list
    object_storage                 = module.dynamic_values.object_storage
    key_management                 = module.dynamic_values.key_management
    vpn_gateways                   = module.dynamic_values.vpn_gateways
    f5_deployments                 = module.dynamic_values.f5_deployments
    security_groups                = module.dynamic_values.security_groups
    vsi                            = []

    ##############################################################################

    ##############################################################################
    # IAM Account Settings
    ##############################################################################
    iam_account_settings = {
      enable = false
    }
    access_groups = [
      # for group in ["admin", "operate", "viewer"]:
      # {
      #   name = group
      #   description = "Template access group for ${group}"
      #   policies = [
      #     {
      #       name = "${group}-policy"
      #       roles = [
      #         lookup({
      #           admin = "Administrator"
      #           operate = "Operator"
      #           viewer = "Viewer"
      #         }, group)
      #       ]
      #       resources = {
      #         resource = "is"
      #       }
      #     }
      #   ]
      # }
    ]
    ##############################################################################

    ##############################################################################
    # Appid config
    ##############################################################################

    appid = {
      name           = var.appid_name
      use_data       = var.use_existing_appid
      resource_group = var.appid_resource_group == null ? "${var.prefix}-service-rg" : var.appid_resource_group
      use_appid      = var.teleport_management_zones > 0 || var.provision_teleport_in_f5
      keys           = ["slz-appid-key"]
    }

    ##############################################################################

    ##############################################################################
    # Teleport Config Data
    ##############################################################################

    teleport_config = {
      teleport_license   = var.teleport_license
      https_cert         = var.https_cert
      https_key          = var.https_key
      domain             = var.teleport_domain
      cos_bucket_name    = "bastion-bucket"
      cos_key_name       = "bastion-key"
      teleport_version   = var.teleport_version
      message_of_the_day = var.message_of_the_day
      app_id_key_name    = "slz-appid-key"
      hostname           = var.teleport_hostname
      claims_to_roles = [
        {
          email = var.teleport_admin_email
          roles = ["teleport-admin"]
        }
      ]
    }

    teleport_vsi = module.dynamic_values.teleport_vsi

    ##############################################################################

    ##############################################################################
    # Secrets Manager Config
    ##############################################################################

    secrets_manager = {
      use_secrets_manager = var.create_secrets_manager
      name                = var.create_secrets_manager ? "${var.prefix}-secrets-manager" : null
      resource_group      = var.create_secrets_manager ? "${var.prefix}-service-rg" : null
      kms_key_name        = var.create_secrets_manager ? "${var.prefix}-slz-key" : null
    }

    ##############################################################################
  }

  ##############################################################################
  # Compile Environment for Config output
  ##############################################################################
  env = {
    resource_groups                = lookup(local.override, "resource_groups", local.config.resource_groups)
    vpcs                           = lookup(local.override, "vpcs", local.config.vpcs)
    vpn_gateways                   = lookup(local.override, "vpn_gateways", local.config.vpn_gateways)
    enable_transit_gateway         = lookup(local.override, "enable_transit_gateway", local.config.enable_transit_gateway)
    transit_gateway_resource_group = lookup(local.override, "transit_gateway_resource_group", local.config.transit_gateway_resource_group)
    transit_gateway_connections    = lookup(local.override, "transit_gateway_connections", local.config.transit_gateway_connections)
    ssh_keys                       = lookup(local.override, "ssh_keys", local.config.ssh_keys)
    network_cidr                   = lookup(local.override, "network_cidr", var.network_cidr)
    vsi                            = lookup(local.override, "vsi", local.config.vsi)
    security_groups                = lookup(local.override, "security_groups", local.config.security_groups)
    virtual_private_endpoints      = lookup(local.override, "virtual_private_endpoints", local.config.virtual_private_endpoints)
    cos                            = lookup(local.override, "cos", local.config.object_storage)
    service_endpoints              = lookup(local.override, "service_endpoints", "private")
    key_management                 = lookup(local.override, "key_management", local.config.key_management)
    atracker                       = lookup(local.override, "atracker", local.config.atracker)
    clusters                       = lookup(local.override, "clusters", local.config.clusters)
    wait_till                      = lookup(local.override, "wait_till", "IngressReady")
    iam_account_settings           = lookup(local.override, "iam_account_settings", local.config.iam_account_settings)
    access_groups                  = lookup(local.override, "access_groups", local.config.access_groups)
    appid                          = lookup(local.override, "appid", local.config.appid)
    secrets_manager                = lookup(local.override, "secrets_manager", local.config.secrets_manager)
    f5_vsi                         = lookup(local.override, "f5_vsi", local.config.f5_deployments)
    f5_template_data = {
      tmos_admin_password     = lookup(local.override, "f5_template_data", null) == null ? var.tmos_admin_password : lookup(local.override.f5_template_data, "tmos_admin_password", var.tmos_admin_password)
      license_type            = lookup(local.override, "f5_template_data", null) == null ? var.license_type : lookup(local.override.f5_template_data, "license_type", var.license_type)
      byol_license_basekey    = lookup(local.override, "f5_template_data", null) == null ? var.byol_license_basekey : lookup(local.override.f5_template_data, "byol_license_basekey", var.byol_license_basekey)
      license_host            = lookup(local.override, "f5_template_data", null) == null ? var.license_host : lookup(local.override.f5_template_data, "license_host", var.license_host)
      license_username        = lookup(local.override, "f5_template_data", null) == null ? var.license_username : lookup(local.override.f5_template_data, "license_username", var.license_username)
      license_password        = lookup(local.override, "f5_template_data", null) == null ? var.license_password : lookup(local.override.f5_template_data, "license_password", var.license_password)
      license_pool            = lookup(local.override, "f5_template_data", null) == null ? var.license_pool : lookup(local.override.f5_template_data, "license_pool", var.license_pool)
      license_sku_keyword_1   = lookup(local.override, "f5_template_data", null) == null ? var.license_sku_keyword_1 : lookup(local.override.f5_template_data, "license_sku_keyword_1", var.license_sku_keyword_1)
      license_sku_keyword_2   = lookup(local.override, "f5_template_data", null) == null ? var.license_sku_keyword_2 : lookup(local.override.f5_template_data, "license_sku_keyword_2", var.license_sku_keyword_2)
      license_unit_of_measure = lookup(local.override, "f5_template_data", null) == null ? var.license_unit_of_measure : lookup(local.override.f5_template_data, "license_unit_of_measure", var.license_unit_of_measure)
      do_declaration_url      = lookup(local.override, "f5_template_data", null) == null ? var.do_declaration_url : lookup(local.override.f5_template_data, "do_declaration_url", var.do_declaration_url)
      as3_declaration_url     = lookup(local.override, "f5_template_data", null) == null ? var.as3_declaration_url : lookup(local.override.f5_template_data, "as3_declaration_url", var.as3_declaration_url)
      ts_declaration_url      = lookup(local.override, "f5_template_data", null) == null ? var.ts_declaration_url : lookup(local.override.f5_template_data, "ts_declaration_url", var.ts_declaration_url)
      phone_home_url          = lookup(local.override, "f5_template_data", null) == null ? var.phone_home_url : lookup(local.override.f5_template_data, "phone_home_url", var.phone_home_url)
      template_source         = lookup(local.override, "f5_template_data", null) == null ? var.template_source : lookup(local.override.f5_template_data, "template_source", var.template_source)
      template_version        = lookup(local.override, "f5_template_data", null) == null ? var.template_version : lookup(local.override.f5_template_data, "template_version", var.template_version)
      app_id                  = lookup(local.override, "f5_template_data", null) == null ? var.app_id : lookup(local.override.f5_template_data, "app_id", var.app_id)
      tgactive_url            = lookup(local.override, "f5_template_data", null) == null ? var.tgactive_url : lookup(local.override.f5_template_data, "tgactive_url", var.tgactive_url)
      tgstandby_url           = lookup(local.override, "f5_template_data", null) == null ? var.tgstandby_url : lookup(local.override.f5_template_data, "tgstandby_url", var.tgstandby_url)
      tgrefresh_url           = lookup(local.override, "f5_template_data", null) == null ? var.tgrefresh_url : lookup(local.override.f5_template_data, "tgrefresh_url", var.tgrefresh_url)
    }
    teleport_vsi = lookup(local.override, "teleport_vsi", local.config.teleport_vsi)
    teleport_config = {
      teleport_license   = lookup(local.override, "teleport_config", null) == null ? local.config.teleport_config.teleport_license : lookup(local.override.teleport_config, "teleport_license", local.config.teleport_config.teleport_license)
      https_cert         = lookup(local.override, "teleport_config", null) == null ? local.config.teleport_config.https_cert : lookup(local.override.teleport_config, "https_cert", local.config.teleport_config.https_cert)
      https_key          = lookup(local.override, "teleport_config", null) == null ? local.config.teleport_config.https_key : lookup(local.override.teleport_config, "https_key", local.config.teleport_config.https_key)
      domain             = lookup(local.override, "teleport_config", null) == null ? local.config.teleport_config.domain : lookup(local.override.teleport_config, "domain", local.config.teleport_config.domain)
      cos_bucket_name    = lookup(local.override, "teleport_config", null) == null ? local.config.teleport_config.cos_bucket_name : lookup(local.override.teleport_config, "cos_bucket_name", local.config.teleport_config.cos_bucket_name)
      cos_key_name       = lookup(local.override, "teleport_config", null) == null ? local.config.teleport_config.cos_key_name : lookup(local.override.teleport_config, "cos_key_name", local.config.teleport_config.cos_key_name)
      teleport_version   = lookup(local.override, "teleport_config", null) == null ? local.config.teleport_config.teleport_version : lookup(local.override.teleport_config, "teleport_version", local.config.teleport_config.teleport_version)
      message_of_the_day = lookup(local.override, "teleport_config", null) == null ? local.config.teleport_config.message_of_the_day : lookup(local.override.teleport_config, "message_of_the_day", local.config.teleport_config.message_of_the_day)
      app_id_key_name    = lookup(local.override, "teleport_config", null) == null ? local.config.teleport_config.app_id_key_name : lookup(local.override.teleport_config, "app_id_key_name", local.config.teleport_config.app_id_key_name)
      hostname           = lookup(local.override, "teleport_config", null) == null ? local.config.teleport_config.hostname : lookup(local.override.teleport_config, "hostname", local.config.teleport_config.hostname)
      claims_to_roles    = lookup(local.override, "teleport_config", null) == null ? local.config.teleport_config.claims_to_roles : lookup(local.override.teleport_config, "claims_to_roles", local.config.teleport_config.claims_to_roles)
    }
  }
  ##############################################################################

  string = "\"${jsonencode(local.env)}\""
}

##############################################################################

##############################################################################
# Convert Environment to escaped readable string
##############################################################################

data "external" "format_output" {
  program = ["python3", "${path.module}/scripts/output.py", local.string]
}

##############################################################################


##############################################################################
# Conflicting Variable Failure States
##############################################################################

locals {
  # Prevent users from inputting conflicting variables by checking regex
  # causeing plan to fail when true. 
  # > if both are false will pass
  # > if only one is true will pass
  fail_with_conflicting_bastion = regex("false", tostring(
    var.add_edge_vpc == false && var.create_f5_network_on_management_vpc == false
    ? false
    : var.add_edge_vpc == var.create_f5_network_on_management_vpc
  ))

  # Prevent users from provisioning bastion subnets without a tier selected
  fail_with_no_vpn_firewall_type = regex("false", tostring(
    var.vpn_firewall_type == null && var.provision_teleport_in_f5
  ))

  # Prevent users from provisioning using both external and management fip
  # VSI can only have one floating IP per device
  fail_with_both_f5_fip = regex("false", tostring(
    var.enable_f5_management_fip == true && var.enable_f5_external_fip == true
  ))

  # Prevent users from provisioning bastion on edge and management
  fail_with_both_bastion_host_types = regex("false", tostring(
    var.provision_teleport_in_f5 && var.teleport_management_zones > 0
  ))

}

##############################################################################