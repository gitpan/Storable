#!./perl

# $Id: blessed.t,v 0.7 2000/08/03 22:04:44 ram Exp $
#
#  Copyright (c) 1995-2000, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# $Log: blessed.t,v $
# Revision 0.7  2000/08/03 22:04:44  ram
# Baseline for second beta release.
#

require 't/dump.pl';
sub ok;

use Storable qw(freeze thaw);

print "1..10\n";

package SHORT_NAME;

sub make { bless [], shift }

package SHORT_NAME_WITH_HOOK;

sub make { bless [], shift }

sub STORABLE_freeze {
	my $self = shift;
	return ("", $self);
}

sub STORABLE_thaw {
	my $self = shift;
	my $cloning = shift;
	my ($x, $obj) = @_;
	die "STORABLE_thaw" unless $obj eq $self;
}

package main;

# Still less than 256 bytes, so long classname logic not fully exercised
# Wait until Perl removes the restriction on identifier lengths.
my $name = "LONG_NAME_" . 'xxxxxxxxxxxxx::' x 14 . "final";

eval <<EOC;
package $name;

\@ISA = ("SHORT_NAME");
EOC
die $@ if $@;
ok 1, $@ eq '';

eval <<EOC;
package ${name}_WITH_HOOK;

\@ISA = ("SHORT_NAME_WITH_HOOK");
EOC
ok 2, $@ eq '';

# Construct a pool of objects
my @pool;

for (my $i = 0; $i < 10; $i++) {
	push(@pool, SHORT_NAME->make);
	push(@pool, SHORT_NAME_WITH_HOOK->make);
	push(@pool, $name->make);
	push(@pool, "${name}_WITH_HOOK"->make);
}

my $x = freeze \@pool;
ok 3, 1;

my $y = thaw $x;
ok 4, ref $y eq 'ARRAY';
ok 5, @{$y} == @pool;

ok 6, ref $y->[0] eq 'SHORT_NAME';
ok 7, ref $y->[1] eq 'SHORT_NAME_WITH_HOOK';
ok 8, ref $y->[2] eq $name;
ok 9, ref $y->[3] eq "${name}_WITH_HOOK";

my $good = 1;
for (my $i = 0; $i < 10; $i++) {
	do { $good = 0; last } unless ref $y->[4*$i]   eq 'SHORT_NAME';
	do { $good = 0; last } unless ref $y->[4*$i+1] eq 'SHORT_NAME_WITH_HOOK';
	do { $good = 0; last } unless ref $y->[4*$i+2] eq $name;
	do { $good = 0; last } unless ref $y->[4*$i+3] eq "${name}_WITH_HOOK";
}
ok 10, $good;
