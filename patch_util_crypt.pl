#!/usr/bin/perl
use strict; use warnings;

my $file = $ARGV[0] or die "Usage: $0 <file>\n";
open(my $fh, '<', $file) or die;
my $content = do { local $/; <$fh> };
close($fh);

my $search  = "    return new_algo->secure;\n";
my $replace = "    if (!new_algo)\n        return false;\n    return new_algo->secure;\n";

die "Pattern not found!\n" unless $content =~ /\Q$search\E/;
cp($file, "$file.bak");
$content =~ s/\Q$search\E/$replace/;
open(my $out, '>', $file) or die;
print $out $content;
close($out);
print "Patch 3 applied.\n";

sub cp { my ($s,$d)=@_; open(my $i,'<',$s)or die; open(my $o,'>',$d)or die; print $o do{local $/;<$i>}; }
