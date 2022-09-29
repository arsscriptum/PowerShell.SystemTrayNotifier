<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜 
#̷𝓍   
#̷𝓍   Write-SysTrayLog
#̷𝓍   
#>


$CurrentPath = (Get-Location).Path
$CmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = '$pid'" | select CommandLine ).CommandLine   
[string[]]$UserCommandArray = $CmdLine.Split(' ')
$ProgramFullPath = $UserCommandArray[0].Replace('"','')
$ProgramDirectory = (gi $ProgramFullPath).DirectoryName
$ProgramName = (gi $ProgramFullPath).Name
$ProgramBasename = (gi $ProgramFullPath).BaseName

$Global:GlobalIndentValue = 0
$Global:LogFilePath = "C:\Tmp\ShowSystemTrayNotifier.log"
Remove-Item $Global:LogFilePath -Force -ErrorAction Ignore | Out-Null
New-Item $Global:LogFilePath -Force -ItemType file -ErrorAction Ignore | Out-Null

if(($ProgramName -eq 'pwsh.exe') -Or ($ProgramName -eq 'powershell.exe')){
    $MODE_NATIVE = $False
    $MODE_SCRIPT = $True
}else{
    $MODE_NATIVE = $True
    $MODE_SCRIPT = $False
}


Function Read-CmdlineAndParse{    
    # Define Parameters
    [CmdletBinding(SupportsShouldProcess)]
    Param
    (
        # The popup Content
        [Parameter(Position=0,Mandatory=$True)]
        [String]$CommandLine
    )

    Write-SysTrayLog "########################"
    Write-SysTrayLog "Read-CmdlineAndParse"


    Write-SysTrayLog "CommandLine $CommandLine"




    [string]$Tooltip    = ''
    [string]$Icon       = ''
    [string]$Title      = ''
    [string]$Text       = ''
    [string]$DurationStr= ''
    [int]$Duration      = 0


    [string[]]$CommandsArray = $CommandLine.Split('-')
    $CommandsArrayCount = $CommandsArray.Count
    ########################################################################
    #                     COMMAND LINE PARSING
    ########################################################################

    $Parameters = @{}
    $Ready = $False
    Write-SysTrayLog "COMMAND LINE PARSING. $CommandsArrayCount Options"
    for ( $i = 1; $i -lt $CommandsArrayCount; $i++ ) {

        if($CommandsArray[$i].Length -lt 2){ continue; }
        [string]$CmdOption = $CommandsArray[$i]
        Write-SysTrayLog "$i ==> $CmdOption"
        
        $CmdOptionLen = $CmdOption.Length
        $CmdValue = $CmdOption.SubString(2,$CmdOptionLen-2)
        Write-SysTrayLog "CmdValue $CmdValue"
        switch($CmdOption[0]){

            'm'         {
                            $Text  = $CmdValue
                            $Parameters['Text'] = $CmdValue 
                            Write-SysTrayLog "Text $Text" -f Red
                        }
            't'         {
                            $Title  = $CmdValue
                            $Parameters['Title'] = $CmdValue 
                            Write-SysTrayLog "Title $Title" -f Red
                        }

            'i'         {
                            $Icon  = $CmdValue
                            $Parameters['Icon'] = $CmdValue 
                            Write-SysTrayLog "Icon $Icon" -f Red
                        }
            'c'         {
                            $Tooltip  = $CmdValue
                            $Parameters['Tooltip'] = $CmdValue 
                            Write-SysTrayLog "Tooltip $Tooltip" -f Red
                        }

            'd'         {
                            $Duration  = $CmdValue
                            $Parameters['Duration'] = $CmdValue 
                            Write-SysTrayLog "Duration $Duration" -f Red
                        }


        }
    }

    $Parameters = @{
            Text        = $Text 
            Title       = $Title 
            Duration    = $Duration 
            Icon        = $Icon
            Tooltip     = $Tooltip
        }

    return $Parameters
}



