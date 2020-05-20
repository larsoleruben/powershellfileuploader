#script to upload files
function Get-TimeStamp {
    
    return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
    
}

$logfilename = "ftplog.txt"
$ftpURL = ""
$ftpUsername = ""
$ftpPwd = ""

Write-Output "$(Get-TimeStamp) FTP Filetransfer started" | Out-file $logfilename -append
$files = Get-ChildItem "/tmp" -Filter *.log
[string[]]$arrayFromFile = Get-Content -Path $logfilename
foreach ($f in $files){
    #Write-Output "$(Get-TimeStamp) FTP Filetransfer started" | Out-file $logfilename -append
    $outfile = $f.FullName
    $filename = $f.Name
    $filename 
    $outfile
    #read the log to see if the file as allready been transferred
    if( (@($arrayFromFile) -like "*$outfile*").Count -eq 0 ){
        # create the FtpWebRequest and configure it
        $ftp = [System.Net.FtpWebRequest]::Create("$ftpURL/$filename")
        $ftp = [System.Net.FtpWebRequest]$ftp
        $ftp.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
        $ftp.Credentials = new-object System.Net.NetworkCredential($ftpUsername,$ftpPwd)
        $ftp.UseBinary = $true
        $ftp.UsePassive = $true
        # read in the file to upload as a byte array
        $content = [System.IO.File]::ReadAllBytes($outfile)
        $ftp.ContentLength = $content.Length
        # get the request stream, and write the bytes into it
        $rs = $ftp.GetRequestStream()
        $rs.Write($content, 0, $content.Length)
        #write to log that file is transfered
        Write-Output "$(Get-TimeStamp) $outfile transferred" | Out-file $logfilename -append
        # be sure to clean up after ourselves
        $rs.Close()
        $rs.Dispose()
    }
}
Write-Output "$(Get-TimeStamp) FTP Filetransfer ended" | Out-file $logfilename -append

