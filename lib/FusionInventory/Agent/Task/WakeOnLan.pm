package FusionInventory::Agent::Task::WakeOnLan;

use strict;
use warnings;
use base 'FusionInventory::Agent::Task';

use constant ETH_P_ALL => 0x0003;
use constant PF_PACKET => 17;
use constant SOCK_PACKET => 10;

use English qw(-no_match_vars);
use Socket;

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Linux;
use FusionInventory::Agent::Tools::Network;

our $VERSION = '1.0';

sub isEnabled {
    my ($self) = @_;

    return $self->{target}->isa('FusionInventory::Agent::Target::Server');
}

sub run {
    my ($self, %params) = @_;

    my $client = FusionInventory::Agent::HTTP::Client::OCS->new(
        logger       => $self->{logger},
        user         => $params{user},
        password     => $params{password},
        proxy        => $params{proxy},
        ca_cert_file => $params{ca_cert_file},
        ca_cert_dir  => $params{ca_cert_dir},
        no_ssl_check => $params{no_ssl_check},
    );

    my $options = $self->getOptionsFromServer(
        $client, 'WAKEONLAN', 'wake on lan'
    );
    return unless $options;

    my $macaddress = $self->{WAKEONLAN}->{PARAM}->[0]->{MAC};

    return unless defined $macaddress;

    if ($macaddress !~ /^$mac_address_pattern$/) {
        die "invalid MAC address $macaddress, exiting";
    }
    $macaddress =~ s/://g;

    # Linux only
    eval {
        socket(SOCKET, PF_PACKET, SOCK_PACKET, 0);

        setsockopt(SOCKET, SOL_SOCKET, SO_BROADCAST, 1)
            or warn "Can't do setsockopt: $ERRNO\n";

        my $interface =
            first { $_->{MACADDR} }
            getInterfacesFromIfconfig(logger => $self->{logger});
        my $sourceMac = $interface->{MACADDR};
        $sourceMac =~ s/://g;

        $self->{logger}->debug(
            "Send magic packet to $macaddress directly on card driver"
        );

        my $magic_packet =
            (pack('H12', $macaddress)) .
            (pack('H12', $sourceMac)) .
            (pack('H4', "0842"));
        $magic_packet .= chr(0xFF) x 6 . (pack('H12', $macaddress) x 16);
        my $destination = pack("Sa14", 0, $interface->{DESCRIPTION});
        send(SOCKET, $magic_packet, 0, $destination)
            or warn "Couldn't send packet: $ERRNO";
        # TODO : For FreeBSD, send to /dev/bpf ....
    };

    return unless $EVAL_ERROR;

    # degraded WOL by UDP
    eval {
        socket(SOCKET, PF_INET, SOCK_DGRAM, getprotobyname('udp'));
        my $magic_packet = 
            chr(0xFF) x 6 .
            (pack('H12', $macaddress) x 16);
        my $sinbroadcast = sockaddr_in("9", inet_aton("255.255.255.255"));
        $self->{logger}->debug(
            "Send magic packet to $macaddress in UDP mode (degraded wol)"
        );
        send(SOCKET, $magic_packet, 0, $sinbroadcast);
    };

    return unless $EVAL_ERROR;

    $self->{logger}->debug("Impossible to send magic packet...");

    # For Windows, I don't know, just test
    # See http://msdn.microsoft.com/en-us/library/ms740548(VS.85).aspx
}

1;
__END__

=head1 NAME

FusionInventory::Agent::Task::WakeOnLan - Wake-on-lan task for FusionInventory 

=head1 DESCRIPTION

This task send a wake-on-lan packet to another host on the same network as the
agent host.
