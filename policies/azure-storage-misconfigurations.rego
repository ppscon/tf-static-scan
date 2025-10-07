package azure.storage
# title: Azure Storage Account Must Have Soft Delete Enabled
# description: Blob soft deletion protects data from accidental deletion
# id: blobs-soft-deletion-enabled
# avd_id: AVD-AZU-0033
# severity: MEDIUM
deny[res] {
    resource := input.configuration.root_module.resources[_]
    resource.type == "azurerm_storage_account"
    resource.mode == "managed"

    not resource.expressions.blob_properties

    res := {
        "msg": sprintf("Storage account '%s' does not have blob soft delete enabled. Configure delete_retention_policy with at least 7 days.", [resource.name]),
        "severity": "MEDIUM",
        "id": "blobs-soft-deletion-enabled",
        "resource": resource.name
    }
}

deny[res] {
    resource := input.configuration.root_module.resources[_]
    resource.type == "azurerm_storage_account"
    resource.mode == "managed"

    blob_props := resource.expressions.blob_properties[0]
    not blob_props.delete_retention_policy

    res := {
        "msg": sprintf("Storage account '%s' does not have soft delete enabled. Configure delete_retention_policy.", [resource.name]),
        "severity": "MEDIUM",
        "id": "blobs-soft-deletion-enabled",
        "resource": resource.name
    }
}

deny[res] {
    resource := input.configuration.root_module.resources[_]
    resource.type == "azurerm_storage_account"
    resource.mode == "managed"

    retention := resource.expressions.blob_properties[0].delete_retention_policy[0]
    days := retention.days.constant_value

    days < 7

    res := {
        "msg": sprintf("Storage account '%s' soft delete retention is less than 7 days (currently: %d days). Increase to at least 7 days.", [resource.name, days]),
        "severity": "MEDIUM",
        "id": "blobs-soft-deletion-enabled",
        "resource": resource.name
    }
}

# METADATA
# title: Azure Storage Account Must Have Geo-Redundant Replication
# description: Ensures storage account has geo-redundant backup enabled
# id: enable-geo-redundant-backups
# avd_id: AVD-AZU-0038
# severity: HIGH
deny[res] {
    resource := input.configuration.root_module.resources[_]
    resource.type == "azurerm_storage_account"
    resource.mode == "managed"

    not resource.expressions.account_replication_type

    res := {
        "msg": sprintf("Storage account '%s' does not specify account_replication_type. Use GRS, GZRS, RA-GRS, or RA-GZRS for geo-redundancy.", [resource.name]),
        "severity": "HIGH",
        "id": "enable-geo-redundant-backups",
        "resource": resource.name
    }
}

deny[res] {
    resource := input.configuration.root_module.resources[_]
    resource.type == "azurerm_storage_account"
    resource.mode == "managed"

    replication := resource.expressions.account_replication_type.constant_value

    # Check if replication is NOT geo-redundant
    not is_geo_redundant(replication)

    res := {
        "msg": sprintf("Storage account '%s' uses '%s' replication (not geo-redundant). Change to GRS, GZRS, RA-GRS, or RA-GZRS for disaster recovery.", [resource.name, replication]),
        "severity": "HIGH",
        "id": "enable-geo-redundant-backups",
        "resource": resource.name
    }
}

is_geo_redundant(replication) {
    replication == "GRS"
}

is_geo_redundant(replication) {
    replication == "GZRS"
}

is_geo_redundant(replication) {
    replication == "RA-GRS"
}

is_geo_redundant(replication) {
    replication == "RA-GZRS"
}

# METADATA
# title: Azure Storage Account Must Have Infrastructure Encryption Enabled
# description: Ensures double encryption at rest with infrastructure-level encryption
# id: infrastructure-encryption-enabled
# avd_id: AVD-AZU-0027
# severity: HIGH
deny[res] {
    resource := input.configuration.root_module.resources[_]
    resource.type == "azurerm_storage_account"
    resource.mode == "managed"

    not resource.expressions.infrastructure_encryption_enabled

    res := {
        "msg": sprintf("Storage account '%s' does not have infrastructure encryption enabled. Set infrastructure_encryption_enabled = true for double encryption.", [resource.name]),
        "severity": "HIGH",
        "id": "infrastructure-encryption-enabled",
        "resource": resource.name
    }
}

