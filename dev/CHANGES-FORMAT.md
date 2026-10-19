Formatting conventions for CHANGES.md
=====================================

CHANGES.md is the detailed list of significant, user-visible changes.  It is
read both rendered and as plain text, for example from an unpacked release
tarball, so the raw source is kept simple and consistent.

The conventions below apply to new entries in the current (topmost) release
section.  CI checks the mechanical ones with util/check-changes-format.pl.
Older sections are kept as published and are not reformatted.

File structure
--------------

The file begins with a level 1 heading and a table of contents:

```text
OpenSSL CHANGES
===============

OpenSSL Releases
----------------

 - [OpenSSL 4.2](#openssl-42)
 - [OpenSSL 4.1](#openssl-41)
```

Each release line has a level 2 heading, and each release within that line
has a level 3 section:

```text
OpenSSL 4.2
-----------

### Changes between 4.1 and 4.2 [xx XXX xxxx]
```

The most recent release lines and releases come first.  The table of
contents lists release lines (`x.y`), not individual patch releases.

While a release is under development its date is written as
`[xx XXX xxxx]`.  Once released, the date is replaced with the release date,
for example `[25 Aug 2026]`; the day is written without a leading zero.

Entries
-------

Each entry begins with a top-level bullet written as one space, an asterisk,
and one space:

```text
 * Added support for ...
```

Continuation lines are indented by exactly three spaces, which aligns the
text with the first word of the entry:

```text
 * Added support for ...
   and a continuation line.
```

Paragraphs within an entry are separated by a blank line.  Continuation
lines still use three spaces after the blank line.

Author attribution
------------------

Each entry normally ends with the author's name in italics, indented by
exactly three spaces:

```text
   *Author Name*
```

There is no space between the asterisks and the name.  Separate multiple
authors with "and" or a comma.  A blank line before the author line is
allowed but not required.

Pull request references
-----------------------

An optional HTML comment can link to the pull request.  It is indented by
exactly three spaces:

```text
   <!-- https://github.com/openssl/openssl/pull/12345 -->
```

Nested lists
------------

Nested list items are indented by four spaces for the first level, seven for
the second, and three more for each subsequent level.  Continuation lines
are two spaces deeper than the bullet they belong to.  Indented code blocks
use eight spaces.

```text
 * An entry:

    * A nested item
      with a continuation line.

       * A second-level nested item
```

NEWS.md
-------

NEWS.md uses the same overall structure but different mechanical settings:

- Section headings are
  `### Major changes between OpenSSL 4.1 and OpenSSL 4.2 [under development]`.
- Top-level bullets are indented by two spaces.
- Continuation lines are indented by four spaces.

The editorial conventions for NEWS.md are described in
[NEWS-FORMAT.md](NEWS-FORMAT.md).

What CI checks
--------------

`util/check-changes-format.pl` checks the current release section of
CHANGES.md and NEWS.md for:

- entry bullet indentation
- continuation, author, and pull request comment indentation
- malformed author lines
- tabs and trailing whitespace

It deliberately does not check historical sections, wording, or the editorial
content of either file.

Checking locally
----------------

Run the same check before submitting a pull request:

```sh
perl util/check-changes-format.pl CHANGES.md NEWS.md
```

The `--verbose` option also reports which section was checked.
