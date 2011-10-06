@echo off
REM Loop through all the adapters registered in the registry
REM and return a list of them, separated by ;
REM ###############################################################################
REM # Copyright (c) 2010, Normation SAS - http://www.normation.com
REM # All rights reserved.
REM ###############################################################################


setlocal enabledelayedexpansion


set adapters=

FOR /F "tokens=8* delims=\" %%a IN ('REG QUERY "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Adapters"') do (
	if not defined adapters (
		set adapters=%%a
	) else (
		set adapters=!adapters!;%%a
	)
)

echo %adapters%

endlocal
