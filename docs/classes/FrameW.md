# FrameW

## FrameW


Class to write frames to a SdifFile


```python

class FrameW()

```


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


## Methods

### \_\_init\_\_


Initialize self.  See help(type(self)) for accurate signature.


```python

def __init__(self, args, kwargs) -> None

```

----------

### add\_matrix


Add a matrix to this Frame


```python

def add_matrix(self, signature: str, data_array: numpy.array) -> None

```

----------

### write


Write the current frame to disk.


```python

def write(self) -> None

```


This function is called after add_matrix has been called (if there 
are any matrices in the current frame). The frame is written all at once. 


---------


## Attributes

**written**