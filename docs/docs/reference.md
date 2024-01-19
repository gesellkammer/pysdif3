# Reference


----------


## Classes

* [SdifFile](classes/SdifFile.md)
* [FrameR](classes/FrameR.md)
* [Matrix](classes/Matrix.md)
* [FrameW](classes/FrameW.md)


----------


## Functions

## predefined\_frametypes


```python

predefined_frametypes()

```


Returns a dict of predefined sdif frame types



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`dict[str: list[str]]`) A dict (framesig: components)

----------

## predefined\_matrixtypes


```python

predefined_matrixtypes()

```


Returns a list of predefined sdif matrix types



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`dict[str, list[str]`) A dict (matrisig: column_names)

----------

## sdif\_init


```python

sdif_init(str sdiftypes_path='')

```


Initialize the sdif library


This function is called automatically whenever an instance of
SdifFile is created. Calling this function explicitely only has an
effect if done previous to any usage of the `pysdif` library, to 
point the library to a `SdifTypes.STYP` file. This file is used
by the underlying code as a library for known SDIF frames and matrix
definitions. 

If called without arguments, the default paths will be searched. If an empty 
string is given, no `SdifTypes.STYP` will be used



**Args**

* **sdiftypes_path** (`str`): The path to `SdifTypes.STYP`, or empty to search
    in default paths (*default*: ``)

**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`bool`) True if the library was initialized, False if it was already initialized. In such a case, the path passed will not have any effect

----------

## signature2str


```python

signature2str(int sig)

```


Converts a numeric signature into a byte string signature



**Args**

* **sig** (`int`): Numeric signature

**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`bytes`) The byte string signature corresponding to the numeric signature

----------

## str2signature


```python

str2signature(s)

```


Converts a 4-byte string signature into a numeric signature



**Args**

* **s** (`bytes | str`): a string of 4 characters

**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`int`) The numeric signature corresponding to the string signature