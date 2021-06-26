# Get-Help .\Deploy-NATGatewayAVD.ps1 -Full

## NAME

```
.\Deploy-NATGatewayAVD.ps1
```
    
## SYNOPSIS

Deploys an Azure NAT-Gateway to route all AVD host traffic out of a single public IP.
    
    
## SYNTAX

    C:\temp\Deploy-NATGatewayAVD.ps1 [-AzureSubscriptionId] <Object> [-AzureResourceGroupName] 
    <Object> [-AzureRegionName] <Object> [[-NewGatewayName] <Object>] [[-NewPublicIPName] 
    <Object>] [[-AzureVirtualNetwork] <Object>] [[-AzureSubnet] <Object>] [<CommonParameters>]
    
    
## DESCRIPTION

Deploys an Azure NAT-Gateway with static IP-Address into an Azure Resource Group. Sets the 
created Gateway as the Gateway for the Subnet. 
If the Virtual Network and Subnet resources are not specified, the script tries to 
determine them automatically.

The logic to determine the correct Virtual Network is:
  1. Retrieve all Virtual Networks in the Resource Group
  2. Assume that the first Virtual Network without "aadds" (Azure Active Directory Domain 
Services) in the name is correct.

The logic to determine the correct Subnet is:
  1. Retrieve all Subnets for the Virtual Network
  2. Assume that the first Subnet without "aadds" (Azure Active Directory Domain Services) 
in the name is correct.

This script was initially created as a submission for the Nerdio Hackathon in June 2021. 
**#NerdioHack2021**

*Hint: Log in first with Connect-AzAccount if not using Azure Cloud Shell*

## PARAMETERS

    -AzureSubscriptionId <Object>
        Azure Subscription Identifier (NOT Azure AD Tenant ID)
        
        Required?                    true
        Position?                    1
        Default value                
        Accept pipeline input?       true (ByPropertyName)
        Accept wildcard characters?  false
        
    -AzureResourceGroupName <Object>
        Name of the Azure Resource Group where the NAT-Gateway should get deployed
        
        Required?                    true
        Position?                    1
        Default value                
        Accept pipeline input?       true (ByPropertyName)
        Accept wildcard characters?  false
        
    -AzureRegionName <Object>
        Codename of the Azure Region where the NAT-Gateway should get deployed. You can 
        retrieve a list of the regions with 'Get-AzLocation'.
        
        Required?                    true
        Position?                    1
        Default value                
        Accept pipeline input?       true (ByPropertyName)
        Accept wildcard characters?  false
        
    -NewGatewayName <Object>
        Specify the name of the NAT-Gateway that gets created, defaults to 'AVD-NAT-Gateway1' 
        if not specified.
        
        Required?                    false
        Position?                    1
        Default value                AVD-NAT-Gateway1
        Accept pipeline input?       true (ByPropertyName)
        Accept wildcard characters?  false
        
    -NewPublicIPName <Object>
        Specify the name of the Public IP Address resource that gets created, defaults to 
        'AVD-NAT-Gateway1-PublicIP1' if not specified.
        
        Required?                    false
        Position?                    1
        Default value                AVD-NAT-Gateway1-PublicIP1
        Accept pipeline input?       true (ByPropertyName)
        Accept wildcard characters?  false
        
    -AzureVirtualNetwork <Object>
        Specify the name of the Azure Virtual Network resource where the NAT-Gateway should get 
        created. If not specified the script tries to automatically determine.
        
        Required?                    false
        Position?                    1
        Default value                
        Accept pipeline input?       true (ByPropertyName)
        Accept wildcard characters?  false
        
    -AzureSubnet <Object>
        Specify the name of the Azure Subnet resource to connect the new NAT-Gateway to. If not 
        specified the script tries to automatically determine.
        
        Required?                    false
        Position?                    1
        Default value                
        Accept pipeline input?       true (ByPropertyName)
        Accept wildcard characters?  false
        
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see 
        about_CommonParameters (https:/go.microsoft.com/fwlink/?LinkID=113216). 
    
## INPUTS

None    
    
## OUTPUTS

None
      
## NOTES  
    
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
    
##    -------------------------- EXAMPLE 1 --------------------------
    
    PS C:\>.\Deploy-NATGatewayAVD.ps1 -AzureSubscriptionId 11111111-aaaa-1111-aaaa-111111111111 
    -AzureResourceGroupName WVD-RG-01 -AzureRegion westeurope
    
Creates a new NAT-Gateway and Public IP Address with default names in the specified 
Subscription/Resource Group/Region. The script tries to figure out the correct Virtual 
Network and Subnet to use.

    
##    -------------------------- EXAMPLE 2 --------------------------
    
    PS C:\>.\Deploy-NATGatewayAVD.ps1 -AzureSubscriptionId 11111111-aaaa-1111-aaaa-111111111111 
    -AzureResourceGroupName WVD-RG-01 -AzureRegion westeurope -NewGatewayName WVD-Outbound 
    -NewPublicIPName WVD-PublicIP
    
Creates a new NAT-Gateway named "WVD-Outbound" and an IP-Address resource named 
"WVD-PublicIP" in the specified Subscription/Resource Group/Region. The script tries to 
figure out the correct Virtual Network and Subnet to use.

##    -------------------------- EXAMPLE 3 --------------------------
    
    PS C:\>.\Deploy-NATGatewayAVD.ps1 -AzureSubscriptionId 11111111-aaaa-1111-aaaa-111111111111 
    -AzureResourceGroupName WVD-RG-01 -AzureRegion westeurope -AzureVirtualNetwork WVD-Network 
    -AzureSubnet WVD-Subnet
    
Creates a new NAT-Gateway and Public IP Address with default names in the specified 
Subscription/Resource Group/Region. The script uses the given Virtual Network and Subnet.
    
## RELATED LINKS

- https://diecknet.de/
- https://github.com/diecknet/AzureVirtualDesktop
- https://docs.microsoft.com/en-us/azure/governance/resource-graph/first-query-rest-api#rest-api-and-powershell
