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

sub spaces_to_quoted {
    my $t = "\t" x $::INDENT if $::INDENT;

    join "\n$t", map { qq/"$_";/ } map { split ' ' } @_;
}

# PROSODY_MODULES_ENABLED globally activates modules (and makes them available)
my %ENABLED;
@ENABLED{split ' ', $ENV{PROSODY_MODULES_ENABLED} // ''} = ();

# PROSODY_MODULES_AVAILABLE symlinks community modules into plugin paths
my %AVAILABLE;
@AVAILABLE{split ' ', $ENV{PROSODY_MODULES_AVAILABLE} // ''} = ();

my %CORE = do {
    my @core = glob '/usr/lib/prosody/modules/mod_*.lua';
    push @core, '/usr/lib/prosody/modules/*/mod_*.lua';

    map { (/mod_(.+)\.lua/)[0] => undef } @core;
};

delete @AVAILABLE{keys %CORE};

# PROSODY_MODULES_DISABLED disables any (global) auto-enabled modules
my %DISABLE;
@DISABLE{split ' ', $ENV{PROSODY_MODULES_DISABLED} // ''} = ();

# PROSODY_MODULES_ENABLED overrides PROSODY_MODULES_DISABLED
delete @DISABLE{keys %ENABLED};

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
        elsif(exists $ENABLED{$modname}) {
            if ($in_auto_disabled_block) {
                comment_out;
            }
            else {
                uncomment;
            }

            # We put anything that's left into the config using the template var
            delete $ENABLED{$modname};
        }
    }
    continue {
        print;
    }
}

# Do this before deleting keys from %ENABLED
$ENV{PROSODY_ENABLED_MODULES} = do { local $::INDENT = 2; spaces_to_quoted(keys %ENABLED) };

# Link modules requested to be available into the enabled dir so all prosodies
# can see them. Only the ones in the main config will be enabled globally
# Don't try to symlink core modules
delete @ENABLED{keys %CORE};
system "ln", "-s", 
    "/opt/prosody-modules-available/mod_$_",
    "/opt/prosody-modules-enabled/mod_$_"
    for keys %AVAILABLE, keys %ENABLED
;

system "ln", "-s", 
    "/opt/prosody-modules-available/.hg",
    "/opt/prosody-modules-enabled/.hg"
;

if ($ENV{PROSODY_STORAGE} eq 'sql') {
    my $sqlconf = {
        driver      => $ENV{PROSODY_DB_DRIVER} // 'PostgreSQL',
        database    => $ENV{PROSODY_DB_NAME} // 'prosody',
        host        => $ENV{PROSODY_DB_HOST} // 'postgresql',
        port        => $ENV{PROSODY_DB_PORT} // 5432,
        username    => $ENV{PROSODY_DB_USERNAME} // 'prosody',
        password    => $ENV{PROSODY_DB_PASSWORD} // die "Must specify database password",
    };

    my $maybe_quote = sub {
        return qq/"$_[0]"/ unless looks_like_number $_[0];
        return $_[0];
    };

    my $sqlstr = "{ " . (join ", ", map { join ' = ', $_, $maybe_quote->($sqlconf->{$_}) } keys %$sqlconf) . " }";

    $ENV{PROSODY_SQL_CONNECTION} = $sqlstr;

# Set up the bootstrap vars before we fiddle with the configs
if ($ENV{PROSODY_BOOTSTRAP}) {
    my @admin_xids = split ' ', $ENV{PROSODY_BOOTSTRAP_ADMIN_XIDS};
    $ENV{PROSODY_BOOTSTRAP_ADMIN_XIDS_QUOTED} = join ',', map { qq/"$_"/ } @admin_xids;

    }
}

$ENV{$_} = spaces_to_quoted($ENV{$_}) for qw/
    PROSODY_S2S_SECURE_DOMAINS
    PROSODY_S2S_INSECURE_DOMAINS
/;

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
