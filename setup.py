"""
************************************************************************
*
* GPL 
*
* This file is part of pysdif3
*
* pysdif3 is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* pysdif3 is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
* 
* You should have received a copy of the GNU General Public License
* If not, see <http://www.gnu.org/licenses/>.
*************************************************************************
"""

import sys
from setuptools import setup, Extension
from setuptools.command.build_ext import build_ext as build_ext_orig
import glob
import os


def configure_sdif_unix():
    os.chdir("SDIF")
    os.system("./configure")
    os.chdir("..")


def cmake_step():
    os.makedirs("SDIF/build", exist_ok=True)
    os.chdir("SDIF/build")
    os.system("cmake ..")
    os.chdir("../..")
    assert os.path.exists("SDIF/build/sdifconfig/sdif.h")
    assert os.path.exists("SDIF/build/sdifconfig/config.h")
     

def is_newer(file1, file2):
    """ Return True if file1 is newer than file2 """
    t1 = os.path.getmtime(file1)
    t2 = os.path.getmtime(file2)
    return t1 > t2
    

def cython_step():
    if os.path.exists("pysdif/_pysdif.c") and not is_newer("pysdif/_pysdif.pyx", "pysdif/_pysdif.c"):
        return
    from Cython.Compiler.Main import compile
    compilation_result = compile("pysdif/_pysdif.pyx")
    print("Compiled cython file: ", compilation_result.c_file)


class build_ext(build_ext_orig):
    def run(self):
        cython_step()
        cmake_step()
        super().run()


def get_version():
    d = {}
    with open("pysdif/version.py") as f:
        code = f.read()
    exec(code, d)
    version = d.get('__version__', (0, 0, 0))
    return version


class numpy_include(str):

    def __str__(self):
        import numpy
        return numpy.get_include()


library_dirs = []

compile_args = [
    '-fno-strict-aliasing',
    '-Werror-implicit-function-declaration',
    '-Wfatal-errors'
]

sources = []
sdif_base = os.path.join("SDIF")
sdif_sources = glob.glob(os.path.join(sdif_base, 'sdif', '*.c'))
sdif_headers = glob.glob(os.path.join(sdif_base, 'include', '*.h'))
sources.extend(sdif_sources)

include_dirs = []
include_dirs.append(os.path.join(sdif_base, 'include'))
include_dirs.append(os.path.join(sdif_base, 'sdif'))
include_dirs.append(os.path.join(sdif_base, 'build', 'sdifconfig'))


if sys.platform == "windows":
    compile_args += ["-march=i686"]
elif sys.platform == "linux":
    include_dirs.append("/usr/local/include/")
    library_dirs.append("/usr/local/lib")
elif sys.platform == "darwin":
    include_dirs.append("/usr/local/include/")
    library_dirs.append("/usr/local/lib")


versionstr = "%d.%d.%d" % get_version()

classifiers = """
Intended Audience :: Science/Research
License :: OSI Approved :: GNU General Public License v3 (GPLv3)
Operating System :: MacOS
Operating System :: POSIX
Operating System :: Unix
Programming Language :: C
Programming Language :: Cython
Programming Language :: Python
Programming Language :: Python :: 3
Topic :: Multimedia :: Sound/Audio
Topic :: Multimedia :: Sound/Audio :: Analysis
Topic :: Multimedia :: Sound/Audio :: Sound Synthesis
Topic :: Multimedia :: Sound/Audio :: Speech
Topic :: Scientific/Engineering
Topic :: Software Development :: Libraries :: Python Modules
"""

long_description = open("README.rst").read()

print(__name__)

setup(
    name = "pysdif3",
    python_requires=">=3.8",
    cmdclass={'build_ext': build_ext},
    ext_modules = [
        Extension(
            'pysdif._pysdif',
            # sources = sources + ['pysdif/_pysdif.pyx', 'pysdif/pysdif.pxd'],
            sources = sources + ['pysdif/_pysdif.c'],
            include_dirs = include_dirs + ['pysdif', numpy_include()],
            depends=sdif_headers,
            # libraries = ['sdif'],
            library_dirs = library_dirs,
            extra_compile_args = compile_args,
            extra_link_args = compile_args,
        )
    ],
    setup_requires = [
        'numpy>=1.10',
        'cython>=0.25'
    ],
    install_requires = [
        'numpy>=1.10',
        'cython>=0.25'
    ],
    packages = ['pysdif'],
    package_dir  = {'pysdif': 'pysdif'},
    package_data = {'pysdif': ['data/*']},
    scripts = ['bin/sdifinfo'],
    version  = versionstr,
    url = 'https://github.com/gesellkammer/pysdif',
    author = 'Eduardo Moguillansky',
    author_email = 'eduardo.moguillansy@gmail.com',
    long_description = long_description,
    # long_description_content_type="text/markdown",
    description = "Wrapper for the SDIF library for audio analysis",
    classifiers = [c for c in classifiers.split('\n') if c]
)
