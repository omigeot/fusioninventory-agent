package Ocsinventory::Agent::XML::Inventory;
# TODO: resort the functions
use strict;
use warnings;

use XML::Simple;
use Digest::MD5 qw(md5_base64);
use Config;

use Ocsinventory::Agent::Backend;

sub new {
  my (undef, $params) = @_;

  my $self = {};
  $self->{accountinfo} = $params->{accountinfo};
  $self->{accountconfig} = $params->{accountconfig};
  $self->{backend} = $params->{backend};
  my $logger = $self->{logger} = $params->{logger};
  $self->{config} = $params->{config};

  if (!($self->{config}{deviceid})) {
    $logger->fault ('deviceid unititalised!');
  }

  $self->{h}{QUERY} = ['INVENTORY'];
  $self->{h}{DEVICEID} = [$self->{config}->{deviceid}];
  $self->{h}{CONTENT}{ACCESSLOG} = {};
  $self->{h}{CONTENT}{BIOS} = {};
  $self->{h}{CONTENT}{CONTROLLERS} = [];
  $self->{h}{CONTENT}{CPUS} = [];
  $self->{h}{CONTENT}{DRIVES} = [];
  $self->{h}{CONTENT}{HARDWARE} = {
    # TODO move that in a backend module 
    ARCHNAME => [$Config{archname}]
  };
  $self->{h}{CONTENT}{MONITORS} = [];
  $self->{h}{CONTENT}{PORTS} = [];
  $self->{h}{CONTENT}{SLOTS} = [];
  $self->{h}{CONTENT}{STORAGES} = [];
  $self->{h}{CONTENT}{SOFTWARES} = [];
  $self->{h}{CONTENT}{VIDEOS} = [];
  $self->{h}{CONTENT}{VIRTUALMACHINES} = [];
  $self->{h}{CONTENT}{SOUNDS} = [];
  $self->{h}{CONTENT}{MODEMS} = [];

  # Is the XML centent initialised?
  $self->{isInitialised} = undef;

  bless $self;
}

sub initialise {
  my ($self) = @_;

  return if $self->{isInitialised};

  $self->{backend}->feedInventory ({inventory => $self});

}

sub addController {
  my ($self, $args) = @_;

  my $driver = $args->{DRIVER};
  my $name = $args->{NAME};
  my $manufacturer = $args->{MANUFACTURER};
  my $pciid = $args->{PCIID};
  my $pcislot = $args->{PCISLOT};
  my $type = $args->{TYPE};

  push @{$self->{h}{CONTENT}{CONTROLLERS}},
  {
    DRIVER => [$driver?$driver:''],
    NAME => [$name],
    MANUFACTURER => [$manufacturer],
    PCIID => [$pciid?$pciid:''],
    PCISLOT => [$pcislot?$pcislot:''],
    TYPE => [$type],

  };
}

sub addModems {
  my ($self, $args) = @_;

  my $description = $args->{DESCRIPTION};
  my $name = $args->{NAME};

  push @{$self->{h}{CONTENT}{MODEMS}},
  {

    DESCRIPTION => [$description],
    NAME => [$name],

  };
}

sub addDrives {
  my ($self, $args) = @_;

  my $createdate = $args->{CREATEDATE};
  my $free = $args->{FREE};
  my $filesystem = $args->{FILESYSTEM};
  my $label = $args->{LABEL};
  my $serial = $args->{SERIAL};
  my $total = $args->{TOTAL};
  my $type = $args->{TYPE};
  my $volumn = $args->{VOLUMN};

  push @{$self->{h}{CONTENT}{DRIVES}},
  {
    CREATEDATE => [$createdate?$createdate:''],
    FREE => [$free?$free:''],
    FILESYSTEM => [$filesystem?$filesystem:''],
    LABEL => [$label?$label:''],
    SERIAL => [$serial?$serial:''],
    TOTAL => [$total?$total:''],
    TYPE => [$type?$type:''],
    VOLUMN => [$volumn?$volumn:'']
  };
}

