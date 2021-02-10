need    Hypervisor::IBM::POWER::HMC::REST::Config;
need    Hypervisor::IBM::POWER::HMC::REST::Config::Analyze;
need    Hypervisor::IBM::POWER::HMC::REST::Config::Dump;
need    Hypervisor::IBM::POWER::HMC::REST::Config::Optimize;
use     Hypervisor::IBM::POWER::HMC::REST::Config::Traits;
need    Hypervisor::IBM::POWER::HMC::REST::ETL::XML;
unit    class Hypervisor::IBM::POWER::HMC::REST::ManagementConsole::UserObjectModelVersion:api<1>:auth<Mark Devine (mark@markdevine.com)>
            does Hypervisor::IBM::POWER::HMC::REST::Config::Analyze
            does Hypervisor::IBM::POWER::HMC::REST::Config::Dump
            does Hypervisor::IBM::POWER::HMC::REST::Config::Optimize
            does Hypervisor::IBM::POWER::HMC::REST::ETL::XML;

my      Bool                                        $names-checked          = False;
my      Bool                                        $analyzed               = False;
my      Lock                                        $lock                   = Lock.new;

has     Hypervisor::IBM::POWER::HMC::REST::Config   $.config                is required;
has     Bool                                        $.initialized           = False;
has     Str                                         $.MinorVersion          is conditional-initialization-attribute;
has     Str                                         $.SchemaNamespace       is conditional-initialization-attribute;

method  xml-name-exceptions () { return set <Metadata>; }

submethod TWEAK {
    self.config.diag.post:      self.^name ~ '::' ~ &?ROUTINE.name if %*ENV<HIPH_SUBMETHOD>;
    my $proceed-with-analyze    = False;
    $lock.protect({
        if !$analyzed           { $proceed-with-analyze    = True; $analyzed      = True; }
    });
    self.init;
    self.analyze                if $proceed-with-analyze;
    self;
}

method init () {
    return self             if $!initialized;
    self.config.diag.post:  self.^name ~ '::' ~ &?ROUTINE.name if %*ENV<HIPH_METHOD>;

    my $proceed-with-name-check = False;
    $lock.protect({
        if !$names-checked      { $proceed-with-name-check = True; $names-checked = True; }
    });
    self.etl-node-name-check    if $proceed-with-name-check;

    $!MinorVersion          = self.etl-text(:TAG<MinorVersion>,     :$!xml) if self.attribute-is-accessed(self.^name, 'MinorVersion');
    $!SchemaNamespace       = self.etl-text(:TAG<SchemaNamespace>,  :$!xml) if self.attribute-is-accessed(self.^name, 'SchemaNamespace');
    $!initialized           = True;
    $!xml                   = Nil;
    self;
}

=finish
