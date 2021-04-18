SDIF for Python
===============

-  Author: Eduardo Moguillansky
-  Contact: ``eduardo.moguillansky@gmail.com``

This is a python wrapper to IRCAM’s sdif library
(http://sourceforge.net/projects/sdif/files/sdif/) to read and write
SDIF files. It consists of a core written in Cython and some other
utilities written in Python. The SDIF library is included in the package
and built together with the python wrapper.

**NB**: This software is released under the GPL v3 license.

--------------

Install
-------

.. code:: bash


   pip install pysdif3

--------------

Build from source
-----------------

.. code:: bash


   git clone https://github.com/gesellkammer/pysdif3
   cd pysdif3

   python3 setup.py install

--------------

Introduction
------------

Sdif files are used to store time-based analysis. A Sdif file consists
of time-tagged frames, each frame consisting of one or more matrices.

Read a Sdif file, read only selected matrices
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code:: python

       
   from pysdif import *
   sdif = SdifFile("path.sdif")
   # get metadata
   print(sdif.get_NVTs())
   for frame in sdif:
       print(frame.time, frame.signature)
       for matrix in frame:
           if matrix.signature == b'1MAT':
               print(matrix.get_data())

Write a Sdif file modifying a previous one
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code:: python


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

Write a SDIF file from scratch
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code:: python


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

--------------

Documentation
-------------

https://pysdif3.readthedocs.io/
