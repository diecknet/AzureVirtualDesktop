<#
.SYNOPSIS
  Deploys an Azure NAT-Gateway to route all AVD host traffic out of a single public IP.
.DESCRIPTION
  Deploys an Azure NAT-Gateway with static IP-Address into an Azure Resource Group. Sets the created Gateway as the Gateway for the Subnet. 
  If the Virtual Network and Subnet resources are not specified, the script tries to determine them automatically.

  The logic to determine the correct Virtual Network is:
    1. Retrieve all Virtual Networks in the Resource Group
    2. Assume that the first Virtual Network without "aadds" (Azure Active Directory Domain Services) in the name is correct.

  The logic to determine the correct Subnet is:
    1. Retrieve all Subnets for the Virtual Network
    2. Assume that the first Subnet without "aadds" (Azure Active Directory Domain Services) in the name is correct.

  This script was initially created as a submission for the Nerdio Hackathon in June 2021. #NerdioHack2021

  Hint: Log in first with Connect-AzAccount if not using Azure Cloud Shell
.INPUTS
  None
.OUTPUTS
  None
.NOTES
  Version:        1.0
  Author:         Andreas Dieckmann
  Creation Date:  2021-06-24
  GitHub:         https://github.com/diecknet/AzureVirtualDesktop
  Blog:           https://diecknet.de
  License:        MIT License

  Copyright (c) 2021 Andreas Dieckmann

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
.LINK 
  https://diecknet.de/
.LINK
  https://github.com/diecknet/AzureVirtualDesktop
.LINK
  https://docs.microsoft.com/en-us/azure/governance/resource-graph/first-query-rest-api#rest-api-and-powershell
.EXAMPLE
  .\Deploy-NATGatewayAVD.ps1 -AzureSubscriptionId 11111111-aaaa-1111-aaaa-111111111111 -AzureResourceGroupName WVD-RG-01 -AzureRegion westeurope
  Creates a new NAT-Gateway and Public IP Address with default names in the specified Subscription/Resource Group/Region. The script tries to figure out the correct Virtual Network and Subnet to use.
.EXAMPLE
  .\Deploy-NATGatewayAVD.ps1 -AzureSubscriptionId 11111111-aaaa-1111-aaaa-111111111111 -AzureResourceGroupName WVD-RG-01 -AzureRegion westeurope -NewGatewayName WVD-Outbound -NewPublicIPName WVD-PublicIP
  Creates a new NAT-Gateway named "WVD-Outbound" and an IP-Address resource named "WVD-PublicIP" in the specified Subscription/Resource Group/Region. The script tries to figure out the correct Virtual Network and Subnet to use.
.EXAMPLE
  .\Deploy-NATGatewayAVD.ps1 -AzureSubscriptionId 11111111-aaaa-1111-aaaa-111111111111 -AzureResourceGroupName WVD-RG-01 -AzureRegion westeurope -AzureVirtualNetwork WVD-Network -AzureSubnet WVD-Subnet
  Creates a new NAT-Gateway and Public IP Address with default names in the specified Subscription/Resource Group/Region. The script uses the given Virtual Network and Subnet.
#>
Param
    (
        # Azure Subscription Identifier (NOT Azure AD Tenant ID)
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$false,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0)]
        [ValidatePattern('^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$')]
        $AzureSubscriptionId,
        # Name of the Azure Resource Group where the NAT-Gateway should get deployed
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$false,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0)]
        [ValidatePattern('^[-\w\._\(\)]+$')]
        $AzureResourceGroupName,
        # Codename of the Azure Region where the NAT-Gateway should get deployed. You can retrieve a list of the regions with 'Get-AzLocation'.
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$false,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0)]
        [ValidatePattern('^[\w]+$')]
        $AzureRegionName,
        # Specify the name of the NAT-Gateway that gets created, defaults to 'AVD-NAT-Gateway1' if not specified.
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$false,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0)]
        [ValidatePattern('^[-\w\._\(\)]+$')]
        $NewGatewayName='AVD-NAT-Gateway1',
        # Specify the name of the Public IP Address resource that gets created, defaults to 'AVD-NAT-Gateway1-PublicIP1' if not specified.
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$false,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0)]
        [ValidatePattern('^[-\w\._\(\)]+$')]
        $NewPublicIPName='AVD-NAT-Gateway1-PublicIP1',
        # Specify the name of the Azure Virtual Network resource where the NAT-Gateway should get created. If not specified the script tries to automatically determine.
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$false,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0)]
        [ValidatePattern('^[-\w\._\(\)]+$')]
        $AzureVirtualNetwork,
        # Specify the name of the Azure Subnet resource to connect the new NAT-Gateway to. If not specified the script tries to automatically determine.
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$false,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0)]
        [ValidatePattern('^[-\w\._\(\)]+$')]
        $AzureSubnet
    )

