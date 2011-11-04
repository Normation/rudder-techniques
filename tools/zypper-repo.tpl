#############################################################
### This file is protected by your Rudder infrastructure. ###
### Manually editing the file might lead your Rudder      ###
### infrastructure to change back the server’s            ###
### configuration and/or to raise a compliance alert.     ###
#############################################################

[$(set_zypper_repos.zypper_name)]
name=$(set_zypper_repos.zypper_name)
enabled=$(set_zypper_repos.zypper_enabled)
autorefresh=0
baseurl=$(set_zypper_repos.zypper_url)
type=$(set_zypper_repos.zypper_type)
keeppackages=0
