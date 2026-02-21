#!/usr/bin/perl
use strict; use warnings;

my $file = $ARGV[0] or die "Usage: $0 <file>\n";
open(my $fh, '<', $file) or die;
my $content = do { local $/; <$fh> };
close($fh);

cp($file, "$file.bak");

$content =~ s/pthread_setname_np\(thread->sys_thread, name\)/pthread_setname_np(name)/g;
$content =~ s/pthread_setname_np\(thread->sys_thread, "Worker"\)/pthread_setname_np("Worker")/g;
$content =~ s/.*pthread_condattr_setclock.*\n//g;

open(my $out, '>', $file) or die;
print $out $content;
close($out);
print "Patch 1 applied.\n";

sub cp { my ($s,$d)=@_; open(my $i,'<',$s)or die; open(my $o,'>',$d)or die; print $o do{local $/;<$i>}; }
