# Run in PowerShell after Node-RED is running and flows are deployed.
# Change this to match NODE_RED_API_KEY in your local .env file.
$ApiKey = "b1070c05d2e64facabf9bdd956593f04942c4453f6d64f37af8a7eab10546de3"
$Url = "http://172.20.10.14:1880/firedata"

$headers = @{ "x-api-key" = $ApiKey }
$normal = @{
  nodeId = "node1"
  temperature = 31.5
  humidity = 55.0
  smoke_level = 180
  fire_detected = $false
} | ConvertTo-Json

$alert = @{
  nodeId = "node2"
  temperature = 52.0
  humidity = 18.0
  smoke_level = 720
  fire_detected = $true
} | ConvertTo-Json

Write-Host "Sending normal test for node1..."
Invoke-RestMethod -Method Post -Uri $Url -Headers $headers -ContentType "application/json" -Body $normal
Write-Host "Sending alert test for node2..."
Invoke-RestMethod -Method Post -Uri $Url -Headers $headers -ContentType "application/json" -Body $alert
