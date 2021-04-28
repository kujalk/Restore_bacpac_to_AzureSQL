
$ConnectionName = "AzureRunAsConnection"
$ResourceGroupName = "Azure_SQL"
$SqlServerName = "test-azure-sql-server"
$SqlDB = "sampledb"
$StorageAccountName = "sqlupworkjana"
$StorageContainer = "sqlbackup"
$FileName = "AdventureWorks.bacpac"
$SqlCredentialName = "SqlCred"

[PSCredential] $SqlCredential = Get-AutomationPSCredential -Name $SqlCredentialName

# Get the username and password from the SQL Credential
$SqlUser = $SqlCredential.UserName
$SqlPass = $SqlCredential.GetNetworkCredential().Password

try
{
    # Get the connection "AzureRunAsConnection"
    $servicePrincipalConnection = Get-AutomationConnection -Name $ConnectionName

    Write-Output "Logging into Azure..."
    $connectionResult =  Connect-AzAccount -Tenant $servicePrincipalConnection.TenantID `
                            -ApplicationId $servicePrincipalConnection.ApplicationID   `
                            -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint `
                            -ServicePrincipal
    Write-Output "Login succeeded"

}
catch 
{
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $ConnectionName not found."
        throw $ErrorMessage
    } 
    else
    {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

try
{
    Write-Output "Going to import database to Azure SQL"

    # Import bacpac to database with an S3 performance level
    $importRequest = New-AzSqlDatabaseImport -ResourceGroupName $ResourceGroupName `
        -ServerName $SqlServerName `
        -DatabaseName $SqlDB `
        -DatabaseMaxSizeBytes "268435456000" `
        -StorageKeyType "StorageAccessKey" `
        -StorageKey $(Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName).Value[0] `
        -StorageUri "https://$StorageAccountName.blob.core.windows.net/$StorageContainer/$FileName" `
        -Edition "Standard" `
        -ServiceObjectiveName "S3" `
        -AdministratorLogin $SqlUser `
        -AdministratorLoginPassword $(ConvertTo-SecureString -String $SqlPass -AsPlainText -Force) -EA Stop

    Write-Output "Import command executed successfully. Waiting to retrieve progress"

    # Check import status and wait for the import to complete
    $importStatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink -EA Stop
    Write-Output "Import status will be shown below - "

    while ($importStatus.Status -eq "InProgress")
    {
        $importStatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink -EA Stop
        $Date = Get-Date -Format "hh:mm:ss dd-MM-yyyy"
        Write-Output ("[{0}] Import in progress ....." -f $Date) 
        Start-Sleep -s 60
    }

    Write-Output "Completed with the import database of Azure SQL"
}

catch
{
    Write-Output "Error is - $_"
    Write-Error "$_"
}