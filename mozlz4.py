#!/usr/bin/env python
# https://unix.stackexchange.com/questions/326897/how-to-decompress-jsonlz4-files-firefox-bookmark-backups-using-the-command-lin
# pip install lz4

from sys import stdin, stdout, argv, stderr
import os
try:
    import lz4.block as lz4
except ImportError:
    import lz4

stdin = os.fdopen(stdin.fileno(), 'rb')
stdout = os.fdopen(stdout.fileno(), 'wb')

if argv[1:] == ['-c']:
    stdout.write(b'mozLz40\0' + lz4.compress(stdin.read()))
elif argv[1:] == ['-d']:
    assert stdin.read(8) == b'mozLz40\0'
    stdout.write(lz4.decompress(stdin.read()))
else:
    stderr.write('Usage: %s -c|-d < infile > outfile\n' % argv[0])
    stderr.write('Compress or decompress Mozilla-flavor LZ4 files.\n\n')
    stderr.write('Examples:\n')
    stderr.write('\t%s -d < infile.json.mozlz4 > outfile.json\n' % argv[0])
    stderr.write('\t%s -c < infile.json > outfile.json.mozlz4\n' % argv[0])
    exit(1)