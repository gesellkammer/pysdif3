# FrameR

## FrameR


FrameR is an iterator over the matrices of a frame.


```python

class FrameR(source: SdifFile)

```


Access the matrices by iterating on the frame, or calling 
next(frame). 

!!! note

    A `FrameR` is not created by a user, it is yielded by
    a SdifFile on iteration.

#### Example

```python

import pysdif
sdiffile = pysdif.SdifFile("1trc.sdif")
### Iterating over a SdifFile open for reading yields FrameR
for frame in sdiffile:
    print(frame.signature, frame.time)
    # iterating over a frame yields the matrices present in the frame
    for matrix in frame:
        print(matrix.signature, matrix.get_data())

```



**Args**

* **source** (`SdifFile`): the sidffile this frame belongs to


---------


## Methods
### \_\_init\_\_


Initialize self.  See help(type(self)) for accurate signature.


```python

def __init__(self, args, kwargs) -> None

```

----------

### get\_matrix


Reads the next matrix entirely, returns (matrixsig, data)


```python

def get_matrix(self, copy) -> tuple[str, numpy.array]

```


!!! note

    Raises `StopIteration` when there are no more matrices

#### Example

```python

frame = next(sdiffile)
while True:
    sig, data = frame.get_matrix()
    print(data)

```

This is the same as:

```python
frame = next(sdiffile)
for matrix in frame:
    print(matrix.get_data())
```



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`tuple[str, numpy.array]`) A tuple (string signature, matrix data)


---------


## Attributes

**id**: (int) The id of this frame

**matrix_idx**: The index of the current matrix

**num_matrices**: (int) The number of matrices in this frame

**numerical_signature**

**signature**: (str) The string signature of this frame

**size**: (int) The size of this frame in bytes

**time**: (float) The time of this frame