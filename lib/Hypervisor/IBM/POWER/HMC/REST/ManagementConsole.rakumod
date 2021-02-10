need    Hypervisor::IBM::POWER::HMC::REST::Atom;
need    Hypervisor::IBM::POWER::HMC::REST::Config;
need    Hypervisor::IBM::POWER::HMC::REST::Config::Analyze;
need    Hypervisor::IBM::POWER::HMC::REST::Config::Dump;
need    Hypervisor::IBM::POWER::HMC::REST::Config::Optimize;
use     Hypervisor::IBM::POWER::HMC::REST::Config::Traits;
need    Hypervisor::IBM::POWER::HMC::REST::ETL::XML;
need    Hypervisor::IBM::POWER::HMC::REST::ManagementConsole::MachineTypeModelAndSerialNumber;
need    Hypervisor::IBM::POWER::HMC::REST::ManagementConsole::MemConfiguration;
need    Hypervisor::IBM::POWER::HMC::REST::ManagementConsole::NetworkInterfaces;
need    Hypervisor::IBM::POWER::HMC::REST::ManagementConsole::TemplateObjectModelVersion;
need    Hypervisor::IBM::POWER::HMC::REST::ManagementConsole::UserObjectModelVersion;
need    Hypervisor::IBM::POWER::HMC::REST::ManagementConsole::WebObjectModelVersion;
need    Hypervisor::IBM::POWER::HMC::REST::ManagementConsole::ProcConfiguration;
need    Hypervisor::IBM::POWER::HMC::REST::ManagementConsole::VersionInfo;
use     URI;
unit    class Hypervisor::IBM::POWER::HMC::REST::ManagementConsole:api<1>:auth<Mark Devine (mark@markdevine.com)>
            does Hypervisor::IBM::POWER::HMC::REST::Config::Analyze
            does Hypervisor::IBM::POWER::HMC::REST::Config::Dump
            does Hypervisor::IBM::POWER::HMC::REST::Config::Optimize
            does Hypervisor::IBM::POWER::HMC::REST::ETL::XML;

my      Bool                                                                                    $names-checked  = False;
my      Bool                                                                                    $analyzed       = False;
my      Lock                                                                                    $lock           = Lock.new;

has     Hypervisor::IBM::POWER::HMC::REST::Config                                               $.config        is required;
has     Bool                                                                                    $.initialized   = False;

has     Hypervisor::IBM::POWER::HMC::REST::Atom                                                 $.atom;
has     Str                                                                                     $.id                                    is conditional-initialization-attribute;
has     Str                                                                                     @.AuthorizedKeysValue                   is conditional-initialization-attribute;
has     Str                                                                                     $.BaseVersion                           is conditional-initialization-attribute;
has     Str                                                                                     $.BIOS                                  is conditional-initialization-attribute;
has     Str                                                                                     $.Driver                                is conditional-initialization-attribute;
has     Str                                                                                     $.LicenseID                             is conditional-initialization-attribute;
has     Str                                                                                     $.LicenseFirstYear                      is conditional-initialization-attribute;
has     Str                                                                                     @.IFixDetails                           is conditional-initialization-attribute;
has     Hypervisor::IBM::POWER::HMC::REST::ManagementConsole::MachineTypeModelAndSerialNumber   $.MachineTypeModelAndSerialNumber       is conditional-initialization-attribute;
has     URI                                                                                     @.ManagedSystems                        is conditional-initialization-attribute;
has     Str                                                                                     $.ManagementConsoleName                 is conditional-initialization-attribute;
has     Hypervisor::IBM::POWER::HMC::REST::ManagementConsole::MemConfiguration                  $.MemConfiguration                      is conditional-initialization-attribute;
has     Hypervisor::IBM::POWER::HMC::REST::ManagementConsole::NetworkInterfaces                 $.NetworkInterfaces                     is conditional-initialization-attribute;
has     Hypervisor::IBM::POWER::HMC::REST::ManagementConsole::TemplateObjectModelVersion        $.TemplateObjectModelVersion            is conditional-initialization-attribute;
has     Hypervisor::IBM::POWER::HMC::REST::ManagementConsole::UserObjectModelVersion            $.UserObjectModelVersion                is conditional-initialization-attribute;
has     Hypervisor::IBM::POWER::HMC::REST::ManagementConsole::ProcConfiguration                 $.ProcConfiguration                     is conditional-initialization-attribute;
has     Str                                                                                     $.PublicSSHKeyValue                     is conditional-initialization-attribute;
has     Hypervisor::IBM::POWER::HMC::REST::ManagementConsole::VersionInfo                       $.VersionInfo                           is conditional-initialization-attribute;
has     Hypervisor::IBM::POWER::HMC::REST::ManagementConsole::WebObjectModelVersion             $.WebObjectModelVersion                 is conditional-initialization-attribute;