deny[res] {
    resource := input.configuration.root_module.resources[_]
    resource.type == "azurerm_storage_account"
    resource.mode == "managed"

    resource.expressions.infrastructure_encryption_enabled.constant_value == false

    res := {
        "msg": sprintf("Storage account '%s' has infrastructure encryption explicitly disabled. Enable it for compliance.", [resource.name]),
        "severity": "HIGH",
        "id": "infrastructure-encryption-enabled",
        "resource": resource.name
    }
}

# METADATA
# title: Azure Storage Blob Container Must Use Customer-Managed Keys (CMK)
# description: Ensures blob containers are encrypted with customer-managed keys
# id: blob-container-cmk-encrypted
# severity: MEDIUM
deny[res] {
    container := input.configuration.root_module.resources[_]
    container.type == "azurerm_storage_container"
    container.mode == "managed"

    # Get storage account reference
    storage_account_ref := container.expressions.storage_account_name.references[0]

    # Find the storage account
    storage_account := input.configuration.root_module.resources[_]
    storage_account.type == "azurerm_storage_account"
    storage_account.address == storage_account_ref

    # Check if storage account has CMK encryption configured
    not storage_account.expressions.customer_managed_key

    res := {
        "msg": sprintf("Storage container '%s' belongs to storage account '%s' without customer-managed key encryption. Configure customer_managed_key block for enhanced security.", [container.name, storage_account.name]),
        "severity": "MEDIUM",
        "id": "blob-container-cmk-encrypted",
        "resource": container.name
    }
}

# METADATA
# title: Azure Storage Account Diagnostic Logging Must Be Enabled
# description: Ensures storage account has diagnostic logging enabled
# id: storage-account-logging-enabled
# severity: MEDIUM
deny[res] {
    storage_account := input.configuration.root_module.resources[_]
    storage_account.type == "azurerm_storage_account"
    storage_account.mode == "managed"

    # Check if there's a corresponding azurerm_monitor_diagnostic_setting
    storage_account_id := storage_account.address

    # Look for diagnostic setting referencing this storage account
    not has_diagnostic_setting(storage_account_id)

    res := {
        "msg": sprintf("Storage account '%s' does not have diagnostic logging configured. Create an azurerm_monitor_diagnostic_setting resource.", [storage_account.name]),
        "severity": "MEDIUM",
        "id": "storage-account-logging-enabled",
        "resource": storage_account.name
    }
}

has_diagnostic_setting(storage_account_id) {
    diagnostic := input.configuration.root_module.resources[_]
    diagnostic.type == "azurerm_monitor_diagnostic_setting"

    # Check if target_resource_id references the storage account
    diagnostic.expressions.target_resource_id.references[0] == storage_account_id
}

# METADATA
# title: Azure Storage Account Log Storage Must Be Encrypted (HTTPS Only)
# description: Ensures logs are stored securely with HTTPS enforcement
# id: log-storage-encryption
# avd_id: AVD-AZU-0010
# severity: HIGH
deny[res] {
    resource := input.configuration.root_module.resources[_]
    resource.type == "azurerm_storage_account"
    resource.mode == "managed"

    # Check if HTTPS is NOT enforced
    resource.expressions.enable_https_traffic_only.constant_value == false

    res := {
        "msg": sprintf("Storage account '%s' does not enforce HTTPS-only traffic. Enable with enable_https_traffic_only = true.", [resource.name]),
        "severity": "HIGH",
        "id": "log-storage-encryption",
        "resource": resource.name
    }
}

deny[res] {
    resource := input.configuration.root_module.resources[_]
    resource.type == "azurerm_storage_account"
    resource.mode == "managed"

    # HTTPS enforcement not explicitly set (defaults to true, but best practice to set explicitly)
    not resource.expressions.enable_https_traffic_only

    res := {
        "msg": sprintf("Storage account '%s' does not explicitly set enable_https_traffic_only. Set to true for clarity and compliance.", [resource.name]),
        "severity": "LOW",
        "id": "log-storage-encryption",
        "resource": resource.name
    }
}

# Summary count for reporting
violation_summary = {
    "total_violations": count(deny),
    "by_severity": {
        "HIGH": count([v | v := deny[_]; v.severity == "HIGH"]),
        "MEDIUM": count([v | v := deny[_]; v.severity == "MEDIUM"]),
        "LOW": count([v | v := deny[_]; v.severity == "LOW"])
    }
}
