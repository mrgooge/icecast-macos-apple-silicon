#!/usr/bin/perl
use strict; use warnings;

my $file = $ARGV[0] or die "Usage: $0 <file>\n";
open(my $fh, '<', $file) or die;
my $content = do { local $/; <$fh> };
close($fh);

my $search = qq(    reportxml_t *report = client_get_reportxml("0aa76ea1-bf42-49d1-887e-ca95fb307dc4", NULL, NULL);\n    reportxml_node_t *reportnode = reportxml_get_node_by_type(report, REPORTXML_NODE_TYPE_REPORT, 0);\n    reportxml_node_t *incident = reportxml_get_node_by_type(report, REPORTXML_NODE_TYPE_INCIDENT, 0);\n);

my $replace = qq(    reportxml_t *report = client_get_reportxml("0aa76ea1-bf42-49d1-887e-ca95fb307dc4", NULL, NULL);\n    if (!report) {\n        ICECAST_LOG_ERROR("Dashboard report definition not found in database. Sending 500.");\n        config_release_config();\n        client_send_error_by_id(client, ICECAST_ERROR_GEN_HEADER_GEN_FAILED);\n        return;\n    }\n    reportxml_node_t *reportnode = reportxml_get_node_by_type(report, REPORTXML_NODE_TYPE_REPORT, 0);\n    reportxml_node_t *incident = reportxml_get_node_by_type(report, REPORTXML_NODE_TYPE_INCIDENT, 0);\n    if (!reportnode || !incident) {\n        ICECAST_LOG_ERROR("Dashboard report missing required REPORT or INCIDENT node. Sending 500.");\n        config_release_config();\n        refobject_unref(report);\n        client_send_error_by_id(client, ICECAST_ERROR_GEN_HEADER_GEN_FAILED);\n        return;\n    }\n);

die "Pattern not found!\\n" unless $content =~ /\\Q$search\\E/;
cp($file, "$file.bak");
$content =~ s/\\Q$search\\E/$replace/;
open(my $out, '>', $file) or die;
print $out $content;
close($out);
print "Patch 2 applied.\\n";

sub cp { my ($s,$d)=@_; open(my $i,'<',$s)or die; open(my $o,'>',$d)or die; print $o do{local $/;<$i>}; }
