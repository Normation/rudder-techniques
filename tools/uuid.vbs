' Retrieve the UUID of the motherboard using WMI
strComputer = "." 
Set objWMIService = GetObject("winmgmts:" _
    & "{impersonationLevel=impersonate}!\\" _
    & strComputer & "\root\cimv2")

Set colItems = objWMIService.ExecQuery _
("Select * from Win32_ComputerSystemProduct")


For Each objItem in colItems
	WScript.Echo objItem.UUID
Next