# Start of the script

try {
    # Trying to use an existing connection to Azure to acquire an Access Token. Using that Access Token to list the subscription details. If that fails, the authentication probably failed.
    $azContext = Get-AzContext
    $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
    $token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
    $authHeader = @{
        'Content-Type'='application/json'
        'Authorization'='Bearer ' + $token.AccessToken
    }
    # Invoke REST API to test Authentication header
    $restUri = 'https://management.azure.com/subscriptions/{0}?api-version=2020-01-01' -f $AzureSubscriptionId
    Write-Verbose "Calling REST API to test authentication header"
    $authResponse = Invoke-RestMethod -Uri $restUri -Method GET -Headers $authHeader
    Write-Verbose "Authentication Response: $($authResponse)"
} catch {
    $ErrorMessage = $_.Exception.Message
    Write-Error "Authentication to Azure failed. $($ErrorMessage)" -ErrorAction Stop
    return 1
}

if(!$AzureVirtualNetwork) {
    # If the user didn't specify the Azure Virtual Network  
    try {
        # Trying to figure out which virtual network to use, if not provided
        $restUri = 'https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Network/virtualNetworks?api-version=2020-11-01' -f $AzureSubscriptionId,$AzureResourceGroupName
        Write-Verbose "Calling REST API to find virtual network in resource group"
        $vnetResponse = Invoke-RestMethod -Uri $restUri -Method GET -Headers $authHeader
        foreach($response in $vnetResponse.value) {
            # looping through the response, because there might be more than one vnet
            Write-Verbose "Vnet response: $($response)"
        }
        # Filter out virtual networks with "aadds" in the name, since those are probably used by Azure AD Domain Services. Use the first result.
        $AzureVirtualNetwork = ($vnetResponse.value | Where-Object {$_.name -notlike "*aadds*"} | Select-Object -First 1).name
        Write-Verbose "Virtual network: $($AzureVirtualNetwork)"
        # If no subnet is defined by the user, trying to find a subnet for this vnet
        if(!$AzureSubnet) {
            # Pick a subnet which has an ip configuration (hence, it's used). Use the first result.
            $AzureSubnetDetails = (($vnetResponse.value | Where-Object {$_.name -notlike "*aadds*"} | Select-Object -First 1).properties.subnets) | Where-Object {$_.properties.ipconfigurations} | Select-Object -First 1
            Write-Verbose "Subnet: $($AzureSubnetDetails)"
        }    
    } catch {
        $ErrorMessage = $_.Exception.Message
        Write-Error "Failed to find virtual network or subnet in resource group. $($ErrorMessage)" -ErrorAction Stop
        return 1
    }
}

if(!$AzureSubnetDetails) {
    # If the script did not determine the details of the subnet yet.
    try {
        # Trying to retrieve details for the subnet, if we don't have them yet. If we don't know the subnet name yet, we pick the most likely subnet automatically.
        $restUri = 'https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Network/virtualNetworks/{2}/subnets?api-version=2020-11-01' -f $AzureSubscriptionId,$AzureResourceGroupName,$AzureVirtualNetwork
        Write-Verbose "Calling REST API to find subnet in virtual network"
        $subnetResponse = Invoke-RestMethod -Uri $restUri -Method GET -Headers $authHeader
        foreach($response in $subnetResponse.value) {
            # looping through the response, because there might be more than one subnet
            Write-Verbose "Subnet response: $($response)"
        }
        Write-Verbose "Filtering subnet result..."
        if($AzureSubnet) {
            # if we have a subnet name specified by the user, we take the details for that.
            $AzureSubnetDetails = ($subnetResponse.value | Where-Object {$_.name -like "$($AzureSubnet)"} | Select-Object -First 1)
        } else {
            # If we don't know the name of the subnet:
            # Filter out subnets with "aadds" in the name, since those are probably used by Azure AD Domain Services
            # Pick a subnet which has an ip configuration (hence, it's used). Use the first result.
            $AzureSubnetDetails = ($subnetResponse.value | Where-Object {$_.name -notlike "*aadds*" -and $_.properties.ipconfigurations.id} | Select-Object -First 1)
        }
        Write-Verbose "Subnet details: $($AzureSubnetDetails)"
    } catch {
        $ErrorMessage = $_.Exception.Message
        Write-Error "Failed to retrieve subnet info in virtual network. $($ErrorMessage)" -ErrorAction Stop
        return 1
    }
}

