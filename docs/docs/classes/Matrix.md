# Matrix

## 


```python

def (source: SdifFile) -> None

```


Matrix is a placeholder class to iterate through data while reading a SdifFile


In particular the default behaviour is that when you are given a Matrix, 
this is only valid until a new one is read.

See the methods `get_data` and `copy` for a better explanation of how to 
make the data in the Matrix persistent

### Example

```python
from pysdif import *
sdif = SdifFile("1trc.sdif")
for frame in sdif:
    print(f"Frame signature: {frame.signature}, time: {frame.time}")
    for matrix in frame:
        print(f"Matrix shape: {matrix.rows} x {matrix.cols}, "
              f"dtype={matrix.dtype}, signature: {matrix.signature}")
        print("Data", matrix.get_data())

```



**Args**

* **source** (`SdifFile`): The source sdiffile this matrix belongs to

**Attributes**

* **cols**

* **dtype**

* **numerical_signature**

* **rows**

* **signature**

* **status**


---------


**Methods**

## column\_names


```python

Matrix.column_names(self)

```


Returns a list of column names for the current matrix



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`list[str]`) Column names

----------

## get\_data


```python

Matrix.get_data(self, copy=True)

```


Read the data from the matrix as a numpy array


!!! note

    If copy is False, the data is not copied to the array. 
    The array is only a 'view' of this data and does not own it,
    so it is only valid until you read a new matrix. 

    If you want to keep the data, do get_data(copy=True) or call
    .copy() on the resulting numpy array 



**Args**

* **copy** (`bool`): if True, the returned data is a copy of the data read
    and will not be invalidated

**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`numpy.array`) The data as a numpy.array. If copy==False, this data is a view on the decoded data and will be invalidated when a new matrix is read

----------

## skip


```python

Matrix.skip(self)

```


Skip reading the data


This method can only be called if the data was not already read