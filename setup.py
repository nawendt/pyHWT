from pathlib import Path

import numpy as np
from setuptools import Extension, setup


def scandir(src_dir):
    return list(Path(src_dir).rglob('**/*.pyx'))


def makeExtension(ext_path):
    ext_name = '.'.join(ext_path.with_suffix('').parts[1:])
    return Extension(
        ext_name,
        [ext_path],
        include_dirs=[np.get_include()],
        extra_compile_args=['-O3', '-Wall']
    )


ext_names = scandir('src')
extensions = [makeExtension(name) for name in ext_names]

if __name__ == '__main__':
    setup(
        ext_modules=extensions
    )
