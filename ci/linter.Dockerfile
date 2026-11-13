FROM debian:trixie
LABEL ci=rudder/ci/linter.Dockerfile
ARG VERSION
ARG USER_ID=1000

ENV HOME=/tmp
RUN <<EOF
set -ex
useradd -r -u $USER_ID -d $HOME jenkins
apt-get -y update
apt-get install -y wget git default-jdk
wget https://packages.microsoft.com/config/debian/13/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
apt-get -y update
apt-get install -y powershell
pwsh -Command Install-Module -Name PSScriptAnalyzer -RequiredVersion $VERSION -Scope AllUsers -Confirm:\$false -Force
pwsh -Command Install-Module -Name Pester -Scope AllUsers -Confirm:\$false -Force
EOF

USER jenkins
ENTRYPOINT ["bash", "-c"]
