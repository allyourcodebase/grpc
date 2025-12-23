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

filelists = extractFileLists(lines(), {'LIBGRPC_SRC', 'PUBLIC_HEADERS_C', 'LIBBORINGSSL_SRC', 'LIBCARES_SRC', 'LIBZ_SRC'})

for name, files in filelists.items():
    print('pub const ' + name.lower() + ' = .{')
    for f in files:
        print(f'    "{f}",')
    print('};')
