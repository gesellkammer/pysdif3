# FrameR
## 


```python

def (source: SdifFile) -> None

```


FrameR is an iterator over the matrices of a frame.


Access the matrices by iterating on the frame, or calling 
next(frame). 

!!! note

    A `FrameR` is not created by a user, it is yielded by
    a SdifFile on iteration.

### Example

```python

import pysdif
sdiffile = pysdif.SdifFile("1trc.sdif")
# Iterating over a SdifFile open for reading yields FrameR
for frame in sdiffile:
    print(frame.signature, frame.time)
    # iterating over a frame yields the matrices present in the frame
    for matrix in frame:
        print(matrix.signature, matrix.get_data())

```



**Args**

* **source** (`SdifFile`): the sidffile this frame belongs to


---------


**Summary**



| Property  | Description  |
| :-------- | :----------- |
| id | (int) The id of this frame |
| matrix_idx | The index of the current matrix |
| num_matrices | (int) The number of matrices in this frame |
| numerical_signature | - |
| signature | The string signature of this frame, as bytes |
| size | (int) The size of this frame in bytes |
| time | (float) The time of this frame |


| Method  | Description  |
| :------ | :----------- |
| [get_matrix](#get_matrix) | Reads the next matrix entirely, returns (matrixsig, data) |


---------


**Attributes**

* **id**: (int) The id of this frame
* **matrix_idx**: The index of the current matrix
* **num_matrices**: (int) The number of matrices in this frame
* **numerical_signature**
* **signature**: The string signature of this frame, as bytes
* **size**: (int) The size of this frame in bytes
* **time**: (float) The time of this frame


---------


**Methods**

## get\_matrix


```python

FrameR.get_matrix(self, copy=True)

```


Reads the next matrix entirely, returns (matrixsig, data)


!!! note

    Raises `StopIteration` when there are no more matrices

### Example

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



**Args**

* **copy** (`bool`): return a copy of the data. If copy==False, then the data
    is only valid as long as no other matrix is read. This is          done to
    avoid allocating new memory for each new matrix         for the cases where
    the data is not preversed but transformed         within a streaming
    procees. (*default*: `True`)

**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`tuple[str, numpy.array]`) A tuple (string signature, matrix data)