method  xml-name-exceptions () { return set <Metadata>; }

submethod TWEAK {
    self.config.diag.post:      self.^name ~ '::' ~ &?ROUTINE.name if %*ENV<HIPH_SUBMETHOD>;
    my $proceed-with-analyze    = False;
    $lock.protect({
        if !$analyzed           { $proceed-with-analyze    = True; $analyzed      = True; }
    });
    self.analyze                if $proceed-with-analyze;
    self;
}

method init () {
    return self                             if $!initialized;
    self.config.diag.post:                  self.^name ~ '::' ~ &?ROUTINE.name if %*ENV<HIPH_METHOD>;
    my $init-start                          = now;

    my $fetch-start                         = now;
    my $xml-path                            = self.config.session-manager.fetch('/rest/api/uom/ManagementConsole');
    self.config.diag.post:                  sprintf("%-20s %10s: %11s", self.^name.subst(/^.+'::'(.+)$/, {$0}), 'FETCH', sprintf("%.3f", now - $fetch-start)) if %*ENV<HIPH_FETCH>;

    my $parse-start                         = now;
    self.etl-parse-path(:$xml-path);
    self.config.diag.post:                  sprintf("%-20s %10s: %11s", self.^name.subst(/^.+'::'(.+)$/, {$0}), 'PARSE', sprintf("%.3f", now - $parse-start)) if %*ENV<HIPH_PARSE>;

    my $xml-entry                           = self.etl-branch(:TAG<entry>,                                                                          :$!xml);
    my $xml-content                         = self.etl-branch(:TAG<content>,                                                                        :xml($xml-entry));
    my $xml-ManagementConsole               = self.etl-branch(:TAG<ManagementConsole:ManagementConsole>,                                            :xml($xml-content));

    my $proceed-with-name-check             = False;
    $lock.protect({
        if !$names-checked  { $proceed-with-name-check = True; $names-checked = True; }
    });
    self.etl-node-name-check(:xml($xml-ManagementConsole)) if $proceed-with-name-check;

    $!atom                                  = self.etl-atom(:xml(self.etl-branch(:TAG<Metadata>,                                                    :xml($xml-ManagementConsole))))                 if self.attribute-is-accessed(self.^name, 'BaseVersion');
    $!id                                    = self.etl-text(:TAG<id>,                                                                               :xml($xml-entry))                               if self.attribute-is-accessed(self.^name, 'id');
    if self.attribute-is-accessed(self.^name, 'AuthorizedKeysValue') {
        my $xml-AuthorizedKeysValue         = self.etl-branch(:TAG<AuthorizedKeysValue>,                                                            :xml($xml-ManagementConsole));
        @!AuthorizedKeysValue               = self.etl-texts(:TAG<AuthorizedKey>,                                                                   :xml($xml-AuthorizedKeysValue));
    }
    $!BaseVersion                           = self.etl-text(:TAG<BaseVersion>,                                                                      :xml($xml-ManagementConsole))                   if self.attribute-is-accessed(self.^name, 'BaseVersion');
    $!BIOS                                  = self.etl-text(:TAG<BIOS>,                                                                             :xml($xml-ManagementConsole))                   if self.attribute-is-accessed(self.^name, 'BIOS');
    $!Driver                                = self.etl-text(:TAG<Driver>,                                                                           :xml($xml-ManagementConsole), :optional)        if self.attribute-is-accessed(self.^name, 'Driver');
    $!LicenseID                             = self.etl-text(:TAG<LicenseID>,                                                                        :xml($xml-ManagementConsole), :optional)        if self.attribute-is-accessed(self.^name, 'LicenseID');
    $!LicenseFirstYear                      = self.etl-text(:TAG<LicenseFirstYear>,                                                                 :xml($xml-ManagementConsole), :optional)        if self.attribute-is-accessed(self.^name, 'LicenseFirstYear');
    if self.attribute-is-accessed(self.^name, 'IFixDetails') {
        my $xml-IFixDetails                 = self.etl-branch(:TAG<IFixDetails>,                                                                    :xml($xml-ManagementConsole));
        my @ifds                            = ();
        for self.etl-branches(:TAG<IFixDetail>, :xml($xml-IFixDetails)) -> $xml-IFixDetail {
            @ifds.push: self.etl-text(:TAG<IFix>, :xml($xml-IFixDetail));
        }
        @!IFixDetails                       = @ifds;
    }
    if self.attribute-is-accessed(self.^name, 'MachineTypeModelAndSerialNumber') {
        my $xml-MachineTypeModelAndSerialNumber = self.etl-branch(:TAG<MachineTypeModelAndSerialNumber>,                                            :xml($xml-ManagementConsole));
        $!MachineTypeModelAndSerialNumber   = Hypervisor::IBM::POWER::HMC::REST::ManagementConsole::MachineTypeModelAndSerialNumber.new(:$!config,  :xml($xml-MachineTypeModelAndSerialNumber));
    }
    if self.attribute-is-accessed(self.^name, 'ManagedSystems') {
        my $xml-ManagedSystems              = self.etl-branch(:TAG<ManagedSystems>,                                                                 :xml($xml-ManagementConsole));
        @!ManagedSystems                    = self.etl-links-URIs(                                                                                  :xml($xml-ManagedSystems));
    }
    $!ManagementConsoleName                 = self.etl-text(:TAG<ManagementConsoleName>,                                                            :xml($xml-ManagementConsole))                   if self.attribute-is-accessed(self.^name, 'ManagementConsoleName');
    if self.attribute-is-accessed(self.^name, 'MemConfiguration') {
        my $xml-MemConfiguration            = self.etl-branch(:TAG<MemConfiguration>,                                                               :xml($xml-ManagementConsole));
        $!MemConfiguration                  = Hypervisor::IBM::POWER::HMC::REST::ManagementConsole::MemConfiguration.new(:$!config,                 :xml($xml-MemConfiguration));
    }
    if self.attribute-is-accessed(self.^name, 'NetworkInterfaces') {
        my $xml-NetworkInterfaces           = self.etl-branch(:TAG<NetworkInterfaces>,                                                              :xml($xml-ManagementConsole));
        $!NetworkInterfaces                 = Hypervisor::IBM::POWER::HMC::REST::ManagementConsole::NetworkInterfaces.new(:$!config,                :xml($xml-NetworkInterfaces));
    }
    if self.attribute-is-accessed(self.^name, 'TemplateObjectModelVersion') {
        my $xml-TemplateObjectModelVersion  = self.etl-branch(:TAG<TemplateObjectModelVersion>,                                                     :xml($xml-ManagementConsole));
        $!TemplateObjectModelVersion        = Hypervisor::IBM::POWER::HMC::REST::ManagementConsole::TemplateObjectModelVersion.new(:$!config,       :xml($xml-TemplateObjectModelVersion));
    }
    if self.attribute-is-accessed(self.^name, 'UserObjectModelVersion') {
        my $xml-UserObjectModelVersion      = self.etl-branch(:TAG<UserObjectModelVersion>,                                                         :xml($xml-ManagementConsole));
        $!UserObjectModelVersion            = Hypervisor::IBM::POWER::HMC::REST::ManagementConsole::UserObjectModelVersion.new(:$!config,           :xml($xml-UserObjectModelVersion));
    }
    if self.attribute-is-accessed(self.^name, 'ProcConfiguration') {
        my $xml-ProcConfiguration           = self.etl-branch(:TAG<ProcConfiguration>,                                                              :xml($xml-ManagementConsole));
        $!ProcConfiguration                 = Hypervisor::IBM::POWER::HMC::REST::ManagementConsole::ProcConfiguration.new(:$!config,                :xml($xml-ProcConfiguration));
    }
    $!PublicSSHKeyValue                     = self.etl-text(:TAG<PublicSSHKeyValue>,        :xml($xml-ManagementConsole))                                                                           if self.attribute-is-accessed(self.^name, 'PublicSSHKeyValue');
    if self.attribute-is-accessed(self.^name, 'VersionInfo') {
        my $xml-VersionInfo                 = self.etl-branch(:TAG<VersionInfo>,                                                                    :xml($xml-ManagementConsole));
        $!VersionInfo                       = Hypervisor::IBM::POWER::HMC::REST::ManagementConsole::VersionInfo.new(:$!config,                      :xml($xml-VersionInfo));
    }
    if self.attribute-is-accessed(self.^name, 'WebObjectModelVersion') {
        my $xml-WebObjectModelVersion       = self.etl-branch(:TAG<WebObjectModelVersion>,                                                          :xml($xml-ManagementConsole));
        $!WebObjectModelVersion             = Hypervisor::IBM::POWER::HMC::REST::ManagementConsole::WebObjectModelVersion.new(:$!config,            :xml($xml-WebObjectModelVersion));
    }
    $!xml                                   = Nil;
    $!initialized                           = True;
    self.config.diag.post:                  sprintf("%-20s %10s: %11s", self.^name.subst(/^.+'::'(.+)$/, {$0}), 'INITIALIZE', sprintf("%.3f", now - $init-start)) if %*ENV<HIPH_INIT>;
    self;
}

method Managed-System-Ids () {
    self.config.diag.post: self.^name ~ '::' ~ &?ROUTINE.name if %*ENV<HIPH_METHOD>;
    my @managed-system-ids;
    for self.ManagedSystems -> $ms-url {
        @managed-system-ids.push: $ms-url.segments[* - 1];
    }
    return @managed-system-ids;
}

=finish