sub addStorages {
  my ($self, $args) = @_;

  my $logger = $self->{logger};

  my $description = $args->{DESCRIPTION};
  my $disksize = $args->{DISKSIZE};
  my $manufacturer = $args->{MANUFACTURER};
  my $model = $args->{MODEL};
  my $name = $args->{NAME};
  my $type = $args->{TYPE};
  my $serial = $args->{SERIAL};
  my $serialnumber = $args->{SERIALNUMBER};
  my $firmware = $args->{FIRMWARE};
  my $scsi_coid = $args->{SCSI_COID};
  my $scsi_chid = $args->{SCSI_CHID};
  my $scsi_unid = $args->{SCSI_UNID};
  my $scsi_lun = $args->{SCSI_LUN};

  $serialnumber = $serial;

  push @{$self->{h}{CONTENT}{STORAGES}},
  {

    DESCRIPTION => [$description?$description:''],
    DISKSIZE => [$disksize?$disksize:''],
    MANUFACTURER => [$manufacturer?$manufacturer:''],
    MODEL => [$model?$model:''],
    NAME => [$name?$name:''],
    TYPE => [$type?$type:''],
    SERIALNUMBER => [$serialnumber?$serialnumber:''],
    FIRMWARE => [$firmware?$firmware:''],
    SCSI_COID => [$scsi_coid?$scsi_coid:''],
    SCSI_CHID => [$scsi_chid?$scsi_chid:''],
    SCSI_UNID => [$scsi_unid?$scsi_unid:''],
    SCSI_LUN => [$scsi_lun?$scsi_lun:''],

  };
}

sub addMemories {
  my ($self, $args) = @_;

  my $capacity = $args->{CAPACITY};
  my $speed =  $args->{SPEED};
  my $type = $args->{TYPE};
  my $description = $args->{DESCRIPTION};
  my $caption = $args->{CAPTION};
  my $numslots = $args->{NUMSLOTS};

  my $serialnumber = $args->{SERIALNUMBER};

  push @{$self->{h}{CONTENT}{MEMORIES}},
  {

    CAPACITY => [$capacity?$capacity:''],
    DESCRIPTION => [$description?$description:''],
    CAPTION => [$caption?$caption:''],
    SPEED => [$speed?$speed:''],
    TYPE => [$type?$type:''],
    NUMSLOTS => [$numslots?$numslots:0],
    SERIALNUMBER => [$serialnumber?$serialnumber:'']

  };
}

sub addPorts {
  my ($self, $args) = @_;

  my $caption = $args->{CAPTION};
  my $description = $args->{DESCRIPTION};
  my $name = $args->{NAME};
  my $type = $args->{TYPE};


  push @{$self->{h}{CONTENT}{PORTS}},
  {

    CAPTION => [$caption?$caption:''],
    DESCRIPTION => [$description?$description:''],
    NAME => [$name?$name:''],
    TYPE => [$type?$type:''],

  };
}

sub addSlots {
  my ($self, $args) = @_;

  my $description = $args->{DESCRIPTION};
  my $designation = $args->{DESIGNATION};
  my $name = $args->{NAME};
  my $status = $args->{STATUS};


  push @{$self->{h}{CONTENT}{SLOTS}},
  {

    DESCRIPTION => [$description?$description:''],
    DESIGNATION => [$designation?$designation:''],
    NAME => [$name?$name:''],
    STATUS => [$status?$status:''],

  };
}

sub addSoftwares {
  my ($self, $args) = @_;

  my $comments = $args->{COMMENTS};
  my $filesize = $args->{FILESIZE};
  my $folder = $args->{FOLDER};
  my $from = $args->{FROM};
  my $installdate = $args->{INSTALLDATE};
  my $name = $args->{NAME};
  my $publisher = $args->{PUBLISHER};
  my $version = $args->{VERSION};


  push @{$self->{h}{CONTENT}{SOFTWARES}},
  {

    COMMENTS => [$comments?$comments:''],
    FILESIZE => [$filesize?$filesize:''],
    FOLDER => [$folder?$folder:''],
    FROM => [$from?$from:''],
    INSTALLDATE => [$installdate?$installdate:''],
    NAME => [$name?$name:''],
    PUBLISHER => [$publisher?$publisher:''],
    VERSION => [$version],

  };
}

