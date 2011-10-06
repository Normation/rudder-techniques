#!/bin/bash

# Retrieve the list of running VM, remove the first line (Total running VMs), escpare the space, and read the uuid for each of them.
# Return a list of couple "VM" {UUID} 
vmrun list |  sed '1d' | sed "s/ /\\\\\\\\ /g" | while read line; do
  echo $line | xargs -I{}  vmrun readVariable {} runtimeConfig uuid.bios | xargs -I{} echo \"$line\"  \{{}\} 
done



