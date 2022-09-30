<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜 
#̷𝓍   
#̷𝓍   
#>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Text,
        [Parameter(Mandatory=$false, Position=1)]
        [string]$Title = "Operation Completed",
        [Parameter(Mandatory=$false)]
        [string]$Icon='download',
        [Parameter(Mandatory=$false)]
        [string]$Tooltip='None',
        [Parameter(Mandatory=$false)]
        [int]$Duration=5000
    )


    try{
        Add-Type -AssemblyName System.Windows.Forms
        Write-Output " Add-Type -AssemblyName System.Windows.Forms"
        [System.Windows.Forms.NotifyIcon]$MyNotifier = [System.Windows.Forms.NotifyIcon]::new()
        #Mouse double click on icon to dispose
        [void](Register-ObjectEvent -ErrorAction Ignore -InputObject $MyNotifier -EventName MouseDoubleClick -SourceIdentifier IconClicked -Action  {
            #Perform cleanup actions on balloon tip
            Write-Verbose 'Disposing of balloon'
            $MyNotifier.dispose()
            Unregister-Event -SourceIdentifier IconClicked
            Remove-Job -Name IconClicked
          
        })

        $CurrentPath = (Get-Location).Path
        $CmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = '$pid'" | select CommandLine ).CommandLine   
        [string[]]$UserCommandArray = $CmdLine.Split(' ')
        $ProgramFullPath = $UserCommandArray[0].Replace('"','')
        $ProgramDirectory = (gi $ProgramFullPath).DirectoryName
        $ProgramName = (gi $ProgramFullPath).Name
        $ProgramBasename = (gi $ProgramFullPath).BaseName

        $Global:LogFilePath = Join-Path ((Get-Location).Path) 'downloadtool.log'
        Remove-Item $Global:LogFilePath -Force -ErrorAction Ignore | Out-Null
        New-Item $Global:LogFilePath -Force -ItemType file -ErrorAction Ignore | Out-Null

        if(($ProgramName -eq 'pwsh.exe') -Or ($ProgramName -eq 'powershell.exe')){
            $MODE_NATIVE = $False
            $MODE_SCRIPT = $True
        }else{
            $MODE_NATIVE = $True
            $MODE_SCRIPT = $False
        }

        if($MODE_NATIVE){
            $IconPath = Join-Path "$ProgramDirectory" "ico"
            $IconPath = Join-Path "$IconPath" "$Icon"
            $IconPath += '.ico'
        }elseif($MODE_SCRIPT){
            $IconPath = Join-Path "$PSScriptRoot\ico" $Icon
        }
        $MyNotifier.Icon = [System.Drawing.Icon]::new($IconPath)

        if([string]::IsNullOrEmpty($Tooltip) -eq $False){
            $MyNotifier.BalloonTipIcon  = [System.Windows.Forms.ToolTipIcon]::$Tooltip
        }
        
        $MyNotifier.BalloonTipText  = $Text
        $MyNotifier.BalloonTipTitle = $Title
        $MyNotifier.Visible = $true

        #Display the tip and specify in milliseconds on how long balloon will stay visible
        $MyNotifier.ShowBalloonTip($Duration)
    }catch{
        Write-Output $_
    }