if(!$AzureSubnetDetails) {
    # if we still don't know the subnet, then something went wrong. Can't continue.
    Write-Error "Failed to retrieve subnet info in virtual network. $($ErrorMessage)" -ErrorAction Stop
    return 1
}

try {
    # Trying to create a Public IP Address resource
    $restUri='https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Network/publicIPAddresses/{2}?api-version=2020-11-01' -f $AzureSubscriptionId, $AzureResourceGroupName, $NewPublicIPName
    $requestBody = "{
                        'location': '$($AzureRegionName)',
                        'sku': {
                            'name': 'Standard'
                        },
                        'properties': {
                            'publicIPAllocationMethod': 'Static'
                        }
                    }"
    Write-Verbose "Calling REST-API to create new public IP-Address resource '$($NewPublicIPName)'."
    $newPublicIpResponse = Invoke-RestMethod -Uri $restUri -Method PUT -Headers $authHeader -Body $requestBody
    Write-Verbose "Result: $($newPublicIPresponse)"
} catch {
    $ErrorMessage = $_.Exception.Message
    Write-Error "Creating Public IP resource in Azure failed. $($ErrorMessage)" -ErrorAction Stop
    return 1
}

try {
    # Trying to create NAT Gateway with public IP-Address associated
    $restUri = 'https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Network/natGateways/{2}?api-version=2021-02-01' -f $AzureSubscriptionId, $AzureResourceGroupName, $NewGatewayName
    $requestBody = "{
                        'location': '$($AzureRegionName)',
                        'sku': {
                            'name': 'Standard'
                        },
                        'properties': {
                            'publicIpAddresses': [
                                {
                                    'id': '$($newPublicIpResponse.id)'
                                }
                            ]
                        }
                    }"
    Write-Verbose "Calling REST-API to create new NAT-Gateway resource '$($NewGatewayName)'."
    $newNATGatewayResponse = Invoke-RestMethod -Uri $restUri -Method PUT -Headers $authHeader -Body $requestBody
    Write-Verbose "Result: $($newNATGatewayResponse)"                    
} catch {
    $ErrorMessage = $_.Exception.Message
    Write-Error "Creating NAT-Gateway resource in Azure failed. $($ErrorMessage)" -ErrorAction Stop
    return 1
}

try {
    # Trying to set the previously created NAT-Gateway as the Gateway for the subnet
    # Before we do so, we wait for 60 seconds to wait for the resources to be ready
    Write-Output "Waiting for the resources to get created and propagated (5 Minutes, until $((Get-Date).AddMinutes(5)))..."
    Start-Sleep -Seconds 300

    $restUri = 'https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Network/virtualNetworks/{2}/subnets/{3}?api-version=2020-11-01' -f $AzureSubscriptionId,$AzureResourceGroupName,$AzureVirtualNetwork,($AzureSubnetDetails.Name)
    $requestBody = "{   
                        'id': '$($AzureSubnetDetails.id)',
                        'properties': {
                            'natGateway': {
                                'id': '$($newNATGatewayResponse.id)'
                            },
                            'addressPrefix': '$($AzureSubnetDetails.properties.addressPrefix)'
                        }
                    }"
    Write-Verbose "Calling REST API to update subnet to use the NAT-Gateway"
    $subnetResponse = Invoke-RestMethod -Uri $restUri -Method PUT -Headers $authHeader -Body $requestBody
    Write-Verbose "Updated subnet details: $($subnetResponse)"
} catch {
    $ErrorMessage = $_.Exception.Message
    Write-Error "Failed to update subnet to use NAT-Gateway. Please retry in a few minutes. $($ErrorMessage)" -ErrorAction Stop
    return 1
}
