import sys
from collections import defaultdict

def lines():
    while True:
        try:
            yield input()
        except:
            break

def extractFileLists(reader, desired: set[str]):
    result = defaultdict(list)
    inside = None
    for line in reader:
        if inside is None and '=' in line:
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

filelists = extractFileLists(lines(), {'LIBGRPC_SRC', 'PUBLIC_HEADERS_C', 'LIBBORINGSSL_SRC', 'LIBCARES_SRC', 'LIBZ_SRC'})

libgrpc = extractSubLists('libgrpc', filelists.pop('LIBGRPC_SRC'))
filelists |= libgrpc
libgrpc = splitByLanguage('libgrpc_src_core', filelists.pop('libgrpc_src_core'))
filelists |= libgrpc

for name, files in filelists.items():
    print(name.lower(), file=sys.stderr)
    print('pub const ' + name.lower() + ' = .{')
    for f in files:
        print(f'    "{f}",')
    print('};')
