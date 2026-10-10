# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///

import sys
from collections import defaultdict

def extractFileLists(reader, desired: set[str]):
    result = defaultdict(list)
    inside = None
    in_condition = 0
    for line in reader:
        if line.startswith('if'):
            in_condition += 1
        elif line.startswith('endif'):
            in_condition -= 1
        elif not in_condition and not inside and '=' in line:
            sep = '+=' if '+=' in line else '='
            assigned, value = map(str.strip, line.split(sep, 1))
            if assigned in desired:
                if value and value[-1] == '\\':
                    inside = assigned
                    value = value[:-1].strip()
                if value:
                    result[assigned].append(value)
        elif inside:
            value = line.strip()
            dest = inside
            if value and value[-1] == '\\':
                value = value[:-1].strip()
            else:
                inside = None
            if value:
                result[dest].append(value)
    return result

def extractSubLists(prefix, current):
    sublists = defaultdict(list)
    for e in current:
        a, b, f = e.split('/', 2)
        sublists[f'{prefix}_{a}_{b.replace("-", "_")}'].append(f)
    return sublists

def splitByLanguage(prefix, current):
    sublists = defaultdict(list)
    for e in current:
        if e.endswith('.c'):
            sublists[f'{prefix}_c'].append(e)
        else:
            sublists[f'{prefix}_cpp'].append(e)
    return sublists

filelists = extractFileLists(sys.stdin, {'LIBGRPC_SRC', 'PUBLIC_HEADERS_C', 'LIBBORINGSSL_SRC', 'LIBCARES_SRC', 'LIBZ_SRC', 'CORE_VERSION'})

libgrpc = extractSubLists('libgrpc', filelists.pop('LIBGRPC_SRC'))
filelists |= libgrpc
libgrpc = splitByLanguage('libgrpc_src_core', filelists.pop('libgrpc_src_core'))
filelists |= libgrpc
filelists['libcares_src'] = [f.split('/', 3)[-1] for f in filelists.pop('LIBCARES_SRC')]
filelists['libboringssl_src'] = [f.split('/', 2)[-1] for f in filelists.pop('LIBBORINGSSL_SRC')]
filelists['libz_src'] = [f.split('/', 2)[-1] for f in filelists.pop('LIBZ_SRC')]

core_version = filelists.pop('CORE_VERSION')[0].split('.')

print(core_version, file=sys.stderr)
print('const std = @import("std");')
print('pub const core_version : std.SemanticVersion = .{', end='')
print(f' .major = {core_version[0]}, .minor = {core_version[1]}, .patch = {core_version[2]}', end='')
print(' };')

for name, files in filelists.items():
    print(name.lower(), file=sys.stderr)
    print('pub const ' + name.lower() + ' = .{')
    for f in files:
        print(f'    "{f}",')
    print('};')