Function Show-InternalMiniPopup{  
    # Define Parameters
    [CmdletBinding(SupportsShouldProcess)]
    Param
    (
        # The popup Content
        [Parameter(Position=0,Mandatory=$True)]
        [String]$Title,
        [Parameter(Position=1,Mandatory=$True)]
        [String]$Message,
        [Parameter(Position=2,Mandatory=$False)]
        [ValidateSet('None','Hand','Error','Stop','Question','Exclamation','Warning','Asterisk','Information')]
        [String]$Icon="None",
        [Parameter(Position=3,Mandatory=$False)]
        [ValidateSet('OK', 'OKCancel', 'AbortRetryIgnore', 'YesNoCancel', 'YesNo', 'RetryCancel')]
        [String]$Type="OK",
        [ValidateSet('Button1','Button2','Button3')]
        [String]$DefaultButton="Button1",
        [ValidateSet('DefaultDesktopOnly', 'RightAlign', 'RtlReading', 'ServiceNotification')]
        [String]$Option="DefaultDesktopOnly"     

        
    )
    $Null = [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    return [Windows.Forms.MessageBox]::show($Message, $Title,$Type,$Icon,$DefaultButton,$Option)
}

Function Show-InternalMiniInfoPopup{   
    # Define Parameters
    [CmdletBinding(SupportsShouldProcess)]
    Param
    (
        # The popup Content
        [Parameter(Position=0,Mandatory=$True)]
        [String]$Message,
        [Parameter(Position=1,Mandatory=$False)]
        [String]$Title = "Important Information"
    )
    return Show-InternalMiniPopup -Title $Title -Message $Message -Icon 'Information'
}

Function Show-InternalMiniErrorPopup{    
    # Define Parameters
    [CmdletBinding(SupportsShouldProcess)]
    Param
    (
        # The popup Content
        [Parameter(Position=0,Mandatory=$True)]
        [String]$Message,
        [Parameter(Position=1,Mandatory=$False)]
        [String]$Title = "ERROR"
    )
    return Show-InternalMiniPopup -Title $Title -Message $Message -Icon 'Error'
}



Function Write-SysTrayLog {     
    PARAM(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="LogEntry", Position=0)]
        [string] $LogEntry,
        [Parameter(Mandatory=$false)]
        [Alias('s')]
        [int]    $Severity=1,
        [Parameter(Mandatory=$false)] 
        [Alias('f')]
        [string] $FontColor="Gray",
        [Parameter(Mandatory=$false)] 
        [Alias('i')]
        [int]    $Indent = 0,
        [Parameter(Mandatory=$false)] 
        [Alias('n')]
        [switch] $NoNewLine,
        [Parameter(Mandatory=$false)] 
        [Alias('c')]
        [string] $Category
    )
    BEGIN
    {
        if($FontColor -eq "") {
            switch ($Severity) {
                "1" {
                    ## Informational Response
                    $FontColor     = "White"
                    $MessagePreFix = ""
                }
                "2" {
                    ## Warning Response
                    $FontColor = "Yellow"
                    $MessagePreFix = "WARNING:  "
                }
                "3" {
                    ## Error Response
                    $FontColor = "Red"
                    $MessagePreFix = "ERROR:    "
                }
            }
        }
        ## Combines the logging message and the message type as a prefix
        $LogEntry = $MessagePreFix + $LogEntry

   
        ## Indents the message when viewed on the screen.
        $LogEntry = $LogEntry.PadLeft($LogEntry.Length + (2 * $Global:GlobalIndentValue) )
    }
    PROCESS
    {
        if($MODE_NATIVE)    { Add-Content -Path "$Global:LogFilePath" -Value "$LogEntry" -NoNewline:$NoNewLine }
        if($MODE_SCRIPT) { 
            if($PSBoundParameters.ContainsKey('Category') -eq $True){
                Write-Host "[$Category] " -f Yellow -n
            }else{
                Write-Host "[ModDl] " -f DarkCyan -n
            }
            Write-Host -Object $LogEntry -ForegroundColor $FontColor -NoNewline:$NoNewLine 
        }
    }
    END
    {
        return
    }
}



