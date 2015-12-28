@echo off
REM Runs the Fusion Inventory agent, with the parameters passed in argument
REM by reparsing it, to solve strange bug between CFEngine and FusionInventory

REM Copyright (c) 2014 Normation SAS.

"c:\Program Files\FusionInventory-Agent\fusioninventory-agent.bat" %*
