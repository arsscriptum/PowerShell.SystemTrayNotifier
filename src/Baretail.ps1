<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜 
#̷𝓍   
#̷𝓍   Write-LogEntry
#̷𝓍   
#>



    [CmdletBinding(SupportsShouldProcess)]
    Param
    (
        # The popup Content
        [Parameter(Mandatory=$false)]
        [String]$Path="C:\Tmp\ShowSystemTrayNotifier.log",
        [Parameter(Mandatory=$false)]
        [string]$Command = 'baretail.exe'
    )
    try{
        $Global:LogFilePath = $Path
        $CmdExe = (Get-Command $Command).Source
        &"$CmdExe" "$Global:LogFilePath"
    }catch{
        Write-Error $_
    }
