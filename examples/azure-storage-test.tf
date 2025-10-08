# Test Azure Storage Account Configurations
# This file contains INTENTIONAL misconfigurations to test REGO policies

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}

  # Allow running without Azure authentication for static analysis
  skip_provider_registration = true
  use_cli                    = false
  use_msi                    = false
  use_oidc                   = false
}

# ❌ BAD: Missing blob service logging
resource "azurerm_storage_account" "bad_no_logging" {
  name                     = "storagenologging"
  resource_group_name      = "test-rg"
  location                 = "East US"
  account_tier             = "Standard"
  account_replication_type = "LRS"  # ❌ Not geo-redundant

  # Missing: blob_properties with logging
  # Missing: infrastructure_encryption_enabled
}

# ❌ BAD: Has blob properties but no soft delete configured
resource "azurerm_storage_account" "bad_no_blob_logging" {
  name                     = "storagenobloblog"
  resource_group_name      = "test-rg"
  location                 = "East US"
  account_tier             = "Standard"
  account_replication_type = "GRS"  # ✅ Geo-redundant

  blob_properties {
    # ❌ Missing: delete_retention_policy (soft delete)
  }
}

# ❌ BAD: Soft delete retention too short
resource "azurerm_storage_account" "bad_incomplete_logging" {
  name                     = "storageincomplete"
  resource_group_name      = "test-rg"
  location                 = "East US"
  account_tier             = "Standard"
  account_replication_type = "GZRS"  # ✅ Geo-redundant

  blob_properties {
    delete_retention_policy {
      days = 3  # ❌ Less than 7 days
    }
  }
}

# ❌ BAD: No soft delete enabled
resource "azurerm_storage_account" "bad_no_soft_delete" {
  name                     = "storagenosoftdel"
  resource_group_name      = "test-rg"
  location                 = "East US"
  account_tier             = "Standard"
  account_replication_type = "GRS"

  blob_properties {
    # ❌ Missing: delete_retention_policy
  }
}

# ❌ BAD: No infrastructure encryption
resource "azurerm_storage_account" "bad_no_infra_encryption" {
  name                     = "storagenoinfraenc"
  resource_group_name      = "test-rg"
  location                 = "East US"
  account_tier             = "Standard"
  account_replication_type = "GRS"

  infrastructure_encryption_enabled = false  # ❌ Explicitly disabled

  blob_properties {
    delete_retention_policy {
      days = 30
    }
  }
}

# ❌ BAD: No diagnostic settings (storage account logging)
resource "azurerm_storage_account" "bad_no_diagnostic_logging" {
  name                     = "storagenodiaglog"
  resource_group_name      = "test-rg"
  location                 = "East US"
  account_tier             = "Standard"
  account_replication_type = "GRS"

  blob_properties {
    delete_retention_policy {
      days = 30
    }
  }
}

# Note: Missing azurerm_monitor_diagnostic_setting for the above storage account

# ❌ BAD: No customer-managed key encryption
resource "azurerm_storage_account" "bad_no_cmk" {
  name                     = "storagenocmk"
  resource_group_name      = "test-rg"
  location                 = "East US"
  account_tier             = "Standard"
  account_replication_type = "GRS"

  # ❌ Missing: customer_managed_key block

  blob_properties {
    delete_retention_policy {
      days = 30
    }
  }
}

# ❌ BAD: Blob container without CMK
resource "azurerm_storage_container" "bad_container" {
  name                  = "testcontainer"
  storage_account_name  = azurerm_storage_account.bad_no_cmk.name
  container_access_type = "private"
}

# ✅ GOOD: Properly configured storage account
resource "azurerm_storage_account" "good_storage" {
  name                     = "storagegood"
  resource_group_name      = "test-rg"
  location                 = "East US"
  account_tier             = "Standard"
  account_replication_type = "GZRS"  # ✅ Geo-redundant

  infrastructure_encryption_enabled = true  # ✅ Infrastructure encryption
  enable_https_traffic_only        = true  # ✅ HTTPS only

  blob_properties {
    delete_retention_policy {
      days = 30  # ✅ Soft delete enabled (30 days)
    }
  }

  # Note: In real config, add customer_managed_key block here
}

# ✅ GOOD: Diagnostic logging configured
resource "azurerm_monitor_diagnostic_setting" "good_storage_logs" {
  name               = "storage-diagnostics"
  target_resource_id = azurerm_storage_account.good_storage.id

  storage_account_id = azurerm_storage_account.good_storage.id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  metric {
    category = "Transaction"
    enabled  = true
  }
}
