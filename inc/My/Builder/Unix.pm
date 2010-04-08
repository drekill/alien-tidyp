package My::Builder::Unix;

use strict;
use warnings;
use base 'My::Builder';

use File::Spec::Functions qw(catdir catfile rel2abs);
use File::Spec qw(devnull);
use Config;

sub build_binaries {
  my ($self, $build_out) = @_;
  my $prefixdir = rel2abs($build_out);

  chdir "src/build/gmake";
  print "Gonna cd build/gmake & make install ...\n";
  my @cmd = ($self->get_make, 'installhdrs', 'installib', 'installexes',
                              "runinst_prefix=$prefixdir", "devinst_prefix=$prefixdir", "CC=$Config{cc}");
  print "[cmd: ".join(' ',@cmd)."]\n";
  $self->do_system(@cmd) or die "###ERROR### [$?] during make ... ";
  chdir $self->base_dir();

  return 1;
}

sub make_clean {
  my ($self) = @_;

  chdir "src/build/gmake";
  print "Gonna cd build/gmake & make clean\n";
  my @cmd = ($self->get_make, 'clean');
  print "[cmd: ".join(' ',@cmd)."]\n";
  $self->do_system(@cmd) or warn "###WARN### [$?] during make ... ";
  chdir $self->base_dir();

  return 1;
}

sub get_make {
  my ($self) = @_;
  my $devnull = File::Spec->devnull();
  my @try = ($Config{gmake}, 'gmake', 'make', $Config{make});
  my %tested;
  print "Gonna detect GNU make:\n";
  print "- \$Config{gmake} = $Config{gmake}\n";
  print "- \$Config{make} = $Config{make}\n";
  foreach my $name ( @try ) {
    next unless $name;
    next if $tested{$name};
    $tested{$name} = 1;
    print "- testing: '$name'\n";
    my $ver = `$name -v 2> $devnull`;
    my $rv = system("$name -v > $devnull 2>&1");
    print "  rv=$rv\n$ver";
    if ($ver =~ /GNU Make/i) {
      print "- found: '$name'\n";
      return $name
    }
  }
  warn "###WARN### GNU make autodetection failed\n";
  my $fallback = ($^O eq 'solaris') ? 'gmake' : 'make';
  print "- fallback to: '$fallback'\n";
  return $fallback;
}

sub quote_literal {
    my ($self, $txt) = @_;
    $txt =~ s|'|'\\''|g;
    return "'$txt'";
}

1;
