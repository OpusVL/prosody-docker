#!/usr/bin/env perl
use strict;
use warnings;
use v5.24;

my @configs = (
    "/etc/prosody/prosody.cfg.lua",
    "/etc/prosody/conf.d/modules.cfg.lua",
    "/etc/prosody/conf.d/logging.cfg.lua",
);

for my $conf (@configs) {
    open my $inconffh, "<", $conf;

    my @outlines;
    for (<$inconffh>) {
        push @outlines,
        s#\$\{
            ([^}]+?)
            (?::-([^}]*?))
        \}
        #$ENV{$1} // $2#xger
        ;
    }

    close $inconffh;
    open my $outconffh, ">", $conf;
    print $outconffh $_ for @outlines;
}

system "ln", "-s", "/opt/prosody-modules-available/mod_$_", "/opt/prosody-modules-enabled/mod_$_"
    for map s/"//gr, split /[,;]\s*/, $ENV{PROSODY_COMM_MODULES};

exec @ARGV;
