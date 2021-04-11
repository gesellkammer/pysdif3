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

include_dirs = []

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

long_description = """

# SDIF for Python

Author
    Eduardo Moguillansky
Contact
    `eduardo.moguillansky@gmail.com`


This is a python wrapper to IRCAM's sdif library to read and write SDIF files.
It consists of a core written in Cython and some other utilities written in Python.

.. node::

    This software is released under the GPL v3 license.

Installation
============


::

    pip install pysdif3

Build
-----

All external libraries are included with the package and compiled and installed::

.. code:: bash

    python setup.py install 


-----

Introduction
============

Sdif files are used to store time-based analysis. A Sdif file consists of time-tagged frames, each frame consisting of one or more matrices. 

Example 1
---------

Read a Sdif file, read only selected matrices
    
.. code-block:: python
    
    from pysdif import *
    sdif = SdifFile("path.sdif")
    # get metadata
    print(sdif.get_NVTs())
    for frame in sdif:
        print(frame.time, frame.signature)
        for matrix in frame:
            if matrix.signature == b'1MAT':
                print(matrix.get_data())


Example 2: Write a SDIF file based on another SDIF file
-------------------------------------------------------

.. code-block:: python

    from pysdif import *
    infile = SdifFile("source.sdif")
    outfile = SdifFile("out.sdif", "w").clone_definitions(infile)
    for inframe in infile:
        if inframe.signature != b'1TRC':
            continue
        with outfile.new_frame(inframe.signature, inframe.time) as outframe:
            for matrix in inframe:
                # 1TRC has columns index, freq, amp, phase
                data = matrix.get_data(copy=True)
                # modify frequency
                data[:,1] *= 2
                outframe.add_matrix(matrix.signature, data)
    outfile.close()


Example 3: Write a SDIF file from scratch
-----------------------------------------

.. code-block:: python


    from pysdif import *
    import numpy as np

    sdif = SdifFile("rbep.sdif", "w")

    # Add some metadata. This is optional
    sdif.add_NVT({'creator': 'pysdif3'})

    # Add any matrix definitions. In this case we add only one definition
    # This is a matrix named "RBEP" with 6 columns
    # Each row in this matrix represents a breakpoint within a frame
    # Index: partial index to which a breakpoint belongs
    # Frequency: the freq. of the breakpoint
    # Amplitude: the amplitude of the breakpoint
    # Phase: the phase
    # Bandwidth: the "noisyness" of the breakpoint
    # Offset: the time offset in relation to the frame time
    sdif.add_matrix_type("RBEP", "Index, Frequency, Amplitude, Phase, Bandwidth, Offset")

    # After all matrix types are defined we define the frames. A frame is defined
    # in terms of the matrices it accepts.
    # Here we define a frame named "RBEP" which takes only matrices of type "RBEP"
    sdif.add_frame_type("RBEP", ["RBEP ReassignedBandEnhancedPartials"])

    # Now we need to add the data. Since there is just one matrix per frame
    # in this sdif we can use the shortcut sdif.new_frame_one_matrix which 
    # creates a frame and adds a matrix all at once
    # The data is just fake data for the sake of an example
    data = np.array([
        [1, 440, 0.1, 0, 0, 0],
        [2, 1000, 0.2, 0, 0, 0], 
    ], dtype=float)
    sdif.new_frame_one_matrix(frame_sig="RBEP", time=0.5, matrix_sig="RBEP", data=data)

    # A second frame
    data = np.array([
        [1, 442, 0.1, 0, 0, 0],
        [2, 1100, 0.1, 0, 0, 0]
    ], dtype=float)
    sdif.new_frame_one_matrix(frame_sig="RBEP", time=0.6, matrix_sig="RBEP", data=data)

    sdif.close()


"""

setup(
    name = "pysdif3",
    python_requires=">=3.6",
    ext_modules = [
        Extension(
            'pysdif._pysdif',
            sources = ['pysdif/_pysdif.pyx', 'pysdif/pysdif.pxd'],
            include_dirs = include_dirs + ['pysdif', numpy_include()],
            libraries = ['sdif'],
            library_dirs = library_dirs,
            extra_compile_args = compile_args,
            extra_link_args = compile_args,
        )
    ],
    setup_requires = [
        'numpy>=1.8',
        'cython>=0.20'
    ],
    install_requires = [
        'numpy>=1.8',
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
    description = "Wrapper for the SDIF library for audio analysis",
    classifiers = [c for c in classifiers.split('\n') if c]
)