function Show-SystemTrayNotifier{
    <#
    .Synopsis
        Display a balloon tip message in the system tray.

    .Description
        This function displays a user-defined message as a balloon popup in the system tray. This function
        requires Windows Vista or later.

    .Parameter Message
        The message text you want to display.  Recommended to keep it short and simple.

    .Parameter Title
        The title for the message balloon.

    .Parameter MessageType
        The type of message. This value determines what type of icon to display. Valid values are

    .Parameter SysTrayIcon
        The path to a file that you will use as the system tray icon. Default is the PowerShell ISE icon.

    .Parameter Duration
        The number of seconds to display the balloon popup. The default is 1000.

    .Inputs
        None

    .Outputs
        None

    .Notes
         NAME:      Invoke-BalloonTip
         VERSION:   1.0
         AUTHOR:    Boe Prox
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$Text,
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$Title,
        [Parameter(Mandatory=$false)]
        [int]$Duration=5000,
        [Parameter(Mandatory=$false)]
        [string]$Tooltip='None',
        [Parameter(Mandatory=$false)]
        [string]$Icon
    )


    try{
        Add-Type -AssemblyName System.Windows.Forms
        Write-SysTrayLog " Add-Type -AssemblyName System.Windows.Forms"
        [System.Windows.Forms.NotifyIcon]$MyNotifier = [System.Windows.Forms.NotifyIcon]::new()
        #Mouse double click on icon to dispose
        [void](Register-ObjectEvent -ErrorAction Ignore -InputObject $MyNotifier -EventName MouseDoubleClick -SourceIdentifier IconClicked -Action  {
            #Perform cleanup actions on balloon tip
            Write-Verbose 'Disposing of balloon'
            $MyNotifier.dispose()
            Unregister-Event -SourceIdentifier IconClicked
            Remove-Job -Name IconClicked
          
        })

        Write-SysTrayLog "########################"
        Write-SysTrayLog "Show-SystemTrayNotifier"


        Write-SysTrayLog "ProgramDirectory $ProgramDirectory"
        Write-SysTrayLog "Icon $Icon"


        if($MODE_SCRIPT -eq $True){
            $IconPath = Join-Path "$PSScriptRoot\ico" $Icon
        }elseif($MODE_NATIVE -eq $True){
            $IconPath = Join-Path "$ProgramDirectory\ico" $Icon
        }
        
        $IconPath += '.ico'

         Write-SysTrayLog "IconPath $IconPath"
        $MyNotifier.Icon = [System.Drawing.Icon]::new($IconPath)
        

        Write-SysTrayLog "BalloonTipText $Text"
        Write-SysTrayLog "BalloonTipTitle $Title"
        Write-SysTrayLog "Duration $Duration"
        if([string]::IsNullOrEmpty($Tooltip) -eq $False){
            $MyNotifier.BalloonTipIcon  = [System.Windows.Forms.ToolTipIcon]::$Tooltip
        }
        
        $MyNotifier.BalloonTipText  = $Text
        $MyNotifier.BalloonTipTitle = $Title
        $MyNotifier.Visible = $true

        #Display the tip and specify in milliseconds on how long balloon will stay visible
        $MyNotifier.ShowBalloonTip($Duration)
    }catch{
        Write-SysTrayLog $_
    }

}


