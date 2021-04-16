# SdifFile

## SdifFile


This is a wrapper around a SdifFileT c-struct (`sdif.h`)


```python

class SdifFile(filename: str, mode: str)

```


It enables to read and write a SDIF file of any form.
It provides **two interfaces**: a **low-level interface**, which
reflects the original implementation and requires that the 
user is acquainted with the internal structure of a SDIF file; and
a **high-level interface** which takes care of most of the book-keeping.

```python

SdifFile(filename: str, mode="r")

```


### Example 1: read a sdiffile 

** High-Level Interface **

```python

s = SdifFile("mysdif.sdif")
for frame in s:
    print(frame.time)
    for matrix in frame:
        numpyarray = matrix.get_data()
        print(numpyarray)
```

** Low-Level Interface **

```python
s = SdifFile("mysdif.sdif")
while True:
    s.frame_read_header()
    if s.eof:
        break
    print(s.frame_time())
    for idx in range(s.frame_num_matrix()):
        print(s.matrix_read_data())
```

### Example 2: write a sdiffile

```python

insdif = SdifFile("mysdif.sdif")
outsdif = SdifFile("outsdif.sdif", "w").clone_definitions(insdif)
for inframe in insdif:
    if inframe.signature != b'1SIG':
        continue
    with outsdif.new_frame(inframe.signature, inframe.time) as outframe:
        for m in inframe:
            outframe.add_matrix(m.signature, m.get_data())
outsdif.close()

```



**Args**

* **filename** (`str`): path to a sdif file
* **mode** (`str`): "r" = read, "w" = write, "rw" = read+write


---------


## Methods

### \_\_init\_\_


```python

def __init__(filename: str, mode: str) -> None

```



**Args**

* **filename** (`str`): the sdif file to open
* **mode** (`str`): r=read, w=write

----------

### add\_NVT


The NVT (Name Value Table) is a place to put metadata about the file.


```python

def add_NVT(self, d: dict) -> None

```


The NVT is a hash table (key: value) where both key and value are a bytes 
string.

#### Example

```python

import pysdif
f = pysdif.SdifFile("foo.sdif", "w")
f.add_NVT({'Author': 'pysdif3', 'SampleRate': '44100'})

```

----------

### add\_frame\_type


Adds a frame type to this sdif.


```python

def add_frame_type(self, signature: str, components: list[str]) -> None

```


A frame is defined by a signature and a list of possible matrices. 

A frame type defines which matrix types are allowed in it.
The matrices mentioned in the frame type MUST be defined
via `add_matrix_type`.

!!! note

    A frame can have multiple matrices in it, so when defining
    a frame-type, you need to pass a sequence of possible
    matrices.


#### Example

Add a new frame type 1NEW, with a 1NEW matrix type

```python

sdiffile.add_frame_type("1NEW", ["1NEW NewMatrix"])
sdiffile.add_matrix_type("1NEW", "Column1, Column2")

```

**See also**: `add_matrix_type`

----------

### add\_matrix\_type


Adds a matrix type to this Sdif


```python

def add_matrix_type(self, signature: str, column_names: list[str]) -> None

```


There are two possible formats for the column names:

* `sdiff.add_matrix_type("1ABC", "Column1, Column2")` or
* `sdiff.add_matrix_type("1ABC", ["Column1", "Column2"])`

See also: add_frame_type

----------

### add\_predefined\_frametype


Add a predefined frame type with corresponding matrix definitions


```python

def add_predefined_frametype(self, signature: str) -> None

```


This type must be already defined globally. If not already defined, add 
your definitions via `frametypes_set` and `matrixtypes_set`

----------

### add\_streamID


This method is only there for completion.


```python

def add_streamID(self, numid: int, source: str, treeway: str) -> Any

```


It seems to be only used in old sdif types

----------

### clone\_NVTs


Clone the NVT (name:value table) from source (an open SdifFile)