sub addMonitors {
  my ($self, $args) = @_;

  my $base64 = $args->{BASE64};
  my $caption = $args->{CAPTION};
  my $description = $args->{DESCRIPTION};
  my $manufacturer = $args->{MANUFACTURER};
  my $serial = $args->{SERIAL};
  my $uuencode = $args->{UUENCODE};


  push @{$self->{h}{CONTENT}{MONITORS}},
  {

    BASE64 => [$base64?$base64:''],
    CAPTION => [$caption?$caption:''],
    DESCRIPTION => [$description?$description:''],
    MANUFACTURER => [$manufacturer?$manufacturer:''],
    SERIAL => [$serial?$serial:''],
    UUENCODE => [$uuencode?$uuencode:''],

  };
}

sub addVideos {
  my ($self, $args) = @_;

  my $chipset = $args->{CHIPSET};
  my $name = $args->{NAME};

  push @{$self->{h}{CONTENT}{VIDEOS}},
  {

    CHIPSET => [$chipset?$chipset:''],
    NAME => [$name?$name:''],

  };
}

sub addSounds {
  my ($self, $args) = @_;

  my $description = $args->{DESCRIPTION};
  my $manufacturer = $args->{MANUFACTURER};
  my $name = $args->{NAME};

  push @{$self->{h}{CONTENT}{SOUNDS}},
  {

    DESCRIPTION => [$description?$description:''],
    MANUFACTURER => [$manufacturer?$manufacturer:''],
    NAME => [$name?$name:''],

  };
}

sub addNetworks {
  # TODO IPSUBNET, IPMASK IPADDRESS seem to be missing.
  my ($self, $args) = @_;

  my $description = $args->{DESCRIPTION};
  my $driver = $args->{DRIVER};
  my $ipaddress = $args->{IPADDRESS};
  my $ipdhcp = $args->{IPDHCP};
  my $ipgateway = $args->{IPGATEWAY};
  my $ipmask = $args->{IPMASK};
  my $ipsubnet = $args->{IPSUBNET};
  my $macaddr = $args->{MACADDR};
  my $pcislot = $args->{PCISLOT};
  my $status = $args->{STATUS};
  my $type = $args->{TYPE};
  my $virtualdev = $args->{VIRTUALDEV};

  return unless $ipaddress;

  push @{$self->{h}{CONTENT}{NETWORKS}},
  {

    DESCRIPTION => [$description?$description:''],
    DRIVER => [$driver?$driver:''],
    IPADDRESS => [$ipaddress?$ipaddress:''],
    IPDHCP => [$ipdhcp?$ipdhcp:''],
    IPGATEWAY => [$ipgateway?$ipgateway:''],
    IPMASK => [$ipmask?$ipmask:''],
    IPSUBNET => [$ipsubnet?$ipsubnet:''],
    MACADDR => [$macaddr?$macaddr:''],
    PCISLOT => [$pcislot?$pcislot:''],
    STATUS => [$status?$status:''],
    TYPE => [$type?$type:''],
    VIRTUALDEV => [$virtualdev?$virtualdev:''],

  };
}

sub addPrinter {
  my ($self, $args) = @_;

  my $description = $args->{DESCRIPTION};
  my $driver = $args->{DRIVER};
  my $name = $args->{NAME};

  push @{$self->{h}{CONTENT}{PRINTERS}},
  {

    DESCRIPTION => [$description],
    DRIVER => [$driver],
    NAME => [$name],

  };
}


