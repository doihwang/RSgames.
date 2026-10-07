$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$serverSource = Get-Content -LiteralPath (Join-Path $root 'Server.server.luau') -Raw
$clientSource = Get-Content -LiteralPath (Join-Path $root 'Client.client.luau') -Raw
$settings = [System.Xml.XmlWriterSettings]::new()
$settings.Indent = $true
$settings.Encoding = [System.Text.UTF8Encoding]::new($false)
$destination = Join-Path $root 'Warrr.rbxlx'
$writer = [System.Xml.XmlWriter]::Create($destination, $settings)
function Start-Item($class, $name) {
    $writer.WriteStartElement('Item')
    $writer.WriteAttributeString('class', $class)
    $writer.WriteStartElement('Properties')
    $writer.WriteStartElement('string')
    $writer.WriteAttributeString('name', 'Name')
    $writer.WriteString($name)
    $writer.WriteEndElement()
    $writer.WriteEndElement()
}
function Write-Script($class, $name, $source) {
    $writer.WriteStartElement('Item')
    $writer.WriteAttributeString('class', $class)
    $writer.WriteStartElement('Properties')
    $writer.WriteStartElement('string')
    $writer.WriteAttributeString('name', 'Name')
    $writer.WriteString($name)
    $writer.WriteEndElement()
    $writer.WriteStartElement('ProtectedString')
    $writer.WriteAttributeString('name', 'Source')
    $writer.WriteCData($source)
    $writer.WriteEndElement()
    $writer.WriteEndElement()
    $writer.WriteEndElement()
}
$writer.WriteStartElement('roblox')
$writer.WriteAttributeString('version', '4')
Start-Item 'Workspace' 'Workspace'
$writer.WriteEndElement()
Start-Item 'ServerScriptService' 'ServerScriptService'
Write-Script 'Script' 'WarrrServer' $serverSource
$writer.WriteEndElement()
Start-Item 'StarterPlayer' 'StarterPlayer'
Start-Item 'StarterPlayerScripts' 'StarterPlayerScripts'
Write-Script 'LocalScript' 'WarrrClient' $clientSource
$writer.WriteEndElement()
$writer.WriteEndElement()
$writer.WriteEndElement()
$writer.Close()
[xml]$check = Get-Content -LiteralPath $destination -Raw
$scripts = $check.SelectNodes('//ProtectedString[@name="Source"]')
if ($scripts.Count -ne 2) { throw 'Expected two embedded scripts.' }
if ($scripts[0].InnerText -cne $serverSource -or $scripts[1].InnerText -cne $clientSource) { throw 'Script source mismatch.' }
Write-Output "Built and XML-validated: $destination"
