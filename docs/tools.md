## Tools

### add\_type\_definitions


Writes predefined types explicitely


```python

def add_type_definitions(infile: str, outfile: str, metadata: Dict[str, 
                         str] = None) -> None

```


Will add the type definitions to the file so that it can be read without a 
modified `SdifTypes.STYP` 



**Args**

* **infile** (`str`): the path to a .sdif file
* **outfile** (`str`): it can be the same as infile
* **metadata** (`Dict[str, str]`): a dictionary with metadata to be added to the
    metadata already present (default: None)

----------

### as\_sdiffile


```python

def as_sdiffile(s: U[str, SdifFile]) -> SdifFile

```


NB: the original sdif or SdifFile is not modified



**Args**

* **s** (`U[str, SdifFile]`): a path to a sdif or a SdifFile, in which case a
    new SdifFile        is opened with the original path.

----------

### check\_matrix\_exists


```python

def check_matrix_exists(sdiffile: str, frame_sig: str, matrix_sig: str) -> bool

```



**Args**

* **sdiffile** (`str`):
* **frame_sig** (`str`):
* **matrix_sig** (`str`):

----------

### convert\_1TRC\_to\_RBEP


Create a RBEP clone from a 1TRC file.


```python

def convert_1TRC_to_RBEP(sdiffile: U[str, SdifFile], metadata: dict = None
                         ) -> None

```



**Args**

* **sdiffile** (`U[str, SdifFile]`): a SdifFile or the path to a sdif file
* **metadata** (`dict`): any metadata to add to the RBEP file (default: None)

----------

### framestatus2str


framestatus2str(int status)


```python

def framestatus2str(status) -> None

```



**Args**

* **status**:

----------

### frametypes\_used


Find all the frametypes used in this sdiffile


```python

def frametypes_used(sdiffile: str) -> Set[str]

```



**Args**

* **sdiffile** (`str`): the path to a sdif file

**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`Set[str]`) the set of frame signatures present in the given file

----------

### matrixstatus2str


Return a string identifier for a matrix status.


```python

def matrixstatus2str(status: int) -> str

```



**Args**

* **status** (`int`): The matrix status

**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`str`) A corresponding string identifier

----------

### matrixtypes\_for\_predefined\_frametype


Given a predefined frametype, return a list of matrix definitions


```python

def matrixtypes_for_predefined_frametype(sig: str) -> Dict[str, list[str]]

```


included in the frame definition



**Args**

* **sig** (`str`): the signature, a 4-byte string

**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`Dict[str, List[str]]`) the matrix definitions possible within the given frame

----------

### predefined\_frametypes


Returns a dict of predefined sdif frame types


```python

def predefined_frametypes() -> dict[str: list[str]]

```



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`dict[str: list[str]]`) A dict (framesig: components)

----------

### predefined\_matrixtypes


Returns a list of predefined sdif matrix types


```python

def predefined_matrixtypes() -> dict[str, list[str]

```



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`dict[str, list[str]`) A dict (matrisig: column_names)

----------

### read\_sdiftypes


Retrieves predefined types definitions parsed from SdifTypes.STYP


```python

def read_sdiftypes() -> Any

```



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;a tuple (frametypes, matrixtypes)

----------

### repair\_RBEP


Add the type definitions to a RBEP file


```python

def repair_RBEP(sdiffile: str, metadata: Dict[str, str] = None) -> None

```


Some libraries (loris, for example), use RBEP frame types/matrix types 
without including the definition in the sdif file. This function
clones a given sdif file and ensures that it has all needed 
definitions



**Args**

* **sdiffile** (`str`):
* **metadata** (`Dict[str, str]`):  (default: None)

----------

### sdif\_cleanup


sdif_cleanup()


```python

def sdif_cleanup() -> None

```

----------

### sdif\_init


Initialize the sdif library


```python

def sdif_init(sdiftypes_path: str = None) -> bool

```


This function is called automatically whenever an instance of
SdifFile is created. Calling this function explicitely only has an
effect if done previous to any usage of the `pysdif` library, to 
point the library to a `SdifTypes.STYP` file. This file is used
by the underlying code as a library for known SDIF frames and matrix
definitions. 

If called without arguments, the default paths will be searched. If an empty 
string is given, no `SdifTypes.STYP` will be used



**Args**

* **sdiftypes_path** (`str`): The path to `SdifTypes.STYP`, or None to search
    in default paths (default: None)

**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`bool`) True if the library was initialized, False if it was already initialized. In such a case, the path passed will not have any effect

----------

### signature2str


Converts a numeric signature into a string signature


```python

def signature2str(sig: int) -> str

```



**Args**

* **sig** (`int`): Numeric signature

**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`str`) The string signature corresponding to the numeric signature

----------

### str2signature


Converts a 4-byte string signature into a numeric signature


```python

def str2signature(s: str) -> int

```



**Args**

* **s** (`str`): a string of 4 characters

**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`int`) The numeric signature corresponding to the string signature

----------

### time\_range


Returns the first and last times of all frames in this sdiffile


```python

def time_range(sdiffile: str) -> tuple[float, float]

```



**Args**

* **sdiffile** (`str`):

----------

### update\_metadata


Update the metadata of the given sdiffile.


```python

def update_metadata(sdiffile: str, metadata: Dict[str, str], 
                    outfile: str = None) -> None

```


Any key already present in the original file will be updated with the 
new value, new keys will be added. Other key: value pairs will be left 
untouched.

!!! note 

    Only the first NVT is taken into consideration. Other NVTs, if present,
    are left untouched.



**Args**

* **sdiffile** (`str`):
* **metadata** (`Dict[str, str]`):
* **outfile** (`str`):  (default: None)

----------

### write\_metadata


Add metadata to a sdif file


```python

def write_metadata(sdif_filename: str, metadata: Dict[str, str], 
                   outfile: str = None) -> None

```


Produce a copy of the sdif file with the metadata given. If there was any 
metadata already defined in the source file, it will be overwritten.
If no outfile is given, the sdif file is modified in place



**Args**

* **sdif_filename** (`str`): the filename of the source sdif file
* **metadata** (`Dict[str, str]`):
* **outfile** (`str`): the outfile to generate, or None to modify the source
    file in place (default: None)