sub setHardware {
  my ($self, $args, $nonDeprecated) = @_;

  my $logger = $self->{logger};

  foreach my $key (qw/USERID OSVERSION PROCESSORN OSCOMMENTS CHECKSUM
    PROCESSORT NAME PROCESSORS SWAP ETIME TYPE OSNAME IPADDR WORKGROUP
    DESCRIPTION MEMORY UUID DNS LASTLOGGEDUSER
    DATELASTLOGGEDUSER DEFAULTGATEWAY/) {

    if (exists $args->{$key}) {
      if ($key eq 'PROCESSORS' && !$nonDeprecated) {
          $logger->debug("PROCESSORN, PROCESSORS and PROCESSORT shouldn't be set directly anymore. Please use addCPU() method instead.");
      }
      $self->{h}{'CONTENT'}{'HARDWARE'}{$key}[0] = $args->{$key};
    }
  }
}

sub setBios {
  my ($self, $args) = @_;

  foreach my $key (qw/SMODEL SMANUFACTURER BDATE SSN BVERSION BMANUFACTURER ASSETTAG/) {

    if (exists $args->{$key}) {
      $self->{h}{'CONTENT'}{'BIOS'}{$key}[0] = $args->{$key};
    }
  }
}

sub addCPU {
  my ($self, $args) = @_;

  # The CPU FLAG
  my $manufacturer = $args->{MANUFACTURER};
  my $type = $args->{TYPE};
  my $serial = $args->{SERIAL};
  my $speed = $args->{SPEED};

  push @{$self->{h}{CONTENT}{CPUS}},
  {

    MANUFACTURER => [$manufacturer],
    TYPE => [$type],
    SERIAL => [$serial],
    SPEED => [$speed],

  };

  # For the compatibility with HARDWARE/PROCESSOR*
  my $processorn = int @{$self->{h}{CONTENT}{CPUS}};
  my $processors = $self->{h}{CONTENT}{CPUS}[0]{SPEED}[0];
  my $processort = $self->{h}{CONTENT}{CPUS}[0]{TYPE}[0];

  $self->setHardware ({
    PROCESSORN => $processorn,
    PROCESSORS => $processors,
    PROCESSORT => $processort,
  }, 1);

}

sub addPrinters {
  my ($self, $args) = @_;

  my $description = $args->{DESCRIPTION};
  my $driver = $args->{DRIVER};
  my $name = $args->{NAME};
  my $port = $args->{PORT};

  push @{$self->{h}{CONTENT}{PRINTERS}},
  {

    DESCRIPTION => [$description?$description:''],
    DRIVER => [$driver?$driver:''],
    NAME => [$name?$name:''],
    PORT => [$port?$port:''],

  };
}



sub addVirtualMachine {
  my ($self, $args) = @_;

  # The CPU FLAG
  my $memory = $args->{MEMORY};
  my $name = $args->{NAME};
  my $uuid = $args->{UUID};
  my $status = $args->{STATUS};
  my $subsystem = $args->{SUBSYSTEM};
  my $vmtype = $args->{VMTYPE};
  my $vcpu = $args->{VCPU};
  my $vmid = $args->{VMID};

  push @{$self->{h}{CONTENT}{VIRTUALMACHINES}},
  {

      MEMORY =>  [$memory],
      NAME => [$name],
      UUID => [$uuid],
      STATUS => [$status],
      SUBSYSTEM => [$subsystem],
      VMTYPE => [$vmtype],
      VCPU => [$vcpu],
      VMID => [$vmid],

  };

}

