'###############################################################################
'# CPU Identification Program
'###############################################################################
'# This program parses the registry informations under the key 
'# HKLM\Hardware\Description\System\CentralProcessor\ to output information about
'# the system's processor(s) in a standard format, as described below.
'#
'# The output is in XML format on stdout, and follows the pattern below:
'# <PROCESSORS>
'#   <PROCESSOR>
'#     <VENDOR>GenuineIntel</VENDOR>
'#     <FAMILY>6</FAMILY>
'#     <MODEL>23</MODEL>
'#     <NAME>Intel(R) Core(TM)2 Duo CPU P8700 @ 2.53GHz</NAME>
'#     <STEPPING>10</STEPPING>
'#     <FREQUENCY>2504</FREQUENCY>
'#   </PROCESSOR>
'# </PROCESSORS>
'#
'# If the registry cannot be read for some reason, the error return code is 2
'# If the data in the registry are incorrect (wrong formatting of the 
'# Identifier), the error return code is 1
'###############################################################################
'# This script has been tested on the following systems:
'#       - Windows 2000
'#       - Windows XP
'#       - Windows 2003
'#       - Windows 2008
'#
'# NOTA : On VirtualBox virtual systems, Windows might have trouble computing 
'# the max CPU frequency : http://support.microsoft.com/kb/888282
'###############################################################################
'# Copyright (c) 2010, Normation SAS - http://www.normation.com
'# All rights reserved.
'###############################################################################




Option Explicit
'### Constant declarations
   
Dim wshShell
Dim procVendor, procFamily, procModel, procName, procStepping, procSpeed
Dim procIdentifier

Dim posFamily, posModel, posStepping

Dim errorTest 

Dim outString, result

Dim nthProc

'### Instantiate script object
Set wshShell = WScript.CreateObject("WScript.Shell" )


'### Query the registry to fetch the values from the nth processor (if available)
'### Return the XML representation of the processor found
Function QueryProc(nthProc)

	procVendor = wshShell.RegRead ("HKLM\Hardware\Description\System\CentralProcessor\"&nthProc&"\VendorIdentifier" )

	procSpeed = wshShell.RegRead ("HKLM\Hardware\Description\System\CentralProcessor\"&nthProc&"\~Mhz" )

	procIdentifier = wshShell.RegRead ("HKLM\Hardware\Description\System\CentralProcessor\"&nthProc&"\Identifier" )

	procName = wshShell.RegRead ("HKLM\Hardware\Description\System\CentralProcessor\"&nthProc&"\ProcessorNameString" )

	posFamily = InStr(procIdentifier, "Family")
	posModel = InStr(procIdentifier, "Model")
	posStepping = InStr(procIdentifier, "Stepping")

	If posStepping = 0 OR posModel = 0 OR posFamily = 0 Then
		WScript.Echo "Registry content for Identifier is not as expected for processor " & nthProc
		WScript.Quit(1)
	End If

	procFamily = Trim(Mid(procIdentifier, posFamily+6, posModel - posFamily - 6))

	procModel = Trim(Mid(procIdentifier, posModel+5, posStepping - posModel - 5))

	procStepping = Trim(Mid(procIdentifier, posStepping+8, Len(procIdentifier) - posStepping - 8 +1))

	'### Create the XML output for this processor
	result = "  <PROCESSOR>" & VbCrLf

	result = result & "    <VENDOR>" & procVendor & "</VENDOR>" & VbCrLf
	result = result & "    <FAMILY>" & procFamily & "</FAMILY>" & VbCrLf
	result = result & "    <MODEL>" & procModel & "</MODEL>" & VbCrLf
	result = result & "    <NAME>" & procName & "</NAME>" & VbCrLf
	result = result & "    <STEPPING>" & procStepping & "</STEPPING>" & VbCrLf
'	result = result & "    <IDENTIFIER>" & procIdentifier & "</IDENTIFIER>" & VbCrLf
	result = result & "    <FREQUENCY>" & procSpeed & "</FREQUENCY>" & VbCrLf
	result = result & "  </PROCESSOR>" & VbCrLf

	QueryProc = result

End Function 

'### Check regRead capacity, and check that the nthProc exists
Function TestProc(nthProc)
	errorTest = wshShell.RegRead ("HKLM\Hardware\Description\System\CentralProcessor\"&nthProc&"\Identifier" )
	TestProc = errorTest 
End Function 


nthProc = 0

'### Check that the registry can be read
On Error Resume Next
TestProc(nthProc)
If err.number <> 0 then
	WScript.Echo "Could not read the registry"
	WScript.Quit(2)
End If


'### Read registry values


outString = "<PROCESSORS>"& VbCrLf


Do While err.number = 0
	outString = outString  & QueryProc(nthProc)
	nthProc  = nthProc + 1
	TestProc(nthProc)
Loop

outString = outString & "</PROCESSORS>"
WScript.Echo outString 

WScript.Quit(0)
