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

$departments  = [System.Collections.ArrayList]@();
foreach($employee in $employees)
{
    $department  = @{};
    foreach($prop in $employee.field.PSObject.properties)
    {
       switch ($prop.Name)
       {
            1083 { $department['Name'] = "$(($prop.Value).data.value)"; $department['DisplayName'] = "$(($prop.Value).data.value)"; }
            1084 { $department['ExternalId'] = "$(($prop.Value).data.value)"; }
       }
    }
    if ($department['ExternalId'] -eq "") { continue; }
    if ($departments.Contains($department['ExternalId']) -eq $false)
    {
        Write-Output ($department | ConvertTo-Json -Depth 20);
        $departments += $department['ExternalId'];
    }
}