```python

def clone_NVTs(self, source: SdifFile) -> None

```


!!! note

    Only for writing mode. If you do not plan to midify the type 
    definitions included in the source file, it's better to call 
    `clone_definitions`, which clones everything but the data
    (see example)

#### Example

```python    
source_sdif = SdifFile("in.sdif")
new_sdif = SdifFile("out.sdif", "w")
new_sdif.clone_definitions(source_sdif)
for frame in old_sdif:
    new_frame = new_sdif.new_frame(frame.signature, frame.time)
    # ... etc ...

```

----------

### clone\_definitions


Only for writing mode - Clone both NVT(s), frame and matrix definitions


```python

def clone_definitions(self, source: SdifFile) -> None

```


Clone NVT, frame and matrix definitions from source, so after calling 
this function you can start creating frames

#### Example

```python

infile = SdifFile("myfile.sdif")
outfile = SdifFile("outfile.sdif", "w")
outfile.clone_definitions(infile)
for inframe in infile:
    with outfile.new_frame(inframe.signature) as outframe:
        matrixsig, data = inframe.get_one_matrix_data()
        outframe.add_matrix(matrixsig, data)

```

----------

### clone\_frames


Clone all the frames in source which are included in


```python

def clone_frames(self, source: SdifFile, signatures_to_clone: list[str]) -> Any

```


!!! note

    the use case for this function is when you want to
    modify some of the metadata but leave the data itself
    unmodified

----------

### clone\_type\_definitions


Clone the frame and matrix type definitions of source_sdiffile


```python

def clone_type_definitions(self, source: SdifFile) -> None

```


!!! note

    Only for writing mode. This function must be called before 
    any frame has been written

----------

### close


Close this SdifFile


```python

def close(self) -> None

```

----------

### curr\_frame\_available


SdifFile.curr_frame_available(self)


```python

def curr_frame_available(self) -> None

```

----------

### curr\_frame\_is\_selected


Return whether the current frame is selected.


```python

def curr_frame_is_selected(self) -> bool

```


Can only be called after reading the frame header. 

!!! note

    Raises `NoFrame` if no header was read



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`bool`) True if current frame is selected

----------

### curr\_matrix\_available


SdifFile.curr_matrix_available(self)


```python

def curr_matrix_available(self) -> None

```

----------

### curr\_matrix\_datatype


Returns the datatype code (an int) or 0 if go current matrix


```python

def curr_matrix_datatype(self) -> int

```



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`int`) the datatype of the current matrix as an int code

----------

### curr\_matrix\_is\_selected


Return whether the current matrix is selected.


```python

def curr_matrix_is_selected(self) -> bool

```


!!! note

    Raises `NoMatrix` if the matrix header was not read.



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`bool`) True if current matrix is selected

----------

### curr\_matrix\_signature


Get the string signature of the current matrix, or None if no current matrix


```python

def curr_matrix_signature(self) -> str | None

```



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`str | None`) The 4-byte string signature of the current matrix, or None if no matrix

----------

### curr\_matrix\_size


Returns the number of rows and number of columns in the current matrix


```python

def curr_matrix_size(self) -> tuple[int, int]

```


This method can be called after reading the matrix header. It does 
not read the data itself

!!! note 

    raises `NoMatrix` if the matrix header has not been read



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`tuple[int, int]`) A tuple (num_rows, num_columns)

----------

### curr\_signature


**Low-level interface** - Return the current frame's numerical signature


```python

def curr_signature(self) -> int

```



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`int`) The current numerical signature

----------

### frame\_id


Get the id of the current frame, or -1 if no current frame


```python

def frame_id(self) -> int

```



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`int`) The id of the current frame

----------

### frame\_num\_matrix


Get the number of matrices in current frame.


```python

def frame_num_matrix(self) -> int

```



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`int`) The number of matrices in the current frame, or -1 if no current frame

----------

### frame\_numerical\_signature


