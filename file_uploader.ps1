#script to upload files
function Get-TimeStamp {
    
    return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
    
}


function CreateDirectoriesFromPath ($DirectoryPath, $ServerPath, $Login, $Password){
 
	$DirectoryParts = $DirectoryPath.Split("/");
 
	$Position = "";
	
	for ($i = 0; $i -lt $DirectoryParts.Length - 1; $i++){
		
		try {
			$Position += $DirectoryParts[$i] + "/";	
			$AbsoluteTemporaryPath = New-Object System.Uri($ServerPath+$Position);
			$WebRequest = [System.Net.WebRequest]::Create($AbsoluteTemporaryPath);
			$WebRequest.KeepAlive = $false;
			$WebRequest.Credentials = New-Object System.Net.NetworkCredential($Login, $Password);
			$WebRequest.Method = [System.Net.WebRequestMethods+Ftp]::MakeDirectory;
			$WebRequest.GetResponse();
			
		} catch [Net.WebException] {
            #If the directory already exits, it throws an exception and the program continues
            #Could be nicer to test for existence, but!! 
			Write-Host $_.Exception.Message; continue;
		}
	}
}

$logfilename = "ftplog.txt"
$ftpURL = "ftp://ftp.recykler.dk/powershelltest"
$ftpUsername = "recykler.dk"
$ftpPwd = "ps1Test2020"


Write-Output "$(Get-TimeStamp) FTP Filetransfer started" | Out-file $logfilename -append
$files = Get-ChildItem "/tmp" -File -Recurse -Filter *.log
[string[]]$arrayFromFile = Get-Content -Path $logfilename
foreach ($f in $files){
    #Write-Output "$(Get-TimeStamp) FTP Filetransfer started" | Out-file $logfilename -append
    $outfile = $f.FullName
    $filename = $f.Name
    $filename 
    $outfile
    $ftpURL+$outfile
    #read the log to see if the file as allready been transferred
    if( (@($arrayFromFile) -like "*$outfile*").Count -eq 0 ){
        #create the directory
        $FtpPath = New-Object System.Uri($ftpURL+$outfile);
        $ServerPath = "ftp://" + $FtpPath.Host;
        $DirectoryPath = $FtpPath.LocalPath;
        CreateDirectoriesFromPath $DirectoryPath $ServerPath $ftpUsername $ftpPwd;
        # create the FtpWebRequest and configure it
        $ftp = [System.Net.FtpWebRequest]::Create($ftpURL+$outfile)
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

