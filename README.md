## DESCRIPTION:

This is a collection of several, may be usefull, PowerShell scritps to use the ProfitBricks SOAP Cloud API. For detailed informations about this please take a look to the ProfitBricks Blog at [http://blog.profitbricks.de/](http://blog.profitbricks.de/)

## Dependencies

PowerShell V3 (`$psversiontable.psversion`)
For PowerSHell V3 - on Server 2008R2 you need Windows Management Framework 3. WMF 3.0 is available for download at Microsoft ( KB2506143-x64 ). WMF 3.0 does require at least .NET Framework 4

## PowerShell Scripts provided

Save-Password-as-encrypted-string.ps1 - Handling of encrypted credentials using PScredentials

ProfitBricks_API_Inventory_Demo.ps1 - Get asset informations about you ProfitBricks cloud ressources using soap api. See als blog post [Part 1 - Inventory](http://blog.profitbricks.de/benutzung-der-profitbricks-api-mit-power-shell-teil-1-basics-und-inventarisierung/) - german only.

ProfitBricks_API_Create[Simple]Datacenter.ps1 - provision new ressources in you ProfitBricks cloud. See also Blog post [Part 2 - Provisioning](http://blog.profitbricks.de/benutzung-der-profitbricks-api-mit-power-shell-teil-2-provisionieren-von-ressourcen/) - german only.

ProfitBricks_API_CloneDatacenter.ps1 - Clone existing Datacenter using snapshots. Work in progess and will result soon in Blog Post part 3 ...

ProfitBricks_API_StartStopDatacenter.ps1 - Power on or power off all servers in a datacenter using ProfitBricks API
 
ProfitBricks_API_StopShutdownServers.ps1 - Power off all shutdown server inside your account. Script is designed to raun as planed task.

## Remarks

Code is for demonstration purpose only.

## LICENSE:

Copyright 2013 Thomas Vogel

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

