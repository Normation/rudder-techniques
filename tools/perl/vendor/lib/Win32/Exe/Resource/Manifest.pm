package Win32::Exe::Resource::Manifest;

use strict;
use base 'Win32::Exe::Resource';
use constant FORMAT => (
    Data        => 'a*',
);

sub get_manifest {
    my ($self ) = @_;
    return $self->dump;    
}

sub set_manifest {
    my ( $self, $xmltext ) = @_;
    $self->SetData( $self->encode_manifest($xmltext) );
    my $rsrc = $self->first_parent('Resources');
    $rsrc->remove("/#RT_MANIFEST");
    $rsrc->insert("/#RT_MANIFEST/#1/#0" => $self);
    $rsrc->refresh;
}

sub update_manifest {
    my ( $self, $xmltext ) = @_;
    $self->SetData( $self->encode_manifest($xmltext) );
}

sub encode_manifest {
    my ($self, $string) = @_;
    return pack("a*", $string);
}

sub default_manifest {
    my ( $self ) = @_;
    my $defman =  <<'W32EXEDEFAULTMANIFEST'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">
    <assemblyIdentity processorArchitecture="x86" version="0.0.0.0" type="win32" name="Win32.Exe.Application" />
    <description>Win32.Exe.Application</description>
    <trustInfo xmlns="urn:schemas-microsoft-com:asm.v3">
        <security>
            <requestedPrivileges>
                <requestedExecutionLevel level="asInvoker" uiAccess="false" />
            </requestedPrivileges>
        </security>
    </trustInfo>
    <dependency>
        <dependentAssembly>
            <assemblyIdentity type="win32" name="Microsoft.Windows.Common-Controls" version="6.0.0.0" publicKeyToken="6595b64144ccf1df" language="*" processorArchitecture="x86" />
        </dependentAssembly>
    </dependency>
</assembly>
W32EXEDEFAULTMANIFEST
;


    return $defman;
}

1;