sub addProcesses {
  my ($self, $args) = @_;

  my $user = $args->{USER};
  my $pid = $args->{PID};
  my $cpu = $args->{CPU};
  my $mem = $args->{MEM};
  my $vsz = $args->{VSZ};
  my $rss = $args->{RSS};
  my $tty = $args->{TTY};
  my $stat = $args->{STAT};
  my $started = $args->{STARTED};
  my $time = $args->{TIME};
  my $cmd = $args->{CMD};

  push @{$self->{h}{CONTENT}{PROCESSES}},
  {
    USER => [$user?$user:''],
    PID => [$pid?$pid:''],
    CPU => [$cpu?$cpu:''],
    MEM => [$mem?$mem:''],
    VSZ => [$vsz?$vsz:0],
    RSS => [$rss?$rss:0],
    TTY => [$tty?$tty:''],
    STAT => [$stat?$stat:''],
    STARTED => [$started?$started:''],
    TIME => [$time?$time:''],
    CMD => [$cmd?$cmd:''],
  };
}


sub setAccessLog {
  my ($self, $args) = @_;

  foreach my $key (qw/USERID LOGDATE/) {

    if (exists $args->{$key}) {
      $self->{h}{'CONTENT'}{'ACCESSLOG'}{$key}[0] = $args->{$key};
    }
  }
}

sub addIpDiscoverEntry {
  my ($self, $args) = @_;

  my $ipaddress = $args->{IPADDRESS};
  my $macaddr = $args->{MACADDR};
  my $name = $args->{NAME};

  if (!$self->{h}{CONTENT}{IPDISCOVER}{H}) {
    $self->{h}{CONTENT}{IPDISCOVER}{H} = [];
  }

  push @{$self->{h}{CONTENT}{IPDISCOVER}{H}}, {
    # If I or M is undef, the server will ingore the host
    I => [$ipaddress?$ipaddress:""],
    M => [$macaddr?$macaddr:""],
    N => [$name?$name:"-"], # '-' is the default value reteurned by ipdiscover
  };
}

sub getContent {
  my ($self, $args) = @_;

  my $logger = $self->{logger};

  $self->initialise();

  $self->processChecksum();

  #  checks for MAC, NAME and SSN presence
  my $macaddr = $self->{h}->{CONTENT}->{NETWORKS}->[0]->{MACADDR}->[0];
  my $ssn = $self->{h}->{CONTENT}->{BIOS}->{SSN}->[0];
  my $name = $self->{h}->{CONTENT}->{HARDWARE}->{NAME}->[0];

  my $missing;

  $missing .= "MAC-address " unless $macaddr;
  $missing .= "SSN " unless $ssn;
  $missing .= "HOSTNAME " unless $name;

  if ($missing) {
    $logger->debug('Missing value(s): '.$missing.'. I will send this inventory to the server BUT important value(s) to identify the computer are missing');
  }

  $self->{accountinfo}->setAccountInfo($self);

  my $content = XMLout( $self->{h}, RootName => 'REQUEST', XMLDecl => '<?xml version="1.0" encoding="UTF-8"?>', SuppressEmpty => undef );

  my $clean_content;
  # To avoid strange breakage I remove the unprintable caractere in the XML
  foreach (split "\n", $content) {
      s/[[:cntrl:]]//g;
      $clean_content .= $_."\n";
  }

  return $clean_content;
}

sub printXML {
  my ($self, $args) = @_;

  $self->initialise();
  print $self->getContent();
}

