with open('cases/null.cl', "wb") as f:
    f.write(b'"' + b'a' + b'\x00' + b'a"\n')
    f.write(b'"' + b'a' + b'\x00' + b'a' * 1024 + b'"')
    f.write(b'"' + b'a' * 1024 + b'\x00' + b'a' * 2 + b'"')
    f.write(b'"' + b'a' * 1027 + b'\x00' + b'a' * 2 + b'"')
    f.write(b'"' + b'\x00')