Return the num. signature of current frame, or -1 if no current frame


```python

def frame_numerical_signature(self) -> int

```



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`int`) The numerical signature of the current frame, or -1 if no current frame

----------

### frame\_read\_header


** Low level interface ** - Read the frame header.


```python

def frame_read_header(self) -> int

```


Returns the number of bytes read. If it reaches the
end of file, self.eof is 1 and this function returns 0

Raises SdifOrderError if the header or some of the data
were already read from this frame.



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`int`) The bytes read

----------

### frame\_signature


Return the str. signature of the current frame, or None if no current frame


```python

def frame_signature(self) -> str|None

```



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`str|None`) The current frame signature (4-char string)

----------

### frame\_skip\_data


**Low level interface** - Skip frame and all its matrices


```python

def frame_skip_data(self) -> None

```

----------

### frame\_skip\_rest


Skipts the rest of the frame, so that a new frame can be read.


```python

def frame_skip_rest(self) -> bool

```



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`bool`) True if anything was skipped, False otherwise

----------

### frame\_time


Get the time of the current frame, or -1 if no current frame


```python

def frame_time(self) -> float

```



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`float`) The time of the current frame

----------

### frame\_types\_to\_string


returns a string with all frame types


```python

def frame_types_to_string(self) -> None

```

----------

### get\_NVTs


Return a list with all defined NameValueTables


```python

def get_NVTs(self) -> list[dict[str, str]]

```


Each NVT is converted to a python dict



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`list[dict[str, str]]`) A list of NVTs, where each NVT is a dictionary with string keys and string values

----------

### get\_frame\_types


Returns a list of Frame Type Definitions (1FTD)


```python

def get_frame_types(self) -> None

```


Each FrameTypeDefinition is a FrameTypeDefinition(signature:bytes, components:list[Component])
(a Component has the attributes signature:bytes, name:bytes, num:int)

----------

### get\_matrix\_types


Get a list of matrix type definitions (1MTD)


```python

def get_matrix_types(self) -> list[str]

```



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`list[str]`) A list of matrix types, where each item is a MatrixTypeDefinition

----------

### get\_num\_NVTs


SdifFile.get_num_NVTs(self)


```python

def get_num_NVTs(self) -> None

```

----------

### get\_stream\_IDs


SdifFile.get_stream_IDs(self)


```python

def get_stream_IDs(self) -> None

```

----------

### last\_error


Returns (error_tag, error_level) or None if there is no last error


```python

def last_error(self) -> None

```

----------

### matrix\_read\_data


Read the data of the current matrix as a numpy array


```python

def matrix_read_data(self, copy) -> None

```


If the matrix-header was not read, it is read here
The matrix signature cam be retrieved via sdiffile.curr_matrix_signature()

If data was already read, it is wrapped as a numpy array and returned.

If copy is False, the array is referencing the data read and 
is only valid as long as no new matrix is read.
To keep the array for longer, use `copy=True` or call `.copy()` on the array:

```python
tmparray = sdiffile.matrix_read_data()
myarray = tmparray.copy() 
```

----------

### matrix\_read\_header


**Low level interface** - Read the matrix header


```python

def matrix_read_header(self) -> int

```


Reads the matrix header (signature, number of rows and columns, etc.)
Return the number of bytes read or 0 if no more matrices,
or if eof is reached

!!! note

    Raises `NoFrame` if no current frame



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`int`) The bytes read

----------

### matrix\_skip


Low level Interface. Skip the matrix altogether.


```python

def matrix_skip(self) -> None

```


!!! note

    this CAN be called after having read the header, in which
    case only the data is skipped, otherwise the matrix is
    skipped altogether

----------

### matrix\_skip\_data


**Low-level Interface** - Skip the matrix data without reading it.


```python

def matrix_skip_data(self) -> int

```


!!! note

    Raises NoFrame if no current frame



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`int`) The bytes read.

----------

