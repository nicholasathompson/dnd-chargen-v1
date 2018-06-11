<#
Remove-InstalledAssets.PS1
Author - Nicholas Thompson (nicholasathompson@gmail.com)
Date - 6/10/2018
.SYNOPSIS
    This script removes all assets defined within this script file from the provided SharePoint Online web url.
.DESCRIPTION
    This script removes all assets defined within this script file from the provided SharePoint Online web url.
.NOTES
    You will be asked for valid owner credentials to the specified web. 
    Any assets provisioned through SP feature must also be defined in this script in the appropriate array.
.EXAMPLE
    remove-installedassets -webUrl "http://nicholasathompson.sharepoint.com/apps/demo"
.INPUTTYPE
   Input type: [System.String] - represents the url of the web where the assets are deployed
#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory = $True, Position = 1)]
    [string]$webUrl
);
Import-Module 'C:\Program Files\SharePoint Online Management Shell\Microsoft.Online.SharePoint.PowerShell' -WarningAction SilentlyContinue;


#Step 1: Connect to SPO Service

#Setup Credentials to connect
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"

$Cred = Get-Credential
$Cred = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Cred.UserName,$Cred.Password)
$ctx = New-Object Microsoft.SharePoint.Client.ClientContext($webUrl);
$ctx.Credentials = $Cred;


#Step 2: Let's define our arrays of guids

$featureGuids = @(
    "7fd18647-b687-4537-a687-71541b17bbd9"
)
$listNames = @(
    "Characters",
    "RaceVariants",
    "ClassArchetypes",
    "Races",
    "Classes"
);

$contentTypeIds = @(
    "0x0100B4771B4115ED41E5BDD2481DF1BA83BD", #Character
    "0x010041D4BF87D75049A69368A31240E2E720", #Class Archetype
    "0x0100569C5AC0D3DF4F94A6363C0751D1E333", #Race Variant
    "0x0100A89565565A7343609F8B57E792268A1A", #Race
    "0x01006EB5F272E8864D95AF59731214014232"  #Class
)

$fieldGuids = @(
    "{060E50AC-E9C1-4D3C-B1F9-DE0BCAC300F6}", #start of character
    "{FD6C86E6-110C-40B7-8EDB-93C3362E62B3}",
    "{10659F62-4540-4E25-BFF3-0A6C01DD9C3B}",
    "{F8A7911F-E689-449E-95C0-804C7741057D}",
    "{0B0FDEE6-D6EE-48FA-9D0B-D0BC8068BB94}",
    "{A5DFDF58-85BA-4D24-8870-C30FEE17532C}",
    "{FDBEE73C-09A3-432D-B367-66A877C246B5}",
    "{C693DBD5-DB64-494B-BF81-8D42BC91E59B}",
    "{1FA9596C-E9D1-4DE8-B8B9-8D0AF1B97BAA}",
    "{D9632E3E-F140-4BE8-A36F-D9E963E0BB86}",
    "{65918568-CBAC-4736-A838-7CBA69C15B5A}",
    "{0368BDC8-FE14-4BEC-B564-00228FBFA51C}",
    "{05E38AE6-7540-458E-A554-F4D04C710EC1}",
    "{F15217E3-393A-4857-9316-1EBA7727F875}",
    "{B2A7F088-50F5-49CB-9D8B-04B1E9759AEC}",
    "{4CCE356B-AB21-44C2-89BA-04ED8D75213D}",
    "{4957053E-63FF-45A2-AE43-B74C3F10B028}",
    "{EF2BD21D-AF8C-4B4A-B806-1B0047AD42BD}",
    "{6EE515E3-B22D-49EA-907E-65DCE6E0F1C4}",
    "{943E7530-5E2B-4C02-8259-CCD93A9ECB18}",
    "{DE9E74D2-63AA-438A-A807-DEEB2A26394C}",
    "{9DABE8D4-040D-42E0-89C0-3137DCE88F4C}", #end of character
    "{8FECF6F5-70AE-4A26-8000-6FB72DFAF37C}",
    "{79B20682-0B1E-4655-A249-74B889CE6CF4}",
    "{C3919B30-928D-4D44-AFE5-7867C4884FCF}",
    "{2B2ED6F8-4980-48DA-8D8C-CB227E7317FC}",
    "{5ADCA8B8-6264-47A1-8B66-F545670EF678}",
    "{4B389D7A-E14D-4EC6-A3BA-736316814B9F}"
)

#K, now that that nightmare's out of the way...let's delete some stuff

function DeactivateFeatures() {
    foreach($featureGuid in $featureGuids)
    {
        try {
            $featureStatus = $ctx.Web.Features.GetById($featureGuid);
            $featureStatus.Retrieve("DefinitionId");
            $ctx.Load($featureStatus);
            $ctx.ExecuteQuery();
            if($featureStatus.DefinitionId -ne $null)
            {
                $ctx.Web.Features.Remove($featureGuid, $true);
                $ctx.ExecuteQuery();
            }
        }
        catch {
            Write-Output "Error removing feature." $_.Exception.Message
        }
    }
}
function DeleteLists {
    
    foreach ($listName in $listNames)
    {
        try {
            $list = $ctx.web.lists.GetByTitle($listName);
            $ctx.Load($list);
            $ctx.ExecuteQuery();
            Write-Output $list.Title;
            $list.DeleteObject();
            $ctx.ExecuteQuery();
        }
        catch {
            Write-Output "Error deleting list." $_.Exception.Message
        }
    }
}

function DeleteContentTypes {
    foreach ($contentTypeId in $contentTypeIds)
    {
        try {
            $ct = $ctx.Web.AvailableContentTypes.GetById($contentTypeId)
            $ctx.Load($ct);
            $ctx.ExecuteQuery();
            Write-Output $ct.Name;
            $ct.DeleteObject();
            $ctx.ExecuteQuery();
        }
        catch {
            Write-Output "Error deleting content type." $_.Exception.Message
        }
    }
}

function DeleteFields {
    foreach ($fieldGuid in $fieldGuids)
    {
        try {
        $field = $ctx.Web.Fields.GetById($fieldGuid);
        $ctx.Load($field);
        $ctx.ExecuteQuery();
        Write-Output $field.Title;
        $field.DeleteObject();
        $ctx.ExecuteQuery();
        }
        catch {
            Write-Output "Error deleting field." $_.Exception.Message
        }
    }    
}

DeactivateFeatures;
DeleteLists;
DeleteContentTypes;
DeleteFields;
