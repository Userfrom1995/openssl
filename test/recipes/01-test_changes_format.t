#! /usr/bin/env perl
# Copyright 2026 The OpenSSL Project Authors. All Rights Reserved.
#
# Licensed under the Apache License 2.0 (the "License").  You may not use
# this file except in compliance with the License.  You can obtain a copy
# in the file LICENSE in the source distribution or at
# https://www.openssl.org/source/license.html

use strict;
use warnings;

use File::Path qw(make_path);
use File::Spec::Functions qw(catdir catfile);
use File::Temp qw(tempdir);
use IPC::Cmd ();
use OpenSSL::Test qw(:DEFAULT srctop_file);

setup("test_changes_format");

my $checker = srctop_file("util", "check-changes-format.pl");

plan skip_all => "util/check-changes-format.pl is not available"
    unless -f $checker;

plan tests => 10;

my $tmp = tempdir(CLEANUP => 1);
my $seq = 0;

sub check {
    my ($name, $text, $want_ok, $desc) = @_;
    my $dir = catdir($tmp, "case" . ++$seq);
    make_path($dir);
    my $file = catfile($dir, $name);

    open(my $fh, '>', $file) or die "Cannot write $file: $!";
    print $fh $text;
    close $fh;

    my ($ok, $err) = IPC::Cmd::run(command => [ $^X, $checker, $file ],
                                   capture => 1);

    ok($want_ok ? $ok : !$ok, $desc)
        or diag("checker output: " . ($err // ""));
}

check("CHANGES.md", <<'EOF', 1, "valid CHANGES.md entry");
OpenSSL CHANGES
===============

OpenSSL 4.2
-----------

### Changes between 4.1 and 4.2 [xx XXX xxxx]

 * An entry.
   A continuation line.

   *Author Name*

 * Another entry.
   <!-- https://github.com/openssl/openssl/pull/12345 -->

   *Another Author*
EOF

check("CHANGES.md", <<'EOF', 0, "CHANGES.md entry with two leading spaces");
### Changes between 4.1 and 4.2 [xx XXX xxxx]

  * Bad entry.
EOF

check("CHANGES.md", <<'EOF', 0, "CHANGES.md continuation with four spaces");
### Changes between 4.1 and 4.2 [xx XXX xxxx]

 * An entry.
    Bad continuation.
EOF

check("CHANGES.md", <<'EOF', 0, "CHANGES.md malformed author line");
### Changes between 4.1 and 4.2 [xx XXX xxxx]

 * An entry.

   * Author Name*
EOF

check("CHANGES.md", <<'EOF', 0, "CHANGES.md author line with four spaces");
### Changes between 4.1 and 4.2 [xx XXX xxxx]

 * An entry.

    *Author Name*
EOF

check("CHANGES.md", "### Changes between 4.1 and 4.2 [xx XXX xxxx]\n\n"
    . " * An entry. \n", 0, "CHANGES.md trailing whitespace");

check("NEWS.md", <<'EOF', 1, "valid NEWS.md section with an opener paragraph");
OpenSSL 4.2
-----------

### Major changes between OpenSSL 4.1 and OpenSSL 4.2 [under development]

OpenSSL 4.2.0 is a feature release adding significant new functionality.

This release adds the following new features:

  * A feature.

    An elaborating paragraph.

  * Another feature.
EOF

check("NEWS.md", <<'EOF', 0, "NEWS.md bullet at column 0 after an opener");
### Major changes between OpenSSL 4.1 and OpenSSL 4.2 [under development]

OpenSSL 4.2.0 is a feature release adding significant new functionality.

* Bad entry.
EOF

check("NEWS.md", <<'EOF', 0, "NEWS.md continuation with three spaces");
### Major changes between OpenSSL 4.1 and OpenSSL 4.2 [under development]

  * An entry.
   Bad continuation.
EOF

check("README.md", "anything\n", 0, "unsupported file name is rejected");
