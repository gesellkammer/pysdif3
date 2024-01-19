# SdifFile
## 


```python

SdifFile(str filename, mode='r')

```


This is a wrapper around a SdifFileT c-struct (`sdif.h`)


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

### Example 2: clone a sdiffile with modifications

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


**Summary**



| Property  | Description  |
| :-------- | :----------- |
| eof | - |
| frame_pos | (int) The current frame position |
| is_seekable | (bool) Is this SdifFile seekable? |
| mode | (str) The mode in which this sdif file was opened ('r', 'w') |
| name | (str) The name of this sdif file |
| numerical_signature | (int) Current signature as numerical signature |
| pos | The last position read |
| prev_time | (float) The previous time |
| signature | (bytes) Current 4-char signature as bytes |


| Method  | Description  |
| :------ | :----------- |
| [__init__](#__init__) | - |
| [add_NVT](#add_NVT) | The NVT (Name Value Table) is a place to put metadata about the file. |
| [add_frame_type](#add_frame_type) | Adds a frame type to this sdif. |
| [add_matrix_type](#add_matrix_type) | Adds a matrix type to this Sdif |
| [add_predefined_frametype](#add_predefined_frametype) | Add a predefined frame type with corresponding matrix definitions |
| [add_streamID](#add_streamID) | This method is only there for completion. |
| [clone_NVTs](#clone_NVTs) | Clone the NVT (name:value table) from source (an open SdifFile) |
| [clone_definitions](#clone_definitions) | Only for writing mode - Clone both NVT(s), frame and matrix definitions |
| [clone_frames](#clone_frames) | Clone all the frames in source which are included in |
| [clone_type_definitions](#clone_type_definitions) | Clone the frame and matrix type definitions of source_sdiffile |
| [close](#close) | Close this SdifFile |
| [curr_frame_available](#curr_frame_available) | SdifFile.curr_frame_available(self) |
| [curr_frame_is_selected](#curr_frame_is_selected) | Return whether the current frame is selected. |
| [curr_matrix_available](#curr_matrix_available) | SdifFile.curr_matrix_available(self) |
| [curr_matrix_datatype](#curr_matrix_datatype) | Returns the datatype code (an int) or 0 if no current matrix |
| [curr_matrix_is_selected](#curr_matrix_is_selected) | Return whether the current matrix is selected. |
| [curr_matrix_signature](#curr_matrix_signature) | Get the string signature of the current matrix, or None if no current matrix |
| [curr_matrix_size](#curr_matrix_size) | The shape of the current matrix, as a tuple (rows, columns) |
| [curr_signature](#curr_signature) | **Low-level interface** - Return the current frame's numerical signature |
| [frame_id](#frame_id) | Get the id of the current frame, or -1 if no current frame |
| [frame_num_matrix](#frame_num_matrix) | Get the number of matrices in current frame. |
| [frame_numerical_signature](#frame_numerical_signature) | Return the num. signature of current frame, or -1 if no current frame |
| [frame_read_header](#frame_read_header) | Low level interface - Read the frame header. |
| [frame_signature](#frame_signature) | Return the str. signature of the current frame, or None if no current frame |
| [frame_skip_data](#frame_skip_data) | Low level interface - Skip frame and all its matrices |
| [frame_skip_rest](#frame_skip_rest) | Skipts the rest of the frame, so that a new frame can be read. |
| [frame_time](#frame_time) | Get the time of the current frame, or -1 if no current frame |
| [frame_types_to_string](#frame_types_to_string) | Returns a string with all frame types |
| [get_NVTs](#get_NVTs) | Return a list with all defined NameValueTables |
| [get_frame_types](#get_frame_types) | Returns a list of Frame Type Definitions (1FTD) |
| [get_matrix_types](#get_matrix_types) | Get a list of matrix type definitions (1MTD) |
| [get_num_NVTs](#get_num_NVTs) | Get the number of NameValueTables defined in this sdif |
| [get_stream_IDs](#get_stream_IDs) | SdifFile.get_stream_IDs(self) |
| [last_error](#last_error) | Returns (error_tag, error_level) or None if there is no last error |
| [matrix_read_data](#matrix_read_data) | Read the data of the current matrix as a numpy array |
| [matrix_read_header](#matrix_read_header) | Low level interface - Read the matrix header |
| [matrix_skip](#matrix_skip) | Low level Interface. Skip the matrix altogether. |
| [matrix_skip_data](#matrix_skip_data) | Low-level Interface - Skip the matrix data without reading it. |
| [matrix_types_to_string](#matrix_types_to_string) | Returns a string with all matrix types |
| [new_frame](#new_frame) | Create a new frame with given signature and at given time |
| [new_frame_one_matrix](#new_frame_one_matrix) | Create a frame containing only one matrix and write it |
| [next_frame](#next_frame) | Read the next frame, returns a Frame or None if no more frames left. |
| [next_matrix](#next_matrix) | Read the next matrix header and return a Matrix with its data **still not read**. |
| [print_NVT](#print_NVT) | Low-Level Interface - Print the name value table |
| [print_all_ascii_chunks](#print_all_ascii_chunks) | Low-Level Interface - print all text chunks |
| [print_all_stream_ID](#print_all_stream_ID) | Low-Level Interface - Print the ID of all streams |
| [print_all_types](#print_all_types) | Low-Level Interface - Print all types defined in this sdif file |
| [print_frame_header](#print_frame_header) | Low-Level Interface- Print the frame header |
| [print_general_header](#print_general_header) | Low-Level Interface - Print the general header |
| [print_matrix_header](#print_matrix_header) | Low-Level Interface - Print the matrix header |
| [print_one_row](#print_one_row) | Low-Level Interface - print one row of the current matrix |
| [rewind](#rewind) | Rewind the SdifFile. |
| [status](#status) | The status of this sdiffile |
| [write_all_ascii_chunks](#write_all_ascii_chunks) | **Low-level Interface** |


---------


**Attributes**

* **eof**
* **frame_pos**: (int) The current frame position
* **is_seekable**: (bool) Is this SdifFile seekable?
* **mode**: (str) The mode in which this sdif file was opened ('r', 'w')
* **name**: (str) The name of this sdif file
* **numerical_signature**: (int) Current signature as numerical signature
* **pos**: The last position read
* **prev_time**: (float) The previous time
* **signature**: (bytes) Current 4-char signature as bytes


---------


**Methods**

## \_\_init\_\_


```python

def __init__(filename: str, mode: str) -> None

```



**Args**

* **filename** (`str`): the sdif file to open
* **mode** (`str`): r=read, w=write

----------

## add\_NVT


```python

SdifFile.add_NVT(self, dict d)

```


The NVT (Name Value Table) is a place to put metadata about the file.


The NVT is a hash table (key: value) where both key and value are a bytes 
string.

### Example

```python

import pysdif
f = pysdif.SdifFile("foo.sdif", "w")
f.add_NVT({'Author': 'pysdif3', 'SampleRate': '44100'})

```



**Args**

* **d** (`dict`): A python dictionary which is translated to a NVT

----------

## add\_frame\_type


```python

SdifFile.add_frame_type(self, signature, list components)

```


Adds a frame type to this sdif.


A frame is defined by a signature and a list of possible matrices. 

A frame type defines which matrix types are allowed in it.
The matrices mentioned in the frame type MUST be defined
via `add_matrix_type`.

!!! note

    A frame can have multiple matrices in it, so when defining
    a frame-type, you need to pass a sequence of possible
    matrices.


### Example

Add a new frame type 1NEW, with a 1NEW matrix type

```python

sdiffile.add_frame_type("1NEW", ["1NEW NewMatrix"])
sdiffile.add_matrix_type("1NEW", "Column1, Column2")

```

**See also**: `add_matrix_type`



**Args**

* **signature** (`str`): A 4-char string
* **components** (`list[str]`): A list of components, where each component is a
    string         of the sort `"{Signature} {Name}"`, like `["1NEW NewMatrix",
    "1FQ0 New1FQ0"]`

----------

## add\_matrix\_type


```python

SdifFile.add_matrix_type(self, signature, column_names)

```


Adds a matrix type to this Sdif


There are two possible formats for the column names:

* `sdiff.add_matrix_type("1ABC", "Column1, Column2")` or
* `sdiff.add_matrix_type("1ABC", ["Column1", "Column2"])`

See also: add_frame_type



**Args**

* **signature** (`str`): The signature as 4-byte string
* **column_names** (`list[str]`): The names of the columns of this matrix

----------

## add\_predefined\_frametype


```python

SdifFile.add_predefined_frametype(self, signature)

```


Add a predefined frame type with corresponding matrix definitions


This type must be already defined globally. If not already defined, add 
your definitions via `frametypes_set` and `matrixtypes_set`



**Args**

* **signature** (`str`): the 4-char string signature

----------

## add\_streamID


```python

SdifFile.add_streamID(self, unsigned int numid, char *source, char *treeway)

```


This method is only there for completion.


It seems to be only used in old sdif types



**Args**

* **numid** (`int`): The numerical ID of the new stream
* **source** (`str`): ??
* **treeway** (`str`): ??

----------

## clone\_NVTs


```python

SdifFile.clone_NVTs(self, SdifFile source)

```


Clone the NVT (name:value table) from source (an open SdifFile)


!!! note

    Only for writing mode. If you do not plan to midify the type 
    definitions included in the source file, it's better to call 
    `clone_definitions`, which clones everything but the data
    (see example)

### Example

```python    
source_sdif = SdifFile("in.sdif")
new_sdif = SdifFile("out.sdif", "w")
new_sdif.clone_definitions(source_sdif)
for frame in old_sdif:
    new_frame = new_sdif.new_frame(frame.signature, frame.time)
    # ... etc ...

```



**Args**

* **source** (`SdifFile`): The source SdifFile to clone the NVTs from

----------

## clone\_definitions


```python

SdifFile.clone_definitions(self, SdifFile source)

```


Only for writing mode - Clone both NVT(s), frame and matrix definitions


Clone NVT, frame and matrix definitions from source, so after calling 
this function you can start creating frames

### Example

```python

infile = SdifFile("myfile.sdif")
outfile = SdifFile("outfile.sdif", "w")
outfile.clone_definitions(infile)
for inframe in infile:
    with outfile.new_frame(inframe.signature) as outframe:
        matrixsig, data = inframe.get_one_matrix_data()
        outframe.add_matrix(matrixsig, data)

```



**Args**

* **source** (`SdifFile`): The sdiffile to clone definitions from

----------

## clone\_frames


```python

SdifFile.clone_frames(self, SdifFile source, signatures_to_clone=None)

```


Clone all the frames in source which are included in


!!! note

    the use case for this function is when you want to
    modify some of the metadata but leave the data itself
    unmodified



**Args**

* **source** (`SdifFile`): The SdifFile to clone from
* **signatures_to_clone** (`list[str]`): A seq. of signature, or None to clone
    all (*default*: `None`)

----------

## clone\_type\_definitions


```python

SdifFile.clone_type_definitions(self, SdifFile source)

```


Clone the frame and matrix type definitions of source_sdiffile


!!! note

    Only for writing mode. This function must be called before 
    any frame has been written



**Args**

* **source** (`SdifFile`): The sourc file to clone type definitions from

----------

## close


```python

SdifFile.close(self)

```


Close this SdifFile


This is called when the object is distroyed, but it can be
called explicitely. It will do nothing if called after
the file has been already closed.

----------

## curr\_frame\_available


```python

def curr_frame_available(self) -> None

```


SdifFile.curr_frame_available(self)

----------

## curr\_frame\_is\_selected


```python

SdifFile.curr_frame_is_selected(self)

```


Return whether the current frame is selected.


Can only be called after reading the frame header. 

!!! note

    Raises `NoFrame` if no header was read



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`bool`) True if current frame is selected

----------

## curr\_matrix\_available


```python

def curr_matrix_available(self) -> None

```


SdifFile.curr_matrix_available(self)

----------

## curr\_matrix\_datatype


```python

SdifFile.curr_matrix_datatype(self)

```


Returns the datatype code (an int) or 0 if no current matrix



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`int`) the datatype of the current matrix as an int code

----------

## curr\_matrix\_is\_selected


```python

SdifFile.curr_matrix_is_selected(self)

```


Return whether the current matrix is selected.


!!! note

    Raises `NoMatrix` if the matrix header was not read.



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`bool`) True if current matrix is selected

----------

## curr\_matrix\_signature


```python

SdifFile.curr_matrix_signature(self)

```


Get the string signature of the current matrix, or None if no current matrix



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`bytes | None`) The 4-byte string signature of the current matrix, or None if no matrix

----------

## curr\_matrix\_size


```python

SdifFile.curr_matrix_size(self)

```


The shape of the current matrix, as a tuple (rows, columns)


This method can be called after reading the matrix header. It does 
not read the data itself

!!! note 

    raises `NoMatrix` if the matrix header has not been read



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`tuple[int, int]`) A tuple (num_rows, num_columns)

----------

## curr\_signature


```python

SdifFile.curr_signature(self)

```


**Low-level interface** - Return the current frame's numerical signature



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`int`) The current numerical signature

----------

## frame\_id


```python

SdifFile.frame_id(self)

```


Get the id of the current frame, or -1 if no current frame



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`int`) The id of the current frame

----------

## frame\_num\_matrix


```python

SdifFile.frame_num_matrix(self)

```


Get the number of matrices in current frame.



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`int`) The number of matrices in the current frame, or -1 if no current frame

----------

## frame\_numerical\_signature


```python

SdifFile.frame_numerical_signature(self)

```


Return the num. signature of current frame, or -1 if no current frame



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`int`) The numerical signature of the current frame, or -1 if no current frame

----------

## frame\_read\_header


```python

SdifFile.frame_read_header(self)

```


Low level interface - Read the frame header.


Returns the number of bytes read. If it reaches the
end of file, self.eof is 1 and this function returns 0

Raises SdifOrderError if the header or some of the data
were already read from this frame.



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`int`) The bytes read

----------

## frame\_signature


```python

SdifFile.frame_signature(self)

```


Return the str. signature of the current frame, or None if no current frame



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`str|None`) The current frame signature (4-char string)

----------

## frame\_skip\_data


```python

SdifFile.frame_skip_data(self)

```


Low level interface - Skip frame and all its matrices

----------

## frame\_skip\_rest


```python

SdifFile.frame_skip_rest(self)

```


Skipts the rest of the frame, so that a new frame can be read.



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`bool`) True if anything was skipped, False otherwise

----------

## frame\_time


```python

SdifFile.frame_time(self)

```


Get the time of the current frame, or -1 if no current frame



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`float`) The time of the current frame

----------

## frame\_types\_to\_string


```python

SdifFile.frame_types_to_string(self)

```


Returns a string with all frame types

----------

## get\_NVTs


```python

SdifFile.get_NVTs(self)

```


Return a list with all defined NameValueTables


Each NVT is converted to a python dict



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`list[dict[str, str]]`) A list of NVTs, where each NVT is a dictionary with string keys and string values

----------

## get\_frame\_types


```python

SdifFile.get_frame_types(self)

```


Returns a list of Frame Type Definitions (1FTD)


Each FrameTypeDefinition is a FrameTypeDefinition(signature:bytes, components:list[Component])
(a Component has the attributes signature:bytes, name:bytes, num:int)



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`list[FrameTypeDefinition]`) A list of FrameTypeDefinition

----------

## get\_matrix\_types


```python

SdifFile.get_matrix_types(self)

```


Get a list of matrix type definitions (1MTD)



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`list[str]`) A list of matrix types, where each item is a MatrixTypeDefinition

----------

## get\_num\_NVTs


```python

SdifFile.get_num_NVTs(self)

```


Get the number of NameValueTables defined in this sdif



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`int`) The number of nvts in this sdiffile

----------

## get\_stream\_IDs


```python

def get_stream_IDs(self) -> None

```


SdifFile.get_stream_IDs(self)

----------

## last\_error


```python

SdifFile.last_error(self)

```


Returns (error_tag, error_level) or None if there is no last error

----------

## matrix\_read\_data


```python

SdifFile.matrix_read_data(self, copy=False)

```


Read the data of the current matrix as a numpy array


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



**Args**

* **copy** (`bool`): if True, copy the matrix data. Otherwise, the data is only
    valid until the next matrix is read. (*default*: `False`)

**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;a numpy array representing the matrix

----------

## matrix\_read\_header


```python

SdifFile.matrix_read_header(self)

```


Low level interface - Read the matrix header


Reads the matrix header (signature, number of rows and columns, etc.)
Return the number of bytes read or 0 if no more matrices,
or if eof is reached

!!! note

    Raises `NoFrame` if no current frame



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`int`) The bytes read

----------

## matrix\_skip


```python

SdifFile.matrix_skip(self)

```


Low level Interface. Skip the matrix altogether.


!!! note

    this CAN be called after having read the header, in which
    case only the data is skipped, otherwise the matrix is
    skipped altogether

----------

## matrix\_skip\_data


```python

SdifFile.matrix_skip_data(self)

```


Low-level Interface - Skip the matrix data without reading it.


!!! note

    Raises NoFrame if no current frame



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`int`) The bytes read.

----------

## matrix\_types\_to\_string


```python

SdifFile.matrix_types_to_string(self)

```


Returns a string with all matrix types



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`str`) A string with all matrix types

----------

## new\_frame


```python

SdifFile.new_frame(self, signature, SdifFloat8 time, SdifUInt4 streamID=0)

```


Create a new frame with given signature and at given time


!!! note "Stream/Frame/Matrix"

    A SDIF file can have 1 or more streams. Each stream has multiple
    frames. A frame is a collection of matrixes at a given time.

### Example

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



**Args**

* **signature** (`str`): The signature of the new Frame
* **time** (`float`): The time of the new frame
* **streamID** (`int`): The ID of the stream (*default*: `0`)

**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`FrameW`) A FrameW, used to write a set of matrices (see example)

----------

## new\_frame\_one\_matrix


```python

SdifFile.new_frame_one_matrix(self, frame_sig, SdifFloat8 time, matrix_sig, ndarray matrixdata, SdifUInt4 streamID=0)

```


Create a frame containing only one matrix and write it


This method creates the frame, creates a new matrix
in the frame and writes it to disk, all at once

!!! note

    use this method when you want to create a frame which
    contains only one matrix, like a 1TRC frame. It is more efficient
    than calling new_frame, add_matrix, write (see method 'new_frame')



**Args**

* **frame_sig** (`str`): The frame signature
* **time** (`float`): The time of the frame
* **matrix_sig** (`str`): The matrix signature
* **matrixdata** (`numpy.array`): The data of the matrix, a 2D array
* **streamID** (`int`): The ID of the stream to add this frame/matrix to
    (*default*: `0`)

----------

## next\_frame


```python

SdifFile.next_frame(self)

```


Read the next frame, returns a Frame or None if no more frames left.


### Example

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

## next\_matrix


```python

SdifFile.next_matrix(self)

```


Read the next matrix header and return a Matrix with its data **still not read**.


If the previous matrix was not read fully, its data is skipped. This is the
same as calling `next(frame)`



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`Matrix|None`) The next Matrix or None if no more matrices available

----------

## print\_NVT


```python

SdifFile.print_NVT(self)

```


Low-Level Interface - Print the name value table

----------

## print\_all\_ascii\_chunks


```python

SdifFile.print_all_ascii_chunks(self)

```


Low-Level Interface - print all text chunks

----------

## print\_all\_stream\_ID


```python

SdifFile.print_all_stream_ID(self)

```


Low-Level Interface - Print the ID of all streams

----------

## print\_all\_types


```python

SdifFile.print_all_types(self)

```


Low-Level Interface - Print all types defined in this sdif file

----------

## print\_frame\_header


```python

SdifFile.print_frame_header(self)

```


Low-Level Interface- Print the frame header

----------

## print\_general\_header


```python

SdifFile.print_general_header(self)

```


Low-Level Interface - Print the general header

----------

## print\_matrix\_header


```python

SdifFile.print_matrix_header(self)

```


Low-Level Interface - Print the matrix header

----------

## print\_one\_row


```python

SdifFile.print_one_row(self)

```


Low-Level Interface - print one row of the current matrix

----------

## rewind


```python

SdifFile.rewind(self)

```


Rewind the SdifFile.


After this function is called, the file is in its starting frame 
(as if the file had been just open)

----------

## status


```python

SdifFile.status(self)

```


The status of this sdiffile



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`tuple[int, int, int]`) A tuple (curr_frame_status, curr_matrix_index, curr_matrix_status)

----------

## write\_all\_ascii\_chunks


```python

SdifFile.write_all_ascii_chunks(self)

```


**Low-level Interface**


Once the NVTs and matrix and frame definitions have been added to the SdifFile,
this methods writes them all together to disk and the SdifFile is ready to accept
new frames.
