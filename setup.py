#!/usr/bin/env python

"""
SDIF for python

This is a wrapper to IRCAM's SDIF C library, written mostly in Cython.

Needs Cython >= 0.15

It allows to read and write any kind of SDIF file, to define new
kinds of frames and matrices and to read and write metadata. 

The matrices read from a sdif file are exposed as numpy arrays.

It exposes both a low level and a high level interface.

The low level interface for reading and writing sdif files mirrors the 
sdif library quite transparently so that the example files and 
utilities using it can be directly translated with it. In particular
it does not create any intermediate objects, even the data of the matrices
is a numpy array mapped to the c array read from disk, so no allocation takes
place. Whereas this makes for very fast code, one has to take care to copy the
data if it will be used longer, since by the time a new matrix is read this
data is no longer valid. 

to read for ex. 1TRC format:

import pysdif

sdif_file = pysdif.SdifFile('filename.sdif')
sig1TRC = pysdif.str2signature("1TRC")
while not sdif_file.eof:
    sdif_file.read_frame_header()
    if sdif_file.frame_numerical_signature) == sig1TRC:
        print(sdif_file.time)
        for n in range(sdif_file.matrices_in_frame):
            sdif_file.read_matrix_header()
            if sdif_file.matrix_numerical_signature == sig1TRC:
                data = sdif_file.get_matrix_data(copy=True) # default is True 
                # data is now a numpy array
                # here is what happens under the hood: the SDIF library
                # reads a whole matrix and puts it in its internal buffer
                # This data is memcpy(ed) to create a numpy array
                # If you dont intend to keep this data and there are no
                # chances that a new matrix or frame will be read before 
                # you use this data for some calculation, then it is safe
                # to call sdif_file.get_matrix_data(copy=False)
                # in this case no memory is copied, the numpy array does not
                # own its memory and uses the internal buffer of the SDIF runtime
                print(data)
    
a more natural way:

from pysdif import SdifFile
sdif_file = SdifFile('filename.sdif')
for frame in sdif_file:
    if frame.signature == "1TRC":
        print(frame.time)
        for matrix in frame:
            if matrix.signature == "1TRC":
                print(matrix.get_data()) # data will be copied, use .get_data(copy=False) to avoid this
                
the frames and the matrices resulting from the iteration
are only guaranteed to be valid as long as no new frames and matrices are read

to write a SdifFile:

f = SdifFile('new_sdif.sdif', 'w')
# these are optional
#   add some metadata
f.add_NVT({
    'name' : 'my name',
    'date' : time.asctime(time.localtime())
})
# define new frame and matrix types
f.add_frame_type('1NEW', '1ABC NewMatrix, 1FQ0 New1FQ0')
f.add_matrix_type('1ABC', 'Column1, Column2')
# now you can begin adding frames
frame = f.new_frame('1NEW', time_now)
frame.add_matrix('1ABC', array([
    [0,     1.2],
    [3.5,   8.13],
    ...
    ]))
frame.write()

# say we just want to take the data from an existing
# sdiffile, modify it and write it back
in_sdif = SdifFile("existing-file.sdif")
out_sdif = SdifFile("outfile.sdif", "w")
out_sdif.clone_definitions(in_sdif)
for in_frame in in_sdif:
    if in_frame.signature == "1NEW":
        new_frame = out_sdif.new_frame("1NEW", in_frame.time)
        # we know there is only one matrix and we dont need to keep the data
        in_data = in_frame.get_matrix_data(copy=False) 
        # multiply it
        in_data[:,1] *= 0.5
        # add it to the stream
        new_frame.add_matrix('1ABC', in_data)
        # only one matrix, so write the frame.
        new_frame.write()
        # along this operation, only the memory used to allocate the original 
        # matrix was used, the rest of the operations is performed in place
        # This is only safe where only one thread has access to 
        # the sdif entity at once and data is not kept longer than the time
        # read it, transform it and rewrite it. 

there are also many utility functions under pysdif.sdiftools

see release notes and changes at http://github.com/gesellkammer/pysdif
"""

"""
GPL 

This file is part of pysdif

pysdif is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Foobar is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
"""


import os
import sys

from numpy.distutils.core import setup, Extension
from setuphelp import info_factory, NotFoundError

f = open('version.cfg')
PYSDIF_VERSION = f.readline().strip()

def is_valid_version(s):
    def is_valid_int(s):
        try:
            int(s)
        except ValueError:
            return False
        return True
    digits = s.split('.')
    o = len(digits) == 3
    o = all(is_valid_int(digit) for digit in digits) and o
    return o

assert is_valid_version(PYSDIF_VERSION)
print("pysdif version = ", PYSDIF_VERSION)

SDIF_MAJ_VERSION = 1

url      = 'http://github.com/gesellkammer/pysdif'
download = ''

descr    = __doc__.split('\n')[1:-1]; del descr[1:3]

classifiers = """
Intended Audience :: Science/Research
License :: OSI Approved :: GPL License
Operating System :: MacOS
Operating System :: POSIX
Operating System :: Unix
Programming Language :: C
Programming Language :: Cython
Programming Language :: Python
Programming Language :: Python :: 2
Topic :: Multimedia
Topic :: Multimedia :: Sound/Audio
Topic :: Multimedia :: Sound/Audio :: Analysis
Topic :: Multimedia :: Sound/Audio :: Sound Synthesis
Topic :: Multimedia :: Sound/Audio :: Speech
Topic :: Scientific/Engineering
Topic :: Software Development :: Libraries :: Python Modules
"""

keywords = """
scientific computing
music
sound analysis
SDIF
IRCAM
"""

platforms = """
Linux
Mac OS X
"""


metadata = {
    'name'             : 'pysdif',
    'version'          : PYSDIF_VERSION,
    'description'      : descr.pop(0),
    'long_description' : '\n'.join(descr),
    'url'              : url,
    'download_url'     : download, 
    'author'           : '',
    'author_email'     : '',
    'maintainer'       : '',
    'maintainer_email' : '',
    'classifiers'      : [c for c in classifiers.split('\n') if c],
    'keywords'         : [k for k in keywords.split('\n')    if k],
    'platforms'        : [p for p in platforms.split('\n')   if p],
    }



def configuration(parent_package='',top_path=None):
    from numpy.distutils.misc_util import Configuration
    confgr = Configuration('pysdif',parent_package,top_path)

    sf_info = info_factory('sdif', ['sdif'], ['sdif.h'])()
    try:
        sf_config = sf_info.get_info(2)
    except NotFoundError:
        raise NotFoundError("""\
sdif library not found.""")

    confgr.add_extension('_pysdif', ['_pysdif.c'], extra_info=sf_config)

    return confgr

if __name__ == "__main__":
    from sdif_setup import cython_setup
    cython_setup()
    from numpy.distutils.core import setup as numpy_setup
    config = configuration(top_path='').todict()
    config.update(metadata)
    numpy_setup(**config)
