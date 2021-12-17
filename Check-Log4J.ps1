function Init-CheckLog4J
{
    [Reflection.Assembly]::LoadWithPartialName( "System.IO.Compression.FileSystem" )
    $appdata = $env:APPDATA
    $programFiles = $env:ProgramFiles
    $programFiles86 = $programFiles + " (x86)"
    $dirList = @($appdata, $programFiles, $programFiles86)
    $listOfApplications = [PSCustomObject]@{
        MachineName = $env:COMPUTERNAME
        ApplicationName = @()
        ApplicationPath = @()
        ClassName = @()
        HasLDAP = @()

    }
    $i = 0
    $netConResult = Test-NetConnection -ComputerName 127.0.0.1 -Port 389
    if ($netConResult.TcpTestSucceeded -eq $false)
    {
        $netConResult = Test-NetConnection -ComputerName 127.0.0.1 -Port 636
    }
    foreach ($item in $dirList)
    {
        $gciOfItem = gci $item -Recurse| ? {$_.Extension -match "jar"}
        foreach ($gci in $gciOfItem)
        {
            Write-Output("Checking " + $gci.fullname)
            $openedJar = [System.IO.Compression.ZipFile]::OpenRead($gci.FullName)
            foreach ($name in $openedJar.Entries.name)
            {
                if ($name -match "log4j")
                {
                    $listOfApplications.ApplicationName += $gci.name
                    $listOfApplications.ApplicationPath += $gci.fullname
                    $listOfApplications.ClassName += $name
                    $listOfApplications.HasLDAP += $netConResult.TcpTestSucceeded
                }
            }
        }
    }

    $log4jvuln = "V:\temp\log4j.csv"
    for ($i = 0; $i -lt $listOfApplications.className.count; $i++) {
        Add-Content -Path $log4jvuln -Value "$($listOfApplications.MachineName[$i])," -NoNewline
        Add-Content -Path $log4jvuln -Value "$($listOfApplications.ApplicationName[$i])," -NoNewline
        Add-Content -Path $log4jvuln -Value "$($listOfApplications.ApplicationPath[$i])," -NoNewline
        Add-Content -Path $log4jvuln -Value "$($listOfApplications.ClassName[$i])," -NoNewline
        Add-Content -Path $log4jvuln -Value "$($listOfApplications.HasLDAP[$i]),"
    }
}

Init-CheckLog4J

