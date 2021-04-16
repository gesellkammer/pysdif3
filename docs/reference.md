# Reference


----------


## Classes

* [SdifFile](classes/SdifFile.md)
* [FrameR](classes/FrameR.md)
* [Matrix](classes/Matrix.md)
* [FrameW](classes/FrameW.md)


----------


## Functions
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