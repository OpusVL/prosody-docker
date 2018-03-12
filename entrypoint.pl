#!/usr/bin/env perl
use strict;
use warnings;
use v5.22;
use Scalar::Util qw/looks_like_number/;

my $confdir = $ENV{PROSODY_CONFIGDIR} // '/etc/prosody';

my @configs = (
    "$confdir/prosody.cfg.lua",
    my $moduleconf = "$confdir/conf.d/modules.cfg.lua",
    "$confdir/conf.d/logging.cfg.lua",
    "$confdir/conf.d/bootstrap.cfg.lua",
);

sub comment_out (_) {
    return if /^\s*--/;

    s/^(\s*)/$1--/;
}

sub uncomment (_) {
    s/^(\s*)--/$1/;
}

my %COMM;
@COMM{split ' ', $ENV{PROSODY_COMM_MODULES} // ''} = ();

my %CORE;
@CORE{split ' ', $ENV{PROSODY_CORE_MODULES} // ''} = ();

my %DISABLE;
@DISABLE{split ' ', $ENV{PROSODY_MODULES_DISABLED} // ''} = ();

my %ENABLE = (%COMM, %CORE);

{
    # In-place edit the module conf based on env vars.
    # We replace the values of the env vars at the end so when we interpolate
    # them into the configs, they work as expected
    local @ARGV = $moduleconf;
    local $^I = '';

    my $in_auto_disabled_block = 0;
    while (<>) {
        $in_auto_disabled_block = 1 if /^modules_disabled/ and not $in_auto_disabled_block;

        my ($modname) = /"([^"]+)"/ or next;

        if (exists $DISABLE{$modname}) {
            if ($in_auto_disabled_block) {
                uncomment;
            }
            else {
                comment_out;
            }
        }
        elsif(exists $ENABLE{$modname}) {
            if ($in_auto_disabled_block) {
                comment_out;
            }
            else {
                uncomment;
            }

            delete $COMM{$modname};
            delete $CORE{$modname};
        }
    }
    continue {
        print;
    }
}

# Link the requested community modules into the enabled directory. This is
# because some community modules clash with core modules so we have to be
# selective.
system "ln", "-s", 
    "/opt/prosody-modules-available/mod_$_",
    "/opt/prosody-modules-enabled/mod_$_"
    for keys %COMM;

$ENV{PROSODY_ENABLED_MODULES} = join "\n\t\t", map { qq/"$_";/ } keys %ENABLE;

# Set up the bootstrap vars before we fiddle with the configs
if ($ENV{PROSODY_BOOTSTRAP}) {
    my @admin_xids = split ' ', $ENV{PROSODY_BOOTSTRAP_ADMIN_XIDS};
    $ENV{PROSODY_BOOTSTRAP_ADMIN_XIDS_QUOTED} = join ',', map { qq/"$_"/ } @admin_xids;

    if ($ENV{PROSODY_BOOTSTRAP_STORAGE} eq 'sql') {
        my $sqlconf = {
            driver      => $ENV{PROSODY_BOOTSTRAP_DB_DRIVER} // 'PostgreSQL',
            database    => $ENV{PROSODY_BOOTSTRAP_DB_NAME} // 'prosody',
            host        => $ENV{PROSODY_BOOTSTRAP_DB_HOST} // 'postgresql',
            port        => $ENV{PROSODY_BOOTSTRAP_DB_PORT} // 5432,
            username    => $ENV{PROSODY_BOOTSTRAP_DB_USERNAME} // 'prosody',
            password    => $ENV{PROSODY_BOOTSTRAP_DB_PASSWORD} // die "Must specify database password",
        };

        my $maybe_quote = sub {
            return qq/"$_[0]"/ unless looks_like_number $_[0];
            return $_[0];
        };

        my $sqlstr = "{ " . (join ", ", map { join ' = ', $_, $maybe_quote->($sqlconf->{$_}) } keys %$sqlconf) . " }";

        $ENV{PROSODY_BOOTSTRAP_SQL_CONNECTION} = $sqlstr;
    }
}

# Go through all of the config files and interpolate environment variables into
# them. ${ENV_VAR_NAME:-default}
for my $conf (@configs) {
    open my $inconffh, "<", $conf;

    my @outlines;
    for (readline $inconffh) {
        push @outlines,
        s#\$\{
            ([^}]+?)
            (?::-([^}]*?))?
        \}
        #$ENV{$1} // $2 // ''#xger
        ;
    }

    close $inconffh;
    open my $outconffh, ">", $conf;
    print $outconffh $_ for @outlines;
}

exec @ARGV;
