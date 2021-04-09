
# SDIF for Python

* Author: Eduardo Moguillansky
* Contact: `eduardo.moguillansky@gmail.com`


This is a python wrapper to IRCAM's sdif library to read and write SDIF files.
It consists of a core written in Cython and some other utilities written in Python.

## Build

* Install the SDIF library at http://sourceforge.net/projects/sdif/files/sdif/

* `python3 setup.py install` 

* This software is released under the GPL v3 license.

## Introduction

Sdif files are used to store time-based analysis. A Sdif file consists of time-tagged frames, each frame consisting of one or more matrices. 

### Read a Sdif file, read only selected matrices
    
```python
    
from pysdif import *
sdif = SdifFile("path.sdif")
# get metadata
print(sdif.get_NVTs())
for frame in sdif:
    print(frame.time, frame.signature)
    for matrix in frame:
        if matrix.signature == b'1MAT':
            print(matrix.get_data())
```

### Write a Sdif file modifying a previous one

```python

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
```