sub writeXML {
  my ($self, $args) = @_;

  my $logger = $self->{logger};

  if ($self->{config}{local} =~ /^$/) {
    $logger->fault ('local path unititalised!');
  }

  $self->initialise();

  my $localfile = $self->{config}{local}."/".$self->{config}{deviceid}.'.ocs';
  $localfile =~ s!(//){1,}!/!;

  # Convert perl data structure into xml strings

  if (open OUT, ">$localfile") {
    print OUT $self->getContent();
    close OUT or warn;
    $logger->info("Inventory saved in $localfile");
  } else {
    warn "Can't open `$localfile': $!"
  }
}

sub processChecksum {
  my $self = shift;

  my $logger = $self->{logger};
#To apply to $checksum with an OR
  my %mask = (
    'HARDWARE'      => 1,
    'BIOS'          => 2,
    'MEMORIES'      => 4,
    'SLOTS'         => 8,
    'REGISTRY'      => 16,
    'CONTROLLERS'   => 32,
    'MONITORS'      => 64,
    'PORTS'         => 128,
    'STORAGES'      => 256,
    'DRIVES'        => 512,
    'INPUT'         => 1024,
    'MODEMS'        => 2048,
    'NETWORKS'      => 4096,
    'PRINTERS'      => 8192,
    'SOUNDS'        => 16384,
    'VIDEOS'        => 32768,
    'SOFTWARES'     => 65536
    'VIRTUALMACHINES' => 131072,
  );
  # TODO CPUS is not in the list

  if (!$self->{config}->{vardir}) {
    $logger->fault ("vardir uninitialised!");
  }

  my $checksum = 0;

  if (!$self->{config}{local} && $self->{config}->{last_statefile}) {
    if (-f $self->{config}->{last_statefile}) {
      # TODO: avoid a violant death in case of problem with XML
      $self->{last_state_content} = XML::Simple::XMLin(
  
        $self->{config}->{last_statefile},
        SuppressEmpty => undef,
        ForceArray => 1

      );
    } else {
      $logger->debug ('last_state file: `'.
  	$self->{config}->{last_statefile}.
  	"' doesn't exist (yet).");
    }
  }

  foreach my $section (keys %mask) {
    #If the checksum has changed...
    my $hash = md5_base64(XML::Simple::XMLout($self->{h}{'CONTENT'}{$section}));
    if (!$self->{last_state_content}->{$section}[0] || $self->{last_state_content}->{$section}[0] ne $hash ) {
      $logger->debug ("Section $section has changed since last inventory");
      #We make OR on $checksum with the mask of the current section
      $checksum |= $mask{$section};
      # Finally I store the new value.
      $self->{last_state_content}->{$section}[0] = $hash;
    }
  }


  $self->setHardware({CHECKSUM => $checksum});
}

# At the end of the process IF the inventory was saved
# correctly, I save the last_state
sub saveLastState {
  my ($self, $args) = @_;

  my $logger = $self->{logger};

  if (!defined($self->{last_state_content})) {
	  $self->processChecksum();
  }

  if (!defined ($self->{config}->{last_statefile})) {
    $logger->debug ("Can't save the last_state file. File path is not initialised.");
    return;
  }

  if (open LAST_STATE, ">".$self->{config}->{last_statefile}) {
    print LAST_STATE my $string = XML::Simple::XMLout( $self->{last_state_content}, RootName => 'LAST_STATE' );;
    close LAST_STATE or warn;
  } else {
    $logger->debug ("Cannot save the checksum values in ".$self->{config}->{last_statefile}."
	(will be synchronized by GLPI!!): $!"); 
  }
}

sub addSection {
  my ($self, $args) = @_;
  my $logger = $self->{logger};
  my $multi = $args->{multi};
  my $tagname = $args->{tagname};

  for( keys %{$self->{h}{CONTENT}} ){
    if( $tagname eq $_ ){
      $logger->debug("Tag name `$tagname` already exists - Don't add it");
      return 0;
    }
  }

  if($multi){
    $self->{h}{CONTENT}{$tagname} = [];
  }
  else{
    $self->{h}{CONTENT}{$tagname} = {};
  }
  return 1;
}

sub feedSection{
  my ($self, $args) = @_;
  my $tagname = $args->{tagname};
  my $values = $args->{data};
  my $logger = $self->{logger};

  my $found=0;
  for( keys %{$self->{h}{CONTENT}} ){
    $found = 1 if $tagname eq $_;
  }

  if(!$found){
    $logger->debug("Tag name `$tagname` doesn't exist - Cannot feed it");
    return 0;
  }

  if( $self->{h}{CONTENT}{$tagname} =~ /ARRAY/ ){
    push @{$self->{h}{CONTENT}{$tagname}}, $args->{data};
  }
  else{
    $self->{h}{CONTENT}{$tagname} = $values;
  }

  return 1;
}

1;