### matrix\_types\_to\_string


Returns a string with all matrix types


```python

def matrix_types_to_string(self) -> str

```



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`str`) A string with all matrix types

----------

### new\_frame


Create a new frame with given signature and at given time


```python

def new_frame(self, signature: str, time: float, streamID: int) -> FrameW

```


!!! note "Stream/Frame/Matrix"

    A SDIF file can have 1 or more streams. Each stream has multiple
    frames. A frame is a collection of matrixes at a given time.

#### Example

```python
new_frame = sdiffile.new_frame('1SIG', time_now)
new_frame.add_matrix(...)
new_frame.write()
```

if you know that you will write only one matrix, you can call:

```python

sdiffile.new_frame_one_matrix(frame_sig, time_now, matrix_sig, data)

```

This will do the same as the three method calls above



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`FrameW`) A FrameW, used to write a (see example)

----------

### new\_frame\_one\_matrix


Create a frame containing only one matrix and write it


```python

def new_frame_one_matrix(self, frame_sig: str, time: float, matrix_sig: str, 
                         matrixdata: numpy.array, streamID: int) -> Any

```


This method creates the frame, creates a new matrix
in the frame and writes it to disk, all at once

!!! note

    use this method when you want to create a frame which
    contains only one matrix, like a 1TRC frame. It is more efficient
    than calling new_frame, add_matrix, write (see method 'new_frame')

----------

### next\_frame


Read the next frame, returns a Frame or None if no more frames left.


```python

def next_frame(self) -> Frame | None

```


#### Example

```python

sdif = SdifFile("mysdif.sdif")

while True:
    frame = sdif.next_frame()
    if frame is None: break
    print(frame.time)

```

This is the same as:

```python
for frame in sdif:
    print(frame.time)
```



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`Frame | None`) Returns the next Frame, or None if no more frames

----------

### next\_matrix


Read the next matrix header and return a Matrix with its data **still not read**.


```python

def next_matrix(self) -> Matrix|None

```


If the previous matrix was not read fully, its data is skipped. This is the
same as calling `next(frame)`



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`Matrix|None`) The next Matrix or None if no more matrices available

----------

### print\_NVT


**Low-Level Interface**


```python

def print_NVT(self) -> None

```

----------

### print\_all\_ascii\_chunks


**Low-Level Interface**


```python

def print_all_ascii_chunks(self) -> None

```

----------

### print\_all\_stream\_ID


**Low-Level Interface**


```python

def print_all_stream_ID(self) -> None

```

----------

### print\_all\_types


**Low-Level Interface**


```python

def print_all_types(self) -> None

```

----------

### print\_frame\_header


**Low-Level Interface**


```python

def print_frame_header(self) -> None

```

----------

### print\_general\_header


**Low-Level Interface**


```python

def print_general_header(self) -> None

```

----------

### print\_matrix\_header


**Low-Level Interface**


```python

def print_matrix_header(self) -> None

```

----------

### print\_one\_row


**Low-Level Interface**


```python

def print_one_row(self) -> None

```

----------

### rewind


Rewind the SdifFile.


```python

def rewind(self) -> None

```


After this function is called, the file is in its starting frame 
(as if the file had been just open)

----------

### status


Returns a tuple (curr_frame_status, curr_matrix_index, curr_matrix_status)


```python

def status(self) -> None

```

----------

### write\_all\_ascii\_chunks


**Low-level Interface**


```python

def write_all_ascii_chunks(self) -> None

```


Once the NVTs and matrix and frame definitions have been added to the SdifFile,
this methods writes them all together to disk and the SdifFile is ready to accept
new frames.


---------


## Attributes

**eof**

**frame_pos**

**is_seekable**: (bool) Is this SdifFile seekable?

**mode**

**name**

**numerical_signature**: (int) Current signature as numerical signature

**pos**: The last position read

**prev_time**: (float)

**signature**: (str) Current signature as 4-byte string