@echo OFF
REM Fetching all users from the system, formated as
REM user1      user2      user3
REM user4      user5

FOR /F "delims=[]" %%A IN ('NET USER ^| FIND /N "----"') DO SET HeaderLines=%%A
FOR /F "tokens=*"  %%A IN ('NET USER') DO SET FooterLine=%%A
NET USER | MORE /E +%HeaderLines% | FIND /V "%FooterLine%"
