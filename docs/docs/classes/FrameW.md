# FrameW
## 


```python

def () -> None

```


Class to write frames to a SdifFile


A FrameW is not created directly but is returned by sdiffile.new_frame(...)
After creating a new frame, you add matrices via:

```python

framew.add_matrix(signature, numpy_array)

```

After finishing adding matrices, `.write` must be called:

```python
framew.write()
```

Alternatively you can do:

```python
with sdiffile.new_frame(sig, time) as frame:
    frame.add_matrix(matrix_sig, data1) 
    frame.add_matrix(matrix_sig, data2)
    ...
```

There is no need to call .write in this case


---------


**Summary**



| Property  | Description  |
| :-------- | :----------- |
| written | - |


| Method  | Description  |
| :------ | :----------- |
| [add_matrix](#add_matrix) | Add a matrix to this Frame |
| [write](#write) | Write the current frame to disk. |


---------


**Attributes**

* **written**


---------


**Methods**

## add\_matrix


```python

FrameW.add_matrix(self, str signature, ndarray data_array)

```


Add a matrix to this Frame


### Example

```python
with sdiffile.new_frame("1FTD", time) as frame:
    frame.add_matrix("1MRK", [segmentstart, segmentend, segmentation, label, periodmarker, transientmarker, transientid])
    ...
```



**Args**

* **signature** (`str`): the signature of the matrix
* **data_array** (`numpy.array`): the data of the matrix, a 2D array.

----------

## write


```python

FrameW.write(self)

```


Write the current frame to disk.


This function should be called after all matrices have been added
via add_matrix. It is not needed if the frame was created
as a context manager. After calling write, the frame is finalized
and no further matrices can be added


### Example

```python
new_frame = sdiffile.new_frame('1SIG', time_now)
new_frame.add_matrix(...)
# possibly add any other matrices to this frame
# When finished adding matrices, write needs to be called
new_frame.write()
```

No need to call `.write()` in this case:

```python
with sdiffile.new_frame(sig, time) as frame:
    frame.add_matrix(matrix_sig, data1)
    frame.add_matrix(matrix_sig, data2)
    ...
```
