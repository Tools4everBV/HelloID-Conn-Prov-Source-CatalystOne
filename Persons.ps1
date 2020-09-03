[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$customer = "<Fill Customer-Name>"
$clientsecret = "<Fill Client-Secret>"
$clientid = "<Fill Client-Id>"
$application = 'https://c6.catalystone.com/' + $customer
$headers = @{
                    'Client-Secret' = $clientsecret
                    'Client-Id' = $clientid
                    'Grant-Type' = "client_credentials"
                    'Api-Version' = "v3"
};
$body = $null
$response = Invoke-RestMethod "$application/api/accesstoken" -Method GET -Body $body -Headers $headers;
$token = $response.access_token; 

$headers = @{
                    'Access-Token' = $token
                    'Api-Version' = "v3"
                    'Accept-Charset' = "utf-8"
};

#Return of API is encoded therefore read it as UTF8
$objects = Invoke-RestMethod "$application/api/employees" -Method GET -Body $body -Headers $headers -OutFile '.\response2.json';
$objects =  (gc .\response2.json -Encoding UTF8) | ConvertFrom-Json
$employees = $objects.employees

foreach($employee in $employees)
{
    $person  = @{};
    $person['ExternalId'] = $employee.guid
    
    foreach($prop in $employee.PSObject.properties)
    {
        if ($prop.Name -eq "field") { continue; }
        $person[$prop.Name] = "$($prop.Value)";
    }
    
    foreach($prop in $employee.field.PSObject.properties)
    {
       switch ($prop.Name)
       {
            0 { $person['employeeId'] = "$(($prop.Value).data.value)"; }
            2 { $person['FirstName'] = "$(($prop.Value).data.value)"; }
            3 { $person['LastName'] = "$(($prop.Value).data.value)"; }
            8 { $person['Organization'] = "$(($prop.Value).data.value)"; }
            1046 { $person['EmploymentType'] = "$(($prop.Value).data.value)"; }
            9 { $person['Manager'] = "$(($prop.Value).data.value)"; }
            1003 { $person['MobilePhone'] = "$(($prop.Value).data.value)"; }
            24 { $person['Country'] = "$(($prop.Value).data.value)"; }
            14 { $person['JobLocation'] = "$(($prop.Value).data.value)"; }
            37 { $person['DateOfHiring'] = "$(($prop.Value).data.value)"; }
            38 { $person['DateOfTermination'] = "$(($prop.Value).data.value)"; }
            103 { $person['AccountStatus'] = "$(($prop.Value).data.value)"; }
            Default { }
       } 
    }

    $person['Contracts'] = [System.Collections.ArrayList]@();
    $contract = @{};
    $contract['SequenceNumber'] = "1";
    foreach($prop in $employee.field.PSObject.properties)
    {
       switch ($prop.Name)
       {
            1083 { $contract['DepartmentName'] = "$(($prop.Value).data.value)"; }
            1084 { $contract['DepartmentNumber'] = "$(($prop.Value).data.value)"; }
            44 { $contract['JobTitle'] = "$(($prop.Value).data.value)"; }
            37 { if ($(($prop.Value).data.value) -eq '') { $contract['StartDate'] = $null } else { $contract['StartDate'] = Get-date("$(($prop.Value).data.value)") -format 'o'; } }
            38 { if ($(($prop.Value).data.value) -eq '') { $contract['EndDate'] = $null } else { $contract['EndDate'] = Get-date("$(($prop.Value).data.value)") -format 'o'; } }
       }
    }
    [void]$person['Contracts'].Add($contract);
    Write-Output ($person | ConvertTo-Json -Depth 20);
}
