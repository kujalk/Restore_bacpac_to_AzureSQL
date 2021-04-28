Instructions
------------------

[1] Create the runbook with default automation account connection "AzureRunAsConnection"

[2] Modules needs to be added-
Az.Accounts
Az.storage
AZ.sql

[3] Create a credential object in Runbook 

[4] Create a Runbook with PowerShell and paste the code and change the top parameters

[5] In SQL Server -> Firewall settings -> Allow Azure services and resources to access this server

FAQs
------
Sometime, Why it takes long time for completion?
This problem occurs when many customers make an import or export request at the same time in the same region.

The Azure SQL Database Import/Export Service provides a limited number of Compute virtual machines (VMs) per region to process the import and export operations

[Reference] https://docs.microsoft.com/en-us/azure/azure-sql/database/database-import-export-hang