try{
    Write-SysTrayLog "================================================"
    Write-SysTrayLog "MODE_NATIVE $MODE_NATIVE"
    Write-SysTrayLog "MODE_SCRIPT $MODE_SCRIPT"
    Write-SysTrayLog "================================================"


    [string]$Tooltip    = ''
    [string]$Icon       = ''
    [string]$Title      = ''
    [string]$Text       = ''
    [string]$DurationStr= ''
    [int]$Duration      = 0

    $Parameters = @{}


    if($MODE_SCRIPT -eq $True){
        # THIS IS ONLY FOR DEUGGING...
        $Tooltip='Warning'
        $Icon = 'upload-in-cloud'
        $Title = "This is the title"
        $Text = "file saved to .."
        $Duration = 5000
        $Parameters = @{
            Text        = $Text 
            Title       = $Title 
            Duration    = $Duration 
            Icon        = $Icon
            Tooltip     = $Tooltip
        } 
        Write-SysTrayLog "MODE_SCRIPT IS USED FOR DEBUGGING"
    }elseif($MODE_NATIVE -eq $True){
        Write-SysTrayLog "MODE_NATIVE logic started..."
        $Pattern = '^(?<Id1>\-m)(\s*)(?<Text>[\w\(\) \. \-a-zA-Z0-9\"]*)(\s*)(?<Id2>\-t)(\s*)(?<Title>[\w\(\) \. \-a-zA-Z0-9\"]*)(\s*)(?<Id3>\-i)(\s*)(?<Icon>[\w\(\) \. \-a-zA-Z0-9\"]*)(\s*)(?<Id4>\-c)(\s*)(?<Category>[\w\(\) \. \-a-zA-Z0-9\"]*)(\s*)(?<Id5>\-d)(\s*)(?<Duration>[0-9\"]*)?'
        $NewCommandLine = (Get-CimInstance Win32_Process -Filter "ProcessId = '$pid'" | select CommandLine ).CommandLine
        $arr = $NewCommandLine.Split(' ')
        $index0 = $arr[0]

        $FullCommand = $NewCommandLine.Replace($index0,'').Trim()  
        Write-SysTrayLog "NewCommandLine     $NewCommandLine"
        Write-SysTrayLog "index0      $index0"
        Write-SysTrayLog "FullCommand $FullCommand"

        if($FullCommand -match $Pattern){
            Write-SysTrayLog "CommandLine was SUCCESSFULLY PARSED using RegEx"

            [string]$Tooltip    = $Matches.Category
            [string]$Icon       = $Matches.Icon
            [string]$Title      = $Matches.Title
            [string]$Text       = $Matches.Text   
            [string]$DurationStr= $Matches.Duration
            [int]$Duration      = $DurationStr


            $Tooltip    = $Tooltip.Trim()
            $Icon       = $Icon.Trim()
            $Title      = $Title.Trim()
            $Text       = $Text.Trim()
            $DurationStr= $DurationStr.Trim()
            $Duration   = $Duration.Trim()

            $Parameters = @{
                Text        = $Text 
                Title       = $Title 
                Duration    = $Duration 
                Icon        = $Icon
                Tooltip     = $Tooltip
            }
        }else{
             Write-SysTrayLog "RegEx parse failure..."
             $Parameters = Read-CmdlineAndParse $FullCommand 

            [string]$Tooltip    = $Parameters.Tooltip
            [string]$Icon       = $Parameters.Icon
            [string]$Title      = $Parameters.Title
            [string]$Text       = $Parameters.Text   
            [int]$Duration      = $Parameters.Duration


            $Tooltip    = $Tooltip.Trim()
            $Icon       = $Icon.Trim()
            $Title      = $Title.Trim()
            $Text       = $Text.Trim()
            $DurationStr= $DurationStr.Trim()
            $Duration   = $Duration.Trim()
        }
    }
}catch{
    Write-SysTrayLog $_
}





Write-SysTrayLog "================================================"
$Parameters.GetEnumerator() | Select-Object Name, Value | % { 
    $n = $_.Name
    $v = $_.Value
    Write-SysTrayLog "$n = $v" 
}
Write-SysTrayLog "================================================"


try{
    Show-SystemTrayNotifier -Text "$Text" -Title $Title -Duration $Duration -Icon $Icon -Tooltip $Tooltip

}catch{
    Write-SysTrayLog $_
} 