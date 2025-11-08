' ============================================================================
' Daktela URL Handler - One-Click Installer (Pure VBScript)
' Advanced registration: Direct command + ProgId registration
' ============================================================================

On Error Resume Next

Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

Dim output, daktelaPath, isStoreApp, success

output = "Daktela URL Handler Registration" & vbCrLf & _
         "================================" & vbCrLf & vbCrLf

output = output & "Searching for Daktela..." & vbCrLf & vbCrLf

daktelaPath = ""
isStoreApp = False

' ============================================================================
' SEARCH: Find Daktela (Traditional or Store app)
' ============================================================================

Dim paths, i
paths = Array( _
    "C:\Program Files\Daktela\Daktela.exe", _
    "C:\Program Files (x86)\Daktela\Daktela.exe", _
    "C:\Program Files\Daktela Desktop\Daktela.exe", _
    "C:\Program Files (x86)\Daktela Desktop\Daktela.exe", _
    "C:\Program Files\Daktela\DaktelaClient.exe", _
    "C:\Program Files (x86)\Daktela\DaktelaClient.exe" _
)

For i = 0 To UBound(paths)
    If objFSO.FileExists(paths(i)) Then
        daktelaPath = paths(i)
        output = output & "[+] Found traditional installation" & vbCrLf & vbCrLf
        Exit For
    End If
Next

' If not found, check for Store app
If daktelaPath = "" Then
    output = output & "[*] Checking Microsoft Store..." & vbCrLf
    
    Dim storeBasePath
    storeBasePath = objShell.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\Packages"
    
    If objFSO.FolderExists(storeBasePath) Then
        Dim folder, subfolder
        Set folder = objFSO.GetFolder(storeBasePath)
        
        For Each subfolder In folder.SubFolders
            If InStr(1, subfolder.Name, "Daktela", 1) > 0 Then
                daktelaPath = subfolder.Name
                isStoreApp = True
                output = output & "[+] Found Store app: " & daktelaPath & vbCrLf & vbCrLf
                Exit For
            End If
        Next
    End If
End If

' Recursive search if still not found
If daktelaPath = "" Then
    output = output & "[*] Searching Program Files..." & vbCrLf
    daktelaPath = FindDaktelaRecursive("C:\Program Files", 5)
    If daktelaPath = "" Then
        daktelaPath = FindDaktelaRecursive("C:\Program Files (x86)", 5)
    End If
    If daktelaPath <> "" Then
        output = output & "[+] Found: " & daktelaPath & vbCrLf & vbCrLf
    End If
End If

If daktelaPath = "" Then
    output = output & vbCrLf & "ERROR: Could not find Daktela!" & vbCrLf & vbCrLf & _
             "Please ensure Daktela is properly installed."
    MsgBox output, vbCritical, "Daktela URL Handler - Error"
    WScript.Quit 1
End If

' ============================================================================
' REGISTER URL SCHEMES
' ============================================================================

Dim schemes
schemes = Array("tel", "callto")

output = output & "Registering URL schemes..." & vbCrLf

success = True

' First, try to clear any conflicting registrations
For Each scheme In schemes
    On Error Resume Next
    objShell.RegDelete "HKCU\Software\Classes\" & scheme & "\shell\open\command\"
    objShell.RegDelete "HKCU\Software\Classes\" & scheme & "\"
    On Error Goto 0
Next

' Now register fresh
For Each scheme In schemes
    On Error Resume Next
    
    Dim regPath, cmdPath, command
    regPath = "HKCU\Software\Classes\" & scheme
    cmdPath = regPath & "\shell\open\command"
    
    If isStoreApp Then
        ' For Store apps, use the shell:appsFolder protocol which is most direct
        command = "explorer.exe shell:appsFolder\" & daktelaPath & "!App"
    Else
        ' For traditional apps
        command = """" & daktelaPath & """ ""%1"""
    End If
    
    ' Register protocol
    objShell.RegWrite regPath & "\", "URL:" & scheme & " Protocol", "REG_SZ"
    objShell.RegWrite regPath & "\URL Protocol", "", "REG_SZ"
    objShell.RegWrite cmdPath & "\", command, "REG_SZ"
    
    If Err.Number = 0 Then
        output = output & "  [OK] " & scheme & vbCrLf
    Else
        output = output & "  [ERROR] " & scheme & vbCrLf
        success = False
    End If
    
    On Error Goto 0
Next

output = output & vbCrLf & "Verifying registration..." & vbCrLf

' Verify
Dim value
For Each scheme In schemes
    On Error Resume Next
    value = objShell.RegRead("HKCU\Software\Classes\" & scheme & "\shell\open\command\")
    On Error Goto 0
    
    If value <> "" Then
        output = output & "  [OK] " & scheme & vbCrLf
    Else
        output = output & "  [ERROR] " & scheme & vbCrLf
        success = False
    End If
Next

output = output & vbCrLf

' Show result
If success Then
    output = output & "SUCCESS! Registration complete." & vbCrLf & vbCrLf & _
             "IMPORTANT - Windows Security:" & vbCrLf & _
             "Windows restricts URL handler changes for security." & vbCrLf & _
             "This is normal behavior to prevent malware." & vbCrLf & vbCrLf & _
             "If you still see a dialog when clicking links:" & vbCrLf & _
             "1. Select Daktela from the list" & vbCrLf & _
             "2. Check 'Always use this app'" & vbCrLf & _
             "3. Click OK" & vbCrLf & vbCrLf & _
             "After that, links will open directly in Daktela."
    MsgBox output, vbInformation, "Daktela URL Handler - Registration Complete"
Else
    MsgBox output, vbExclamation, "Daktela URL Handler - Error"
End If

' ============================================================================
' FUNCTION: Find Daktela Recursively
' ============================================================================

Function FindDaktelaRecursive(folderPath, maxDepth)
    On Error Resume Next
    
    If maxDepth <= 0 Then
        FindDaktelaRecursive = ""
        Exit Function
    End If
    
    If Not objFSO.FolderExists(folderPath) Then
        FindDaktelaRecursive = ""
        Exit Function
    End If
    
    Dim folder, file, subfolder
    Set folder = objFSO.GetFolder(folderPath)
    
    For Each file In folder.Files
        If LCase(file.Name) = "daktela.exe" Or LCase(file.Name) = "daktelaclient.exe" Then
            FindDaktelaRecursive = file.Path
            Exit Function
        End If
    Next
    
    For Each subfolder In folder.SubFolders
        If Not (InStr(subfolder.Name, "System") > 0 Or _
                InStr(subfolder.Name, "$RECYCLE") > 0 Or _
                InStr(subfolder.Name, "ProgramData") > 0) Then
            
            Dim found
            found = FindDaktelaRecursive(subfolder.Path, maxDepth - 1)
            If found <> "" Then
                FindDaktelaRecursive = found
                Exit Function
            End If
        End If
    Next
    
    On Error Goto 0
    FindDaktelaRecursive = ""
End Function
