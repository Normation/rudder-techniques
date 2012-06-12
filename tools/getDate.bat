@echo off
rem Get the time from WMI - at least that's a format we can work with
set X=
for /f "skip=1 delims=" %%x in ('wmic os get localdatetime') do if not defined X set X=%%x

rem dissect into parts
set DATE.YEAR=%X:~0,4%
set DATE.MONTH=%X:~4,2%
set DATE.DAY=%X:~6,2%
set DATE.HOUR=%X:~8,2%
set DATE.MINUTE=%X:~10,2%
set DATE.SECOND=%X:~12,2%
set DATE.FRACTIONS=%X:~15,6%
set DATE.SIGN=%X:~21,1%
set /a DATE.OFFSET=%X:~22,3%/60



echo %DATE.YEAR%-%DATE.MONTH%-%DATE.DAY% %DATE.HOUR%:%DATE.MINUTE%:%DATE.SECOND%%DATE.SIGN%%DATE.OFFSET%:00
