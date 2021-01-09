need    Hypervisor::IBM::POWER::HMC::REST::Config;
need    Hypervisor::IBM::POWER::HMC::REST::Config::Analyze;
need    Hypervisor::IBM::POWER::HMC::REST::Config::Dump;
need    Hypervisor::IBM::POWER::HMC::REST::Config::Optimize;
use     Hypervisor::IBM::POWER::HMC::REST::Config::Traits;
need    Hypervisor::IBM::POWER::HMC::REST::ETL::XML;
use     IP::Addr;
unit    class Hypervisor::IBM::POWER::HMC::REST::ManagementConsole::NetworkInterfaces::ManagementConsoleNetworkInterface:api<1>:auth<Mark Devine (mark@markdevine.com)>
            does Hypervisor::IBM::POWER::HMC::REST::Config::Analyze
            does Hypervisor::IBM::POWER::HMC::REST::Config::Dump
            does Hypervisor::IBM::POWER::HMC::REST::Config::Optimize
            does Hypervisor::IBM::POWER::HMC::REST::ETL::XML;

my      Bool                                        $names-checked          = False;
my      Bool                                        $analyzed               = False;
my      Lock                                        $lock                   = Lock.new;

has     Hypervisor::IBM::POWER::HMC::REST::Config   $.config                is required;
has     Bool                                        $.initialized           = False;
has     Str                                         $.InterfaceName         is conditional-initialization-attribute;
has     Str                                         $.NetworkAddress        is conditional-initialization-attribute;
has     Str                                         $.NetworkAddressIPV4    is conditional-initialization-attribute;
has     Str                                         $.NetworkAddressIPV6    is conditional-initialization-attribute;

method  xml-name-exceptions () { return set <Metadata>; }

submethod TWEAK {
    self.config.diag.post:      self.^name ~ '::' ~ &?ROUTINE.name if %*ENV<HIPH_SUBMETHOD>;
    my $proceed-with-name-check = False;
    my $proceed-with-analyze    = False;
    $lock.protect({
        if !$analyzed           { $proceed-with-analyze    = True; $analyzed      = True; }
        if !$names-checked      { $proceed-with-name-check = True; $names-checked = True; }
    });
    self.etl-node-name-check    if $proceed-with-name-check;
    self.init;
    self.analyze                if $proceed-with-analyze;
    self;
}

method init () {
    return self             if $!initialized;
    self.config.diag.post:  self.^name ~ '::' ~ &?ROUTINE.name if %*ENV<HIPH_METHOD>;
    $!InterfaceName         = self.etl-text(:TAG<InterfaceName>,    :$!xml) if self.attribute-is-accessed(self.^name, 'InterfaceName');
    $!NetworkAddress        = self.etl-text(:TAG<NetworkAddress>,   :$!xml) if self.attribute-is-accessed(self.^name, 'NetworkAddress');
    my ($ipv4, $ipv6)       = $!NetworkAddress.split: /\s+/;
    try {
        $!NetworkAddressIPV4 = $ipv4 if IP::Addr.new($ipv4);
    }
    try {
        $!NetworkAddressIPV6 = $ipv6 if IP::Addr.new($ipv6);
    }
    $!xml                   = Nil;
    $!initialized           = True;
    self;
}

=finish
