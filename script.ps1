# Define a list of regions
$regions = @("eastus", "westus", "centralus", "northcentralus", "southcentralus", "westcentralus", "canadaeast", "canadacentral", "eastus2", "centraluseuap", "northcentralus", "southcentralus", "westcentralus", "eastus2euap", "westus2", "westus2euap", "brazilsouth", "brazilsoutheast", "northeurope", "westeurope", "ukwest", "uksouth", "francecentral", "francesouth", "norwayeast", "norwaywest", "swedencentral", "swedeneast", "eastasia", "southeastasia", "japaneast", "japanwest", "australiaeast", "australiasoutheast", "australiacentral", "australiacentral2", "centralindia", "southindia", "westindia", "koreacentral", "koreasouth", "chinaeast", "chinanorth", "chinanortheast", "chinaeast2", "chinaNorth2", "eastus3", "southafricawest", "southafricaNorth", "uaeNorth", "uaesouth", "europeNorth", "europewest", "switzerlandnorth", "switzerlandwest", "germanynorth", "germanynortheast", "finlandcentral", "finlandnorth", "greececentral", "greeceeast", "turkeywest", "turkeynorth")

# Loop through regions and run Terraform commands
foreach ($region in $regions) {
    # Create a new workspace
    & terraform workspace new $region
    terraform import azurerm_resource_group.slogr /subscriptions/1fe36de8-15e7-4b04-bb85-162d36020b2d/resourceGroups/slogr-resources

    # Set workspace-specific variables, if needed
    # Example: & terraform.exe workspace select $region -var="location=$region"

    # Initialize and apply the configuration for the workspace
    & terraform init
    & terraform apply -auto-approve
}