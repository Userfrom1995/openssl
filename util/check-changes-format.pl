#! /usr/bin/env perl
# Copyright 2026 The OpenSSL Project Authors. All Rights Reserved.
#
# Licensed under the Apache License 2.0 (the "License").  You may not use
# this file except in compliance with the License.  You can obtain a copy
# in the file LICENSE in the source distribution or at
# https://www.openssl.org/source/license.html

#
# Check the mechanical formatting of entries in CHANGES.md and NEWS.md.
#
# Only the topmost (current) release section is checked.  Older sections
# use historical conventions that are intentionally not rewritten, and
# they are not relevant to the formatting of new contributions.
#
# Usage: perl util/check-changes-format.pl [--verbose] CHANGES.md|NEWS.md ...
#

use strict;
use warnings;

use File::Basename qw(basename);
use Getopt::Long qw(GetOptions);

my %PROFILES = (
    'CHANGES.md' => {
        kind          => 'changes',
        heading       => qr/^### Changes between /,
        section       => qr/^### Changes between \S+ and \S+ \[(?:xx XXX xxxx|(?:[1-9]|[12][0-9]|3[01]) (?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) [0-9]{4})\]$/,
        entry         => qr/^ \* /,
        entry_indent  => 1,
        cont_indent   => 3,
        prose_at_col0 => 0,
    },
    'NEWS.md' => {
        kind          => 'news',
        heading       => qr/^### Major changes between /,
        section       => qr/^### Major changes between OpenSSL \S+ and OpenSSL \S+ \[(?:under development|(?:[1-9]|[12][0-9]|3[01]) (?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) [0-9]{4})\]$/,
        entry         => qr/^  \* /,
        entry_indent  => 2,
        cont_indent   => 4,
        prose_at_col0 => 1,
    },
);

my $verbose = 0;

GetOptions('verbose|v' => \$verbose, 'help|h' => \my $help)
    or usage(1);
usage(0) if $help;
usage(1) unless @ARGV;

my $status = 0;
$status |= check_file($_) for @ARGV;
exit $status;

sub usage {
    my $status = shift;

    print STDERR "Usage: $0 [--verbose] CHANGES.md|NEWS.md ...\n";
    exit $status;
}

sub check_file {
    my $file = shift;
    my $base = basename($file);
    my $p    = $PROFILES{$base};

    if (!defined $p) {
        print STDERR "$file: unsupported file (expected CHANGES.md or NEWS.md)\n";
        return 1;
    }

    open(my $fh, '<', $file) or do {
        print STDERR "$file: cannot open: $!\n";
        return 1;
    };
    my @lines = <$fh>;
    close $fh;
    s/\r?\n\z// for @lines;

    my $start;
    for my $i (0 .. $#lines) {
        if ($lines[$i] =~ $p->{heading}) {
            $start = $i;
            last;
        }
    }
    if (!defined $start) {
        print STDERR "$file: no release section found\n";
        return 1;
    }
    if ($lines[$start] !~ $p->{section}) {
        print STDERR $file . ':' . ($start + 1) . ': malformed section heading: '
            . $lines[$start] . "\n";
        return 1;
    }

    my @errors;
    my $last_bullet = $p->{entry_indent};
    my $checked     = 0;

    for (my $i = $start + 1 ; $i <= $#lines ; $i++) {
        my $line = $lines[$i];

        # The current section ends at the next heading, or at the next
        # setext release heading ("OpenSSL x.y" followed by an underline).
        last if $line =~ /^### /;
        last if $line =~ /^OpenSSL \S/
            && ($lines[$i + 1] // '') =~ /^-{3,}$/;

        $checked++;

        my $err = sub {
            push @errors, $file . ':' . ($i + 1) . ': ' . $_[0];
        };

        if ($line =~ /\t/) {
            $err->('tab character');
        }
        if ($line =~ /[ \t]\z/) {
            $err->('trailing whitespace');
        }
        next if $line eq '';

        if ($line =~ $p->{entry}) {
            $err->('entry bullet has no text') if $line =~ /^\s*\*\s*\z/;
            $last_bullet = $p->{entry_indent};
            next;
        }

        if ($line =~ /^(\s+)(.*)$/) {
            my $indent = length($1);
            my $rest   = $2;

            if ($p->{kind} eq 'changes') {
                if ($indent == $p->{cont_indent}) {
                    if ($rest =~ /^\*(?=\S)[^*]*(?<=\S)\*$/) {
                        $last_bullet = $p->{entry_indent};
                        next;
                    }
                    if ($rest =~ /^\* /) {
                        $err->('entry bullet must be indented 1 space (found 3)');
                    } elsif ($rest =~ /^\*[^*]*\*\s*$/) {
                        $err->("malformed author line (expected '   *Name*')");
                    }
                    next;
                }

                if ($indent >= 4 && $rest =~ /^\* /) {
                    if (($indent - $p->{entry_indent}) % 3 != 0) {
                        $err->('nested list bullet must be indented 4, 7, 10, ... spaces'
                            . " (found $indent)");
                    } elsif ($rest =~ /^\*\s*\z/) {
                        $err->('nested list bullet has no text');
                    } else {
                        $last_bullet = $indent;
                    }
                    next;
                }

                next if $indent == $last_bullet + 2;

                # Indented code block inside an entry.
                next if $indent >= 8 && $last_bullet == $p->{entry_indent};

                if ($rest =~ /^\*(?=\S)[^*]*(?<=\S)\*$/) {
                    $err->("author line must be indented 3 spaces (found $indent)");
                } elsif ($rest =~ /^\* /) {
                    $err->("entry bullet must be indented 1 space (found $indent)");
                } else {
                    $err->("continuation line must be indented 3 spaces (found $indent)");
                }
                next;
            }

            # NEWS.md
            if ($indent >= $p->{cont_indent}) {
                $err->("continuation line must be indented 4 spaces (found $indent)")
                    if $indent % 2 != 0;
                $err->('bullet has no text') if $rest =~ /^\*\s*\z/;
                next;
            }

            if ($rest =~ /^\* /) {
                $err->("entry bullet must be indented 2 spaces (found $indent)");
            } else {
                $err->("continuation line must be indented 4 spaces (found $indent)");
            }
            next;
        }

        # Column 0.
        if ($p->{prose_at_col0}) {
            $err->('entry bullet must be indented 2 spaces')
                if $line =~ /^[*+-] /;
            next;
        }
        if ($line =~ /^[*+-] /) {
            $err->('entry bullet must be indented 1 space');
        } else {
            $err->('unexpected unindented line');
        }
    }

    printf "%s: checked %d line(s) in section starting at line %d\n",
        $file, $checked, $start + 1 if $verbose;

    if (@errors) {
        print STDERR "$_\n" for @errors;
        print STDERR "$file: " . scalar(@errors) . " formatting issue(s) found\n";
        return 1;
    }

    print "$file: format looks good\n" unless $verbose;
    return 0;
}
