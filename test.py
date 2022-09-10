import os
import glob

lexers = ['src/lexer', 'reference-binaries/lexer']
parsers = ['src/parser', 'reference-binaries/parser']
mysol = ['my', 'ref']

def test(mode, case):
    name = case.split('/')[-1].split('.')[0]
    print(f'-----{name}-----')
    if mode == 'lexer':
        for i, lexer in enumerate(lexers):
           os.system(f'{lexer} {case} > temp/{name}_{mysol[i]}.out 2>&1')
    elif mode == 'parser':
        for i, lexer in enumerate(lexers):
            parser = parsers[i]
            os.system(f'{lexer} {case} | {parser} > temp/{name}_{mysol[i]}.out 2>&1')
    os.system(f'diff temp/{name}_my.out temp/{name}_ref.out')

# mode = sys.argv[1]
mode = 'parser'
os.chdir('src')
os.system("make")
os.chdir('..')
if not os.path.exists("temp"):
    os.mkdir("temp")
os.system("rm temp/*")
cases = glob.glob(f"{mode}_cases/*.cl")
cases.extend(glob.glob("cases/*.cl"))

for case in cases:
    test(mode, case)
