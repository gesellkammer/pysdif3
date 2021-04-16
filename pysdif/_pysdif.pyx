#cython: embedsignature=True
#cython: binding=True
"""
GPL 

This file is part of pysdif

pysdif is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Foobar is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
"""

from libc.stdio cimport *
from libc.stdlib cimport *

cdef extern from "string.h":
    ctypedef void* const_void_ptr "const void *"
    void *memcpy(void *s1, const_void_ptr s2, size_t n)
    void import_array()

import os.path
import platform
import numpy as np
cimport numpy as c_numpy
from numpy cimport ndarray, npy_intp
import logging
logger = logging.getLogger("pysdif")
logger.setLevel(logging.INFO)

cdef extern from "numpy/arrayobject.h":
    PyArray_SimpleNew(int nd, npy_intp *dims, int type_num)
    PyArray_SimpleNewFromData(int nd, npy_intp *dims, int type_num, void *data)


######################################
# Exceptions
######################################

class NoFrame(Exception): pass
class NoMatrix(Exception): pass
class SdifOrderError(Exception): pass


from pysdif cimport *
# from sdifh cimport *

DEF _SdifNVTStreamID = 0xfffffffd

# ----------------------------------------------------------------------------------

cdef int SDIF_CLOSED = 2
cdef int _g_sdif_initiated = 0

cdef dict FILEMODE_STR2MODE = {
    'r' : eReadFile,
    'w' : eWriteFile,
    'rw': eReadWriteFile,
    'wr': eReadWriteFile
}

cdef dict FILEMODE_MODE2STR = {
    eReadFile: 'r',
    eWriteFile: 'w',
    eReadWriteFile: 'rw'
}

cdef dict _SDIF_DATATYPES = {
    0x0301:"char",
    0x0004:"float32",
    0x0008:"float64",
    0x0101:"int8",
    0x0102:"int16",
    0x0104:"int32",
    0x0108:"int64",
    0x0201:"uint8",
    0x0202:"uint16",
    0x0204:"uint32",
    0x0208:"uint64",
    }

cdef dict _SDIF_TO_NUMPY_TYPENUM = {
    0x0301:c_numpy.NPY_BYTE,
    0x0004:c_numpy.NPY_FLOAT,
    0x0008:c_numpy.NPY_DOUBLE,
    0x0101:c_numpy.NPY_BYTE,
    0x0102:c_numpy.NPY_SHORT,
    0x0104:c_numpy.NPY_INT,
    0x0108:c_numpy.NPY_LONG,
    0x0201:c_numpy.NPY_UBYTE,
    0x0202:c_numpy.NPY_USHORT,
    0x0204:c_numpy.NPY_UINT,
    0x0208:c_numpy.NPY_ULONG
    }
    
cdef inline int dtype_sdif2numpy(int typenum):
    if   typenum == 0x0004: typenum = c_numpy.NPY_FLOAT
    elif typenum == 0x0301: typenum = c_numpy.NPY_BYTE
    elif typenum == 0x0008: typenum = c_numpy.NPY_DOUBLE
    elif typenum == 0x0104: typenum = c_numpy.NPY_INT
    elif typenum == 0x0101: typenum = c_numpy.NPY_BYTE
    elif typenum == 0x0102: typenum = c_numpy.NPY_SHORT
    elif typenum == 0x0108: typenum = c_numpy.NPY_LONG
    elif typenum == 0x0201: typenum = c_numpy.NPY_UBYTE
    elif typenum == 0x0202: typenum = c_numpy.NPY_USHORT
    elif typenum == 0x0204: typenum = c_numpy.NPY_UINT
    elif typenum == 0x0208: typenum = c_numpy.NPY_ULONG
    return typenum
    
cdef inline int dtype_numpy2sdif(int dtype):
    if   dtype == c_numpy.NPY_FLOAT : dtype = 0x0004
    elif dtype == c_numpy.NPY_BYTE  : dtype = 0x0301
    elif dtype == c_numpy.NPY_DOUBLE: dtype = 0x0008
    elif dtype == c_numpy.NPY_INT   : dtype = 0x0104  
    elif dtype == c_numpy.NPY_BYTE  : dtype = 0x0101  
    elif dtype == c_numpy.NPY_SHORT : dtype = 0x0102  
    elif dtype == c_numpy.NPY_LONG  : dtype = 0x0108  
    elif dtype == c_numpy.NPY_UBYTE : dtype = 0x0201  
    elif dtype == c_numpy.NPY_USHORT: dtype = 0x0202      
    elif dtype == c_numpy.NPY_UINT  : dtype = 0x0204  
    elif dtype == c_numpy.NPY_ULONG : dtype = 0x0208
    return dtype
    
cdef inline unsigned int str2sig (char *sig):
   return ((((<unsigned int>(sig[0])) & 0xff) << 24) | 
       (((<unsigned int>(sig[1])) & 0xff) << 16) | 
       (((<unsigned int>(sig[2])) & 0xff) << 8) | 
       ((<unsigned int>(sig[3])) & 0xff))
       
# def signature2str(SdifSignature signature):
#    return PyString_FromStringAndSize(SdifSignatureToString(signature), 4)

cdef inline bytes sig2str(SdifSignature signature):
    cdef char* c_str = SdifSignatureToString(signature)
    cdef bytes out = c_str[:4]
    return out


def signature2str(int sig):
    """
    Converts a numeric signature into a string signature

    Args:
        sig (int): Numeric signature

    Returns:
        (str) The string signature corresponding to the numeric signature
    """
    return sig2str(sig)
 

def str2signature(s):
    """
    Converts a 4-byte string signature into a numeric signature

    Args:
        s (str): a string of 4 characters 

    Returns:
        (int) The numeric signature corresponding to the string signature
    """
    return str2sig(asbytes(s))

cdef inline ndarray _array_from_matrix_data_no_copy(SdifMatrixDataT *matrix):
    cdef SdifMatrixHeaderT *header = matrix.Header
    cdef npy_intp dims[2]
    dims[0] = <npy_intp>header.NbRow
    dims[1] = <npy_intp>header.NbCol
    return PyArray_SimpleNewFromData(2, dims, dtype_sdif2numpy(header.DataType), matrix.Data.Void)

cdef inline ndarray _array_from_matrix_data_copy(SdifMatrixDataT *matrix): 
    cdef ndarray out
    cdef SdifMatrixHeaderT *header = matrix.Header
    cdef npy_intp dims[2]
    dims[0] = <npy_intp>header.NbRow
    dims[1] = <npy_intp>header.NbCol
    out = PyArray_SimpleNew(2, dims, dtype_sdif2numpy(header.DataType)) 
    memcpy(<void *>out.data, matrix.Data.Void, c_numpy.PyArray_ITEMSIZE(out) * dims[0] * dims[1])
    return out


cdef inline bytes bytes_from_sdifstring(SdifStringT *s):
    cdef bytes out = s.str[:s.SizeW]
    return out
    
# cdef inline PyString_from_SdifString(SdifStringT *s):
#     """ convert a SdifStringT to a python string """
#     return PyString_FromStringAndSize(s.str, s.SizeW)
    
cdef SdifStringT *SdifString_from_PyString(s):
    cdef bytes s_bytes = asbytes(s)
    cdef char *c = s
    cdef SdifStringT *sdifstr = SdifStringNew()
    SdifStringAppend(sdifstr, c)
    return sdifstr
    
cdef dict nvt_to_dict( SdifNameValueTableT *nvt ):
    cdef int i
    cdef SdifUInt4      iNV
    cdef SdifHashNT     *pNV
    cdef SdifHashTableT *HTable
    cdef SdifNameValueT *namevalue
    
    HTable = nvt.NVHT
    table = {}
    for i in range(HTable.HashSize):
        pNV = HTable.Table[i]
        while pNV:
            namevalue = <SdifNameValueT *>(pNV.Data)
            name = namevalue.Name
            value = namevalue.Value
            table[name] = value
            pNV = pNV.Next
    return table
    
cdef valuetables_to_dicts (SdifNameValuesLT *namevalues):
    """ create a list of dicts where each dict represents a value table """
    SdifListInitLoop(namevalues.NVTList)
    tables = []
    while SdifListIsNext(namevalues.NVTList):
        namevalues.CurrNVT = <SdifNameValueTableT *>(SdifListGetNext(namevalues.NVTList))
        tables.append(nvt_to_dict(namevalues.CurrNVT))
    return tables
    
cdef streamidtable_to_list(SdifStreamIDTableT *table):
    cdef unsigned int i
    cdef SdifHashNT *pID
    cdef SdifStreamIDT *streamid
    streams = []
    for i in range(table.SIDHT.HashSize):
        pID = table.SIDHT.Table[i]
        while pID:
            streamid = <SdifStreamIDT *>(pID.Data)
            streamid_w = StreamID_fromSdifStreadIDT(streamid)
            streams.append(streamid_w)
            pID = pID.Next
    return streams
            
cdef class StreamID:
    cdef SdifStreamIDT *this
    cdef int own_this
    
    property numid:
        def __get__(self): return self.this.NumID
        
    property source:
        def __get__(self): return self.this.Source
        
    property treeway:
        def __get__(self): return self.this.TreeWay
        
    def __cinit__(self, int numid, source, treeway):
        if numid == -1:
            # we are a wrapper of an existing SdifStreamID
            self.own_this = 0
        else:
            self.this = SdifCreateStreamID(<SdifUInt4>numid, source, treeway)
            self.own_this = 1
            
    def __dealloc__(self):
        if self.own_this:
            SdifKillStreamID(self.this)
            
    def __repr__(self):
        return "StreamID(numid=%d, source='%s', treeway='%s')" % (
            self.numid,
            self.source,
            self.treeway)            
        
cdef StreamID_fromSdifStreadIDT(SdifStreamIDT *this):
    cdef StreamID out = StreamID(-1, None, None)  # create a wrapper
    out.this = this
    out.own_this = 0
    return out
    
cdef SdifMatrixTypeT *MatrixType_create(signature, column_names):
    cdef SdifSignature sig = str2sig(asbytes(signature))
    cdef SdifMatrixTypeT *mt = SdifCreateMatrixType(sig, NULL)
    for column_name in column_names:
        SdifMatrixTypeInsertTailColumnDef(mt, asbytes(column_name))
    return mt
    

cdef SdifFrameTypeT *FrameType_create(signature, list components):
    """
    Create a SdifFrameType with a given signature

    signature: a 4 char string
    components: a list of:
        + Components
        + tuples(str_signature, matrix_role)
        + strings "{SIGN} {ROLE}", like "1TRC SinusoidalTracks"
    """
    cdef SdifSignature sig = str2sig(asbytes(signature))
    cdef SdifFrameTypeT *ft = SdifCreateFrameType(sig, NULL)
    for component in components:
        if isinstance(component, Component):
            SdifFrameTypePutComponent(ft, str2sig(component.signature), component.name)
        elif isinstance(component, tuple):
            SdifFrameTypePutComponent(ft, str2sig(asbytes(component[0])), asbytes(component[1]))
        elif isinstance(component, (str, bytes)):
            component_b = asbytes(component)
            component_sig, component_name = component_b.split()
            SdifFrameTypePutComponent(ft, str2sig(component_sig), component_name)
        else:
            logger.error("components should be a seq. of Components"
                         "or tuples(signature, name), but got: %s" % components)
            return NULL
    return ft

cdef inline bytes asbytes(s):
    if isinstance(s, bytes):
        return s
    elif isinstance(s, str):
        return s.encode("ascii")
    else:
        raise TypeError("s should be either a str or bytes, got {}".format(type(s)))
    
cdef class MatrixTypeDefinition:
    cdef public bytes signature
    cdef public list column_names
    
    def __init__(self, signature, list column_names):
        """
        Args:
            signature (str): A 4 char signature
            column_names: list[str] - A list of column names, ["Col1", "Col2", "Col3", ...]
        """
        self.signature = asbytes(signature)
        self.column_names = [asbytes(name).strip() for name in column_names]
        
    def __repr__(self):
        return "1MTD(signature=%s, column_names=%s)" % (self.signature, self.column_names)
    
    cdef SdifMatrixTypeT *toSdifMatrixType(self):
        return MatrixType_create(self.signature, self.column_names)
        
cdef MatrixTypesTable_to_list(SdifHashTableT *t):
    cdef unsigned int i
    cdef SdifHashNT *pName
    cdef SdifMatrixTypeT *matrix
    cdef SdifColumnDefT *column_def
    cdef list out = []
    cdef list column_names
    cdef bytes signature
    for i in range(t.HashSize):
        pName = t.Table[i]
        while pName:
            matrix = <SdifMatrixTypeT *>(pName.Data)
            if not SdifListIsEmpty(matrix.ColumnUserList):
                signature = sig2str(matrix.Signature)
                column_def = <SdifColumnDefT *>SdifListGetHead(matrix.ColumnUserList)
                column_names = []
                column_names.append(bytes(column_def.Name))
                while SdifListIsNext(matrix.ColumnUserList):
                    column_def = <SdifColumnDefT *>(SdifListGetNext(matrix.ColumnUserList))
                    column_names.append(bytes(column_def.Name))
                row = MatrixTypeDefinition(signature=signature, column_names=column_names)
                out.append(row)
            pName = pName.Next
    return out
        
cdef class Component:
    cdef readonly bytes signature
    cdef readonly bytes name
    cdef readonly unsigned int num
    
    def __init__(self, signature, name, num=0):
        self.signature = asbytes(signature)
        self.name = asbytes(name)
        self.num = num
        
    def __repr__(self):
        return "Component(signature=%s, name=%s, num=%d)" % ( 
               self.signature, self.name, self.num)


cdef Component Component_from_SdifComponent(SdifComponentT *c):
    cdef Component out = Component(sig2str(c.MtrxS), bytes(c.Name), c.Num)
    return out
    
cdef FrameTypesTable_to_list(SdifHashTableT *t):
    cdef unsigned int i
    cdef SdifHashNT *pName
    cdef SdifFrameTypeT *frame
    cdef list out = []

    for i in range(t.HashSize):
        pName = t.Table[i]
        while pName:
            frame = <SdifFrameTypeT *>(pName.Data)
            if frame.NbComponentUse > 0:
                components = []
                signature = sig2str(frame.Signature)
                for j in range(frame.NbComponent - frame.NbComponentUse + 1, frame.NbComponent + 1):
                    component = Component_from_SdifComponent(SdifFrameTypeGetNthComponent(frame, j))
                    components.append(component)
                out.append(FrameTypeDefinition(signature, components))
            pName = pName.Next
    return out

cdef class FrameTypeDefinition:
    cdef readonly bytes signature
    cdef readonly list components
    
    def __init__(self, signature, components):
        """
        Object representing a 1FTD

        Args:
            signature (str):  The signature of the frame
            components: list[Component] - A list of components
        """
        assert isinstance(signature, (str, bytes))
        assert len(signature) == 4
        assert isinstance(components, list)
        assert all(isinstance(c, Component) for c in components)
        self.signature = asbytes(signature)
        self.components = components
        
    def __repr__(self):
        return "1FTD(signature='%s', components=%s)" % (self.signature, self.components)
            
# ----------------------------------------------------------------------

SDIF_PREDEFINEDTYPES = {
    'frametypes': {
        b'RBEP': [b'RBEP ReassignedBandEnhancedPartials']
    },
    'matrixtypes': {
        b'RBEP': b'Index, Frequency, Amplitude, Phase, Bandwidth, Offset'
    }
}

def read_sdiftypes():
    """
    Retrieves predefined types definitions parsed from SdifTypes.STYP

    Returns: 
        a tuple (frametypes, matrixtypes)
    """
    sdif_init()         
    frametypes = FrameTypesTable_to_list(gSdifPredefinedTypes.FrameTypesTable)
    matrixtypes = MatrixTypesTable_to_list(gSdifPredefinedTypes.MatrixTypesTable)
    return frametypes, matrixtypes

def _frametypes_populate():
    frametypeslist, matrixtypeslist = read_sdiftypes()
    frametypes = {f.signature: f.components for f in frametypeslist}
    matrixtypes = {m.signature: m.column_names for m in matrixtypeslist}
    allframetypes = SDIF_PREDEFINEDTYPES['frametypes']
    for f in frametypeslist:
        components = [b" ".join((comp.signature, comp.name)) for comp in f.components]
        allframetypes[asbytes(f.signature)] = components
    allmatrixtypes = SDIF_PREDEFINEDTYPES['matrixtypes']
    for matrixsig, column_names in matrixtypes.items():
        allmatrixtypes[asbytes(matrixsig)] = b", ".join(column_names)


def predefined_frametypes():
    """
    Returns a dict of predefined sdif frame types

    Returns:
        (dict[str: list[str]]) A dict (framesig: components)
    """
    return SDIF_PREDEFINEDTYPES['frametypes']


def predefined_matrixtypes():
    """
    Returns a list of predefined sdif matrix types

    Returns:
        (dict[str, list[str]) A dict (matrisig: column_names)
    """
    return SDIF_PREDEFINEDTYPES['matrixtypes']

# ----------------------------------------------------------------------

def _find_sdiftypes():

    def get_packaged_sdiftypes():
        try:
            thisfile = __file__
        except NameError:
            return None
        datadir = os.path.join(os.path.split(__file__)[0], "data")
        sdiftypes_data = os.path.join(datadir, "SdifTypes.STYP")
        if os.path.exists(sdiftypes_data):
            return sdiftypes_data
        return None

    pl = platform.system()
    if pl == "Linux":
        paths = [".", "/usr/local/share", "/usr/share", "~/.local/share"]
    elif pl == "Windows":
        paths = ["."]
    elif pl == "Darwin":
        paths = [".", "/usr/local/share", "/usr/share", "~/.local/share"]
    else:
        import warnings
        warnings.warn("Platform unknown")
        return ""
    paths = [os.path.abspath(os.path.expanduser(p)) for p in paths]
    for p in paths:
        p2 = os.path.join(p, "SdifTypes.STYP")
        if os.path.exists(p2):
            return p2
    else:
        packaged_sdiftypes = get_packaged_sdiftypes()
        if packaged_sdiftypes is not None:
            return packaged_sdiftypes
    return ""


def sdif_init(sdiftypes_path=None):
    """
    Initialize the sdif library 

    This function is called automatically whenever an instance of
    SdifFile is created. Calling this function explicitely only has an
    effect if done previous to any usage of the `pysdif` library, to 
    point the library to a `SdifTypes.STYP` file. This file is used
    by the underlying code as a library for known SDIF frames and matrix
    definitions. 

    If called without arguments, the default paths will be searched. If an empty 
    string is given, no `SdifTypes.STYP` will be used

    Args:
        sdiftypes_path (str): The path to `SdifTypes.STYP`, or None to search
            in default paths

    Returns:
       (bool) True if the library was initialized, False if it was already 
       initialized. In such a case, the path passed will not have any effect
    """
    global _g_sdif_initiated
    import_array()
    if _g_sdif_initiated == 0:
        _g_sdif_initiated = 1
        if sdiftypes_path is None:
            sdiftypes_path = _find_sdiftypes()
        if os.path.exists(sdiftypes_path):
            SdifGenInitCond(asbytes(sdiftypes_path))
            logger.info("Sdif initialized using path: %s" % sdiftypes_path)
        else:
            SdifGenInitCond(b"")
            logger.info("Sdif initialized without SdifTypes.")
        _frametypes_populate()
    return bool(_g_sdif_initiated)


def sdif_cleanup():
    SdifGenKill()
    
# Forward declarations
cdef class FrameR
cdef class SdifFile

# enums to keep state of reading
cdef enum MatrixStatusE:
    eMatrixInvalid,
    eMatrixNothingRead,
    eMatrixHeaderRead,
    eMatrixDataRead,
    eMatrixDataSkipped,
    eMatrixOffline

cdef enum FrameStatusE:
    eFrameInvalid,
    eFrameNothingRead,
    eFrameHeaderRead,
    eFrameSomeDataRead,
    eFrameAllDataRead,
    eFrameSignatureRead

cdef enum SdifStatusE:
    eSdifNothing,
    eSdifGeneralHeader,
    eSdifAllASCIIChunks,
    eSdifSignature,
    eSdifFrameHeader,
    eSdifMatrixHeader,
    eSdifMatrixData
    

cdef tuple _framestatus2str = (
    "Invalid",
    "NothingRead",
    "HeaderRead",
    "SomeDataRead",
    "AllDataRead",
    "SignatureRead"
)

def framestatus2str(int status):
    if 0 <= status < 6:
        return _framestatus2str[status]
    return None

cdef tuple _matrixstatus2str = (
    "Invalid",
    "NothingRead",
    "HeaderRead",
    "DataRead",
    "DataSkipped",
    "Offline"
)

def matrixstatus2str(int status):
    """
    Return a string identifier for a matrix status. 

    Args:
        status (int): The matrix status 

    Returns:
        (str) A corresponding string identifier

    """
    if 0 <= status < 6:
        return _matrixstatus2str[status]
    return None

# -----------------------------------------------------------------------------------------------

cdef class Matrix:
    """
    Matrix is a placeholder class to iterate through data while reading a SdifFile

    In particular the default behaviour is that when you are given a Matrix, 
    this is only valid until a new one is read.
    
    See the methods `get_data` and `copy` for a better explanation of how to 
    make the data in the Matrix persistent

    Args:
        source (SdifFile): The source sdiffile this matrix belongs to
    
    ## Example

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
    """
    cdef SdifFileT *source_this
    cdef SdifFile source
    cdef ndarray data
    cdef SdifSignature _signature
    cdef MatrixStatusE _status
    cdef int _valid

    def __cinit__(self, SdifFile source):
        if source is not None:
            self.source = source
            self.source_this = source.this
            self.data = None
            self._signature = 0
            self._status = eMatrixHeaderRead
        else:
            self.source_this = NULL
            self._status = eMatrixOffline
            
    property rows:
        def __get__(self): 
            if self.source_this:
                return self.source_this.CurrMtrxH.NbRow
            else:
                return len(self.data)
                
    property cols:
        def __get__(self): 
            if self.source_this:
                return self.source_this.CurrMtrxH.NbCol
            else:
                return len(self.data[0])
                
    property dtype:
        def __get__(self): 
            if self.source_this:
                return _SDIF_DATATYPES[self.source_this.CurrMtrxH.DataType]
            else:
                return self.data.dtype
                
    property signature:
        def __get__(self): 
            if self.source_this:
                return sig2str(self.source_this.CurrMtrxH.Signature)
            else:
                return sig2str(self._signature)
                
    property numerical_signature:
        def __get__(self): 
            #if self.header:
            if self.source_this:
                return self.source_this.CurrMtrxH.Signature
            else:
                return self._signature
                
    def get_data(self, copy=True):
        """
        Read the data from the matrix as a numpy array
        
        !!! note

            If copy is False, the data is not copied to the array. 
            The array is only a 'view' of this data and does not own it,
            so it is only valid until you read a new matrix. 
        
            If you want to keep the data, do get_data(copy=True) or call
            .copy() on the resulting numpy array 
       
        Args:
            copy (bool): if True, the returned data is a copy of the data read
                and will not be invalidated

        Returns:
            (numpy.array) The data as a numpy.array. If copy==False, this data
            is a view on the decoded data and will be invalidated when a new
            matrix is read
        """
        if self.source.matrix_status == eMatrixHeaderRead:
            self.source._matrix_read_data()

        if copy:
            return _array_from_matrix_data_copy(self.source_this.CurrMtrxData)
        return _array_from_matrix_data_no_copy(self.source_this.CurrMtrxData)

    def column_names(self):
        """
        Returns a list of column names for the current matrix

        Returns:
            (list[str]) Column names
        """
        cdef bytes sig = self.signature
        matrixtypes = {mtd.signaturesture: mtd.column_names for mtd in self.source.get_matrix_types()}
        colnames = matrixtypes.get(sig)
        if colnames is None:
            raise KeyError("This matrix type ({sig}) does not seem to be defined!".format(sig=sig))
        return colnames
        
    def skip(self):
        """
        Skip reading the data 

        This method can only be called if the data was not already read
        """
        if self.status == eMatrixHeaderRead:
            self.source.matrix_skip_data()
        else:
            raise SdifOrderError("Can't skip the matrix, status is %s" % (matrixstatus2str(self._status)))
            
    def __repr__(self):
        return "Matrix(sig=%s, rows=%d, cols=%d, dtype=%s)" % (
               self.signature, self.rows, self.cols, str(self.dtype))
        
    property status:
        def __get__(self): 
            if self.source_this != NULL:
                return self.source.matrix_status
            else:
                return self._status

            
# -----------------------------------------------------------------------------------------------

cdef class FrameR:
    """
    FrameR is an iterator over the matrices of a frame. 
    
    Access the matrices by iterating on the frame, or calling 
    next(frame). 

    !!! note

        A `FrameR` is not created by a user, it is yielded by
        a SdifFile on iteration.

    Args:
        source (SdifFile): the sidffile this frame belongs to

    ## Example
    
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
    """
    cdef SdifFrameHeaderT *header
    cdef SdifFile source
    cdef SdifFileT *source_this
    
    def __cinit__(self, SdifFile source):
        self.source = source
        self.source_this = source.this
        self.header = source.this.CurrFramH
        
    def __dealloc__(self):
        self.source = None

    def __repr__(self):
        return "FrameR(signature={sig}, time={t}, matrices={num}, idx={idx})".format(
            sig=self.signature, t=self.time, num=self.num_matrices, idx=self.matrix_idx)
        
    @property
    def signature(self):
        """ (str) The string signature of this frame """
        return sig2str(self.source_this.CurrFramH.Signature)
        
    @property
    def numerical_signature(self):
        if self.source_this.CurrFramH == NULL:
            raise SdifOrderError("The header of the current frame has not been read") 
        return self.source_this.CurrFramH.Signature
    
    @property
    def size(self):
        """
        (int) The size of this frame in bytes
        """
        if self.source_this.CurrFramH == NULL:
            raise SdifOrderError("The header of the current frame has not been read")  
        return self.source_this.CurrFramH.Size
    
    @property
    def num_matrices(self):
        """
        (int) The number of matrices in this frame
        """
        if self.source_this.CurrFramH == NULL:
            raise SdifOrderError("The header of the current frame has not been read")  
        return self.source_this.CurrFramH.NbMatrix
    
    def __len__(self):
        return self.num_matrices
    
    @property
    def id(self):
        """ (int) The id of this frame """
        if self.source_this.CurrFramH == NULL:
            raise SdifOrderError("The header of the current frame has not been read")  
        return self.source_this.CurrFramH.NumID

    @property
    def time(self):
        """ (float) The time of this frame """ 
        if self.source_this.CurrFramH == NULL:
            raise SdifOrderError("The header of the current frame has not been read") 
        return self.source_this.CurrFramH.Time

    @property
    def matrix_idx(self):
        """The index of the current matrix"""
        return self.source.matrix_idx

    def __iter__(self):
        if self.source.frame_status >= eFrameSomeDataRead:
            raise RuntimeError("A Frame can only be iterated once")
        self.source.frame_status = eFrameSomeDataRead
        return self
    
    def __next__(self):
        """
        Read next matrix in this Frame. Raises StopIteration if no more matrices

        Returns:
            (Matrix) the next matrix in this frame

        !!! note

            Only the header of the matrix will be read, to read the data
            you must call the method matrix.get_data() on the resulting Matrix
        """
        matrix = self.source.next_matrix()
        if matrix is None:
            raise StopIteration
        return matrix

    def get_matrix(self, copy=True):
        """
        Reads the next matrix entirely, returns (matrixsig, data)

        !!! note

            Raises `StopIteration` when there are no more matrices

        Args:
            copy: return a copy of the data. If copy==False, then the data
                is only valid as long as no other matrix is read. This is 
                done to avoid allocating new memory for each new matrix
                for the cases where the data is not preversed but transformed
                within a streaming procees.
        
        Returns:
            (tuple[str, numpy.array]) A tuple (string signature, matrix data)

        ## Example

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
        """
        matrix = self.__next__()
        return matrix.signature, matrix.get_data(copy=copy)


cdef class FrameW:
    """
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
    """
    cdef SdifFile sdiffile
    cdef SdifSignature signature
    cdef SdifFloat8 time
    cdef SdifUInt4 streamID
    cdef list matrices
    cdef list signatures
    cdef SdifUInt4 frame_size
    cdef SdifUInt4 num_matrices
    cdef int _written
    
    def __repr__(self):
        return "FrameW(signature=%s, time=%f, streamID=%d, written=%s)" % (
            sig2str(self.signature), self.time, self.streamID, bool(self._written))

    def __enter__(self):
        if self._written:
            raise RuntimeError("Frame has already been written!")
        return self

    def __exit__(self, exception_type, exception_value, traceback):
        if self.num_matrices == 0:
            raise RuntimeError("No matrices were added! Frame not written")
        self.write()

    property written:
        def __get__(self): return bool(self._written)
    
    def add_matrix(self, str signature, c_numpy.ndarray data_array):
        """
        Add a matrix to this Frame

        Args:
            signature (str): the signature of the matrix
            data_array (numpy.array): the data of the matrix, a 2D array
        """
        if self._written:
            raise RuntimeError("Frame has already been written!")
        if data_array.ndim == 1:
            data_array.resize((data_array.shape[0], 1))
        self.signatures.append(asbytes(signature))
        self.matrices.append(np.ascontiguousarray(data_array))
        self.num_matrices += 1
        self.frame_size += SdifSizeOfMatrix(
            <SdifDataTypeET>(dtype_numpy2sdif(data_array.descr.type_num)),
            data_array.shape[0], data_array.shape[1]) # rows, cols
        
    def write(self):
        """
        Write the current frame to disk. 

        This function is called after add_matrix has been called (if there 
        are any matrices in the current frame). The frame is written all at once. 
        """
        if self._written:
            raise RuntimeError("Frame has already been written!")
        cdef SdifUInt4 fsz
        cdef SdifSignature matrix_sig
        cdef int dtype
        cdef c_numpy.ndarray matrix
        cdef int i
        SdifFSetCurrFrameHeader(self.sdiffile.this, self.signature, self.frame_size, 
                                self.num_matrices, self.streamID, self.time)
        fsz = SdifFWriteFrameHeader(self.sdiffile.this)
        for i in range(self.num_matrices):
            matrix_sig = str2sig(self.signatures[i])
            matrix = self.matrices[i]
            dtype = dtype_numpy2sdif(matrix.descr.type_num)
            fsz += SdifFWriteMatrix(self.sdiffile.this, matrix_sig, 
                                    <SdifDataTypeET>dtype, 
                                    matrix.shape[0], matrix.shape[1],   # rows, cols
                                    matrix.data)
        self._written = 1
        self.sdiffile.write_status = eSdifMatrixData


cdef FrameW FrameW_new(SdifFile sdiffile, SdifSignature sig,
                       SdifFloat8 time, SdifUInt4 streamID=0):
    cdef FrameW f = FrameW()
    f.sdiffile = sdiffile
    f.signature = sig
    f.time = time
    f.streamID = streamID
    f.matrices = []
    f.signatures = []
    f.frame_size = SdifSizeOfFrameHeader()
    f.num_matrices = 0
    f._written = 0
    return f

            
# -----------------------------------------------------------------------------------------------
    
cdef class SdifFile:
    """
    This is a wrapper around a SdifFileT c-struct (`sdif.h`)
    
    It enables to read and write a SDIF file of any form.
    It provides **two interfaces**: a **low-level interface**, which
    reflects the original implementation and requires that the 
    user is acquainted with the internal structure of a SDIF file; and
    a **high-level interface** which takes care of most of the book-keeping.

    ```python
    
    SdifFile(filename: str, mode="r")
    
    ```

    Args:
        filename (str):  path to a sdif file
        mode (str): "r" = read, "w" = write, "rw" = read+write


    ## Example 1: read a sdiffile 

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

    ## Example 2: write a sdiffile

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
    """
    cdef SdifFileT *this
    cdef readonly int eof
    cdef FrameR frame
    cdef Matrix matrix
    cdef FrameStatusE frame_status
    cdef int matrix_idx
    cdef MatrixStatusE matrix_status
    cdef SdifStatusE write_status
    cdef set _frametypes_defined   # a set of byte signatures
    cdef set _matrixtypes_defined  # a set of byte signatures

    def __cinit__(self, filename, mode="r", predefined_type=None):
        sdif_init()
        self.this = NULL
        errormsg = None    
        filename = asbytes(filename)
        if mode == "r" or mode == "rw":
            if not os.path.exists(filename):
                errormsg = "path not found, cannot open sdif file for reading"
        elif mode == "w":
            path = os.path.split(os.path.abspath(filename))[0]
            if not os.path.exists(path):
                errormsg = "Path %s does not exist, can't create a file" % path
        else:
            errormsg = "mode should be on of 'r', 'w', 'rw'"

        if errormsg is not None:
            self.eof = SDIF_CLOSED
            print(errormsg)
            logger.error(errormsg)
        else:
            self.this = SdifFOpen(asbytes(filename), FILEMODE_STR2MODE[mode])
            self.eof = 0
            self.matrix_idx = 0    
        
    def __init__(self, str filename, mode="r"):
        """
        Args:
            filename (str): the sdif file to open
            mode (str): r=read, w=write
        """
        if self.eof == SDIF_CLOSED or self.this == NULL:
            logger.debug("error opening file")
            raise IOError("Could not open %s" % filename)
        logger.debug("SdifFile.__init__")
        if self.this.Mode == eReadFile:
            self.init_read()
            sigs = {ftd.signature for ftd in self.get_frame_types()}
            if self.signature not in sigs:
                if self.signature in predefined_frametypes():
                    self.add_predefined_frametype(self.signature)
                else:
                    logger.error("Undefined frametype: {sig}.\n"
                                 "You must add the frametype definition and the"
                                 "corresponding matrix definitions before reading"
                                 "".format(sig=self.signature))
        elif self.this.Mode == eWriteFile:
            self.init_write()

    def __repr__(self):
        if self.this == NULL:
            return "SdifFile(NULL)"
        l = []
        l.append("SdifFile(name={name}, mode={mode})".format(name=self.name, mode=self.mode))
        if self.mode == 'r' or self.mode == 'rw':
            l.append("Status: Frame: {frame}  | MatrixIdx: {midx} | Matrix: {matrix}".format(
                frame=framestatus2str(self.frame_status),
                midx=self.matrix_idx,
                matrix=matrixstatus2str(self.matrix_status))
            )
        return "\n".join(l)


    cdef void init_read(self):
        SdifFReadGeneralHeader (self.this)  
        SdifFReadAllASCIIChunks(self.this)  
        self.eof = (self.this.CurrSignature == eEof)
        self.this.TextStream = stdout  # this is needed by the print functions
        self.init_containers()
        self.frame_status = eFrameNothingRead
        self.matrix_idx = 0
        self.matrix_status = eMatrixNothingRead
        
    cdef void init_containers(self):
        self.frame = FrameR(self)
        self.matrix = Matrix(self)
        
    cdef void init_write(self):
        SdifFWriteGeneralHeader(self.this)
        self.write_status = eSdifGeneralHeader
        self._frametypes_defined = set()
        self._matrixtypes_defined = set()
        
    def __dealloc__(self):
        logger.debug("SdifFile: dealloc")
        self.frame = None
        self.matrix = None
        self.close()  # fails silently if already closed
    
    def close(self):
        """
        Close this SdifFile
        """
        if self.eof == SDIF_CLOSED:
            logger.debug("close: can't close SdifFile, since it was already closed")
            return
        elif self.this == NULL:
            logger.debug("close: can't close SdifFile: it is NULL")
        # make sure we write the global header even if no
        # new frames are written (the global chunks are automatically
        # written when a new frame is added to the sdiffile)
        if self.this.Mode == eWriteFile:
            if self.write_status == eSdifGeneralHeader:
                self.write_all_ascii_chunks()
        SdifFClose(self.this)
        self.eof = SDIF_CLOSED

    @property
    def name(self):
        return self.this.Name

    @property
    def mode(self):
        return FILEMODE_MODE2STR[self.this.Mode]
    
    @property
    def is_seekable(self):
        """
        (bool) Is this SdifFile seekable?
        """
        return self.this.isSeekable

    @property
    def numerical_signature(self):
        """
        (int) Current signature as numerical signature
        """
        return self.this.CurrSignature

    @property 
    def signature(self): 
        """(str) Current signature as 4-byte string """
        return sig2str(self.this.CurrSignature)

    @property 
    def prev_time(self): 
        """(float)"""
        return self.this.PrevTime

    @property
    def frame_pos(self):
        return self.this.CurrFramPos

    def curr_matrix_size(self):
        """
        Returns the number of rows and number of columns in the current matrix

        This method can be called after reading the matrix header. It does 
        not read the data itself

        Returns:
            (tuple[int, int]) A tuple (num_rows, num_columns)
        
        !!! note 

            raises `NoMatrix` if the matrix header has not been read
        """
        cdef SdifMatrixHeaderT* m = self.this.CurrMtrxH
        if m == NULL:
            raise NoMatrix("No current matrix")
        return (m.NbRow, m.NbCol)

    def curr_matrix_datatype(self):
        """
        Returns the datatype code (an int) or 0 if go current matrix

        Returns:
            (int) the datatype of the current matrix as an int code
        """
        if self.this.CurrMtrxH == NULL:
            return 0
        return self.this.CurrMtrxH.DataType

    def curr_signature(self):
        """
        **Low-level interface** - Return the current frame's numerical signature

        Returns:
            (int) The current numerical signature
        """
        return SdifFCurrSignature(self.this)

    cdef int curr_matrix_numerical_signature(self):
        if self.this.CurrMtrxH == NULL:
            return -1
        return self.this.CurrMtrxH.Signature

    def curr_matrix_signature(self):
        """
        Get the string signature of the current matrix, or None if no current matrix

        Returns:
            (str | None) The 4-byte string signature of the current matrix, 
            or None if no matrix
        """
        
        cdef int sig = self.curr_matrix_numerical_signature()
        if sig >= 0:
            return sig2str(sig)
        return None

    def frame_num_matrix(self):
        """
        Get the number of matrices in current frame.    

        Returns:
            (int) The number of matrices in the current frame, or -1
            if no current frame

        """
        if self.this.CurrFramH == NULL:
            return -1
        return self.this.CurrFramH.NbMatrix

    def frame_id(self):
        """
        Get the id of the current frame, or -1 if no current frame

        Returns:
            (int) The id of the current frame
        """
        if self.this.CurrFramH == NULL:
            return -1
        return self.this.CurrFramH.NumID

    @property 
    def pos(self): 
        """The last position read"""
        cdef SdiffPosT _pos
        SdifFGetPos(self.this, &_pos)
        return _pos
        
    @pos.setter
    def pos(self, long pos): 
        """
        The position in the file
        """
        SdifFSetPos(self.this, &pos)

    def frame_numerical_signature(self):
        """
        Return the num. signature of current frame, or -1 if no current frame

        Returns:
            (int) The numerical signature of the current frame, or -1 
            if no current frame
        """
        if self.this.CurrFramH == NULL:
            return -1
        return self.this.CurrFramH.Signature

    def frame_signature(self):
        """
        Return the str. signature of the current frame, or None if no current frame

        Returns:
            (str|None) The current frame signature (4-char string)
        """
        if self.this.CurrFramH == NULL:
            return None
        return sig2str(self.this.CurrFramH.Signature)

    def frame_time(self):
        """
        Get the time of the current frame, or -1 if no current frame

        Returns:
            (float) The time of the current frame
        """
        if self.this.CurrFramH == NULL:
            return -1
        return self.this.CurrFramH.Time

    def last_error(self):
        """
        Returns (error_tag, error_level) or None if there is no last error

        """
        cdef SdifErrorT* error = SdifFLastError(self.this)
        if error == NULL:
            return None
        return (error.Tag, error.Level)

    def curr_frame_is_selected(self):
        """
        Return whether the current frame is selected. 

        Can only be called after reading the frame header. 

        !!! note

            Raises `NoFrame` if no header was read

        Returns:
            (bool) True if current frame is selected
        """
        if self.this.CurrFramH == NULL:
            raise NoFrame("No current matrix!")
        return bool(SdifFCurrFrameIsSelected(self.this))

    def curr_matrix_is_selected(self):
        """
        Return whether the current matrix is selected. 

        !!! note

            Raises `NoMatrix` if the matrix header was not read.

        Returns:
            (bool) True if current matrix is selected
        """
        if self.this.CurrFramH == NULL:
            raise NoMatrix("No current matrix!")
        return bool(SdifFCurrMatrixIsSelected(self.this))
        
    def get_num_NVTs(self):
        if SdifNameValuesLIsNotEmpty(self.this.NameValues):
            return SdifFNameValueNum(self.this)
        else:
            return 0

    
    cdef int _frame_read_header(self):
        """
        Internal function. 

        Read the header, return the number of bytes read
        If an error occurs, returns -1
        If eof is reached, returns 0
        """
        if self.eof == 1:
            return 0
        cdef int status = self.frame_status
        if status == eFrameHeaderRead or status == eFrameSomeDataRead or status == eFrameAllDataRead:
            return -1
        cdef int bytes_read = SdifFReadFrameHeader(self.this)
        # bytes_read += self._read_signature()
        self.frame_status = eFrameHeaderRead
        self.matrix_idx = 0
        self.matrix_status = eMatrixNothingRead
        return bytes_read

    def frame_read_header(self):
        """
        ** Low level interface ** - Read the frame header.

        Returns the number of bytes read. If it reaches the
        end of file, self.eof is 1 and this function returns 0

        Raises SdifOrderError if the header or some of the data
        were already read from this frame.
        
        Returns:
            (int) The bytes read
        """
        cdef int error
        if self.frame_status == eFrameAllDataRead:
            # we are at the end of the last frame.
            logger.debug("frame_read_header: finalizing last frame")
            error = self._finalize_frame()
            if error:
                raise SdifOrderError("Error finalizing Frame")
        cdef int bytesread = self._frame_read_header()
        if bytesread >= 0:
            return bytesread
        else:
            if self.frame_status == eFrameHeaderRead:
                raise SdifOrderError("The header was already read")
            else:
                raise SdifOrderError("The frame should be read or skipped before a new header is read")

    def frame_skip_data(self):
        """
        **Low level interface** - Skip frame and all its matrices
        """
        cdef size_t bytes_read = SdifFSkipFrameData (self.this)
        logger.debug("frame_skip_data: calling finalize_frame")
        cdef int error = self._finalize_frame()
        if error:
            raise SdifOrderError("Error finalizing Frame")
        return bytes_read

    cpdef int _read_signature(self):
        cdef size_t NbCharRead
        self.eof = SdifFGetSignature(self.this, &NbCharRead) == eEof
        self.frame_status = eFrameSignatureRead
        return NbCharRead

    cdef inline size_t _read_matrix_header(self):
        """
        Internal

        Read the matrix header (signature, number of rows and columns, etc.)
        Return the number of bytes read or 0 if no more matrices.
        """
        if self.matrix_idx >= self.this.CurrFramH.NbMatrix:
            return 0
        self.frame_status = eFrameSomeDataRead
        self.matrix_status = eMatrixHeaderRead  
        return SdifFReadMatrixHeader(self.this)

    def matrix_read_header(self):
        """
        **Low level interface** - Read the matrix header 

        Reads the matrix header (signature, number of rows and columns, etc.)
        Return the number of bytes read or 0 if no more matrices,
        or if eof is reached

        !!! note

            Raises `NoFrame` if no current frame

        Returns:
            (int) The bytes read
        """
        if self.frame_status == eFrameNothingRead:
            raise SdifOrderError("Frame header has not been read")
        if self.this.CurrFramH == NULL:
            raise NoFrame("no current frame")
        if self.matrix_status == eMatrixHeaderRead:
            raise SdifOrderError("Matrix header was already read")
        if self.eof:
            logger.error("Attempted to read past end of file")
            return 0
        cdef size_t bytesread = self._read_matrix_header()
        return bytesread
        
    def curr_frame_available(self):
       return self.this.CurrFramH != NULL 

    def curr_matrix_available(self):
       return self.this.CurrMtrxH != NULL
    
    def matrix_skip_data(self):
        """
        **Low-level Interface** - Skip the matrix data without reading it.

        !!! note

            Raises NoFrame if no current frame

        Returns:
            (int) The bytes read. 
        """
        if self.this.CurrFramH == NULL:
            raise NoFrame("matrix_skip_data: no current frame")
        if self.matrix_status != eMatrixHeaderRead:
            raise SdifOrderError("Matrix data can only be skipped after reading the matrix header")  
        cdef size_t bytes_read = SdifFSkipMatrixData(self.this)
        self.matrix_status = eMatrixDataSkipped
        cdef int error = self._finalize_matrix()
        if error:
            raise SdifOrderError("error finishing matrix")
        return bytes_read
    
    cdef inline int _matrix_read_data(self):
        """
        Read the matrix data. 
        
        Returns:
            (int) The number of bytes read, 0 if error 
        """
        if self.this.CurrFramH == NULL:
            return 0
        cdef int bytesread = SdifFReadMatrixData(self.this)
        self.matrix_status = eMatrixDataRead
        cdef int error = self._finalize_matrix()
        if error:
            return 0
        return bytesread
    
    def matrix_read_data(self, copy=False):
        """
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
        """
        cdef int status = self.matrix_status
        cdef size_t bytesread
        if status == eMatrixDataSkipped:
            raise SdifOrderError("Can't get the data, since it was already skipped")
        if status == eMatrixNothingRead:
            if not self.matrix_read_header():
                if self.matrix_idx >= self.this.CurrFramH.NbMatrix:
                    raise SdifOrderError("Attempted to read matrix header, but there are no more matrices in this frame")
                else:
                    raise IOError("Could not read matrix header. ")
            status = eMatrixHeaderRead
        if status == eMatrixHeaderRead:
            bytesread = self._matrix_read_data()
            if not bytesread:
                raise IOError("matrix empty or could not read matrix data")
        if copy:
            return _array_from_matrix_data_copy(self.this.CurrMtrxData) 
        return _array_from_matrix_data_no_copy(self.this.CurrMtrxData)
    
    cdef inline int _finalize_matrix(self):
        """
        Return 0 if OK, -1 if error
        """
        logger.debug("finalize_matrix")
        cdef int st = self.matrix_status
        if not (st == eMatrixDataRead or st == eMatrixDataSkipped):
            logger.debug("tried to finalize matrix, but status is %s" % matrixstatus2str(st))
            return -1
        self.matrix_idx += 1
        self.matrix_status = eMatrixNothingRead
        if self.matrix_idx >= self.this.CurrFramH.NbMatrix:
            self.frame_status = eFrameAllDataRead
            self._finalize_frame()
        else:
            self.frame_status = eFrameSomeDataRead
        return 0
    
    def matrix_skip(self):
        """
        Low level Interface. Skip the matrix altogether. 

        !!! note

            this CAN be called after having read the header, in which
            case only the data is skipped, otherwise the matrix is
            skipped altogether
        
        """
        if self.this.CurrFramH == NULL:
            raise NoFrame("matrix_skip: no current frame")
        cdef int matrix_status = self.matrix_status
        cdef size_t bytes_read
        if matrix_status == eMatrixHeaderRead:
            bytes_read = SdifFSkipMatrixData(self.this)
        elif matrix_status == eMatrixNothingRead:
            bytes_read = SdifFSkipMatrix(self.this)
        else:
            raise SdifOrderError("Matrix can only be skipped if data has not been already read or skipped")
        self.matrix_status = eMatrixDataSkipped
        cdef int error = self._finalize_matrix()
        if error:
            raise SdifOrderError("Error finalizing matrix")
        return bytes_read
    
    def status(self):
        """
        Returns a tuple (curr_frame_status, curr_matrix_index, curr_matrix_status)
        """
        return self.frame_status, self.matrix_idx, self.matrix_status
    
    def __iter__(self): 
        return self

    def __next__(self):
        self._next_frame()
        if self.eof == 1:
            raise StopIteration
        return self.frame
        
    cdef inline void _next_frame(self):
        if self.eof == 1:
            return
        cdef int frame_status = self.frame_status
        if frame_status == eFrameSomeDataRead or frame_status == eFrameHeaderRead:
            self.frame_skip_rest()  
        self.frame_read_header()
        if self.eof == 1:
            return

    def next_frame(self):
        """
        Read the next frame, returns a Frame or None if no more frames left.
        
        Returns:
            (Frame | None) Returns the next Frame, or None if no more frames

        ## Example

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

        """
        self._next_frame()
        return self.frame if self.eof == 0 else None

    def __enter__(self):
        return self

    def __exit__(self):
        self.close()

    def frame_skip_rest(self):
        """
        Skipts the rest of the frame, so that a new frame can be read.

        Returns:
            (bool) True if anything was skipped, False otherwise
        """
        logger.debug("frame_skip_rest")
        if self.eof:
            raise EOFError("Attempted to read past end of file")
        cdef int error = self._frame_skip_rest()
        return False if error else True
        
    cdef int _frame_skip_rest(self):
        """
        Skipts the rest of the frame, so that a new frame can be read. 
        """
        cdef int status = self.frame_status
        cdef int num_matrix
        cdef int i
        if status == eFrameSignatureRead or status == eFrameNothingRead:
            self.frame_read_header()
            status = eFrameHeaderRead
        if status == eFrameHeaderRead or status == eFrameSomeDataRead:
            for i in range(self.matrix_idx, self.frame_num_matrix()):
                self.matrix_skip()
            return 0
        else:
            logger.debug("_frame_skip_rest: Attempted to skip, but everything was read already")
            return -1
    
    cdef inline int _finalize_frame(self):
        logger.debug("_finalize_frame")
        cdef int status = self.frame_status
        if self.frame_status == eFrameSignatureRead:
            logger.debug("_finalize_frame called, but header was not even read")
            return -1
        elif status == eFrameSomeDataRead or status == eFrameHeaderRead:
            logger.debug("_finalize_frame without having read everything")
            return -1
        # self.matrix_idx = 0
        self.matrix_status = eMatrixNothingRead
        self._read_signature()
        return 0      

    def next_matrix(self):      
        """
        Read the next matrix header and return a Matrix with its data **still not read**. 

        If the previous matrix was not read fully, its data is skipped. This is the
        same as calling `next(frame)`

        Returns:
            (Matrix|None) The next Matrix or None if no more matrices available
        """
        if self.this.CurrFramH == NULL:
            raise NoFrame("no current frame")
        cdef int matrix_status = self.matrix_status
        if matrix_status == eMatrixHeaderRead:
            # SdifFSkipMatrixData(self.this)
            self.matrix_skip_data()
        elif matrix_status != eMatrixNothingRead:
            raise SdifOrderError("Some data of the matrix has been read (%s)" % matrixstatus2str(matrix_status)) 
        if self.matrix_idx >= self.this.CurrFramH.NbMatrix:
            return None
        if not self.matrix_read_header():
            raise IOError("Could not read matrix header. ")
        return self.matrix

    def rewind(self):
        """
        Rewind the SdifFile. 

        After this function is called, the file is in its starting frame 
        (as if the file had been just open)
        """
        SdifFRewind(self.this)
        self.reinit()

    def _rewind(self):
        SdifFRewind(self.this)

    cdef void reinit(self):
        if self.mode == 'r' or self.mode == 'rw':
            self.init_read()
        if self.mode == 'w':
            self.init_write()
        
    def _read_padding(self):
        return SdifFReadPadding(self.this, SdifFPaddingCalculate(self.this.Stream, self.this.Pos))
        
    # ------------------------------------------------
    #                      WRITING
    # ------------------------------------------------ 
    
    def add_NVT(self, dict d):
        """
        The NVT (Name Value Table) is a place to put metadata about the file.
        
        The NVT is a hash table (key: value) where both key and value are a bytes 
        string.

        Args:
            d (dict): A python dictionary which is translated to a NVT 
        
        ## Example

        ```python

        import pysdif
        f = pysdif.SdifFile("foo.sdif", "w")
        f.add_NVT({'Author': 'pysdif3', 'SampleRate': '44100'})
        
        ```
        """
        SdifNameValuesLNewTable(self.this.NameValues, _SdifNVTStreamID)
        for name, value in d.iteritems():
            if not isinstance(name, (str, bytes)):
                raise TypeError("Only strings or bytestrings are allowed, but found %s of type %s" % (name, type(name))) 
            if not isinstance(value, (str, bytes)):
                raise TypeError("Only strings or bytestrings are allowed, but found %s of type %s" % (value, type(value))) 
            SdifNameValuesLPutCurrNVT(self.this.NameValues, asbytes(name), asbytes(value))
            
    def add_matrix_type(self, signature, column_names):
        """
        Adds a matrix type to this Sdif

        Args:
            signature (str): The signature as 4-byte string
            column_names (list[str]): The names of the columns of this matrix

        There are two possible formats for the column names:
            
        * `sdiff.add_matrix_type("1ABC", "Column1, Column2")` or
        * `sdiff.add_matrix_type("1ABC", ["Column1", "Column2"])`
        
        See also: add_frame_type
        
        """
        sig = asbytes(signature)
        if isinstance(column_names, (str, bytes)):
            column_names = asbytes(column_names).replace(b",", b" ").split()
        cdef SdifMatrixTypeT *mt = MatrixType_create(signature, column_names)
        if mt == NULL:
            raise RuntimeError("Could not create matrixtype")
        SdifPutMatrixType(self.this.MatrixTypesTable, mt)
        # TODO: is this a memory leak? who destroys the MatrixType?
        #self.frame_status = eFrameInvalid
        
    def add_frame_type(self, signature, list components):
        """
        Adds a frame type to this sdif. 

        A frame is defined by a signature and a list of possible matrices. 

        Args:
            signature (str):A 4-char string
            components (list[str]): A list of components, where each component is a string
                of the sort `"{Signature} {Name}"`, like `["1NEW NewMatrix", "1FQ0 New1FQ0"]`    

        A frame type defines which matrix types are allowed in it.
        The matrices mentioned in the frame type MUST be defined
        via `add_matrix_type`.

        !!! note

            A frame can have multiple matrices in it, so when defining
            a frame-type, you need to pass a sequence of possible
            matrices.

        
        ## Example

        Add a new frame type 1NEW, with a 1NEW matrix type
        
        ```python

        sdiffile.add_frame_type("1NEW", ["1NEW NewMatrix"])
        sdiffile.add_matrix_type("1NEW", "Column1, Column2")
        
        ```

        **See also**: `add_matrix_type`
        """
        cdef SdifFrameTypeT *ft = FrameType_create(signature, components)
        if ft == NULL:
            raise RuntimeError("Could not create frametype")
        SdifPutFrameType(self.this.FrameTypesTable, ft)
        # TODO: is this a memory leak? who destroys the FrameType?
        
    def clone_type_definitions(self, SdifFile source):
        """
        
        Clone the frame and matrix type definitions of source_sdiffile
        
        !!! note

            Only for writing mode. This function must be called before 
            any frame has been written

        Args:
            source (SdifFile): The sourc file to clone type definitions from
        """
        if not(self.this.Mode == eWriteFile or self.this.Mode == eReadWriteFile):
            raise IOError("This function is only possible for SdifFiles opened in write mode")
        frametypes = source.get_frame_types()
        matrixtypes = source.get_matrix_types()
        for frametype in frametypes:
            self.add_frame_type(frametype.signature, frametype.components)
        for matrixtype in matrixtypes:
            self.add_matrix_type(matrixtype.signature, matrixtype.column_names)
        
    def clone_NVTs(self, SdifFile source):
        """
        Clone the NVT (name:value table) from source (an open SdifFile)
        
        !!! note

            Only for writing mode. If you do not plan to midify the type 
            definitions included in the source file, it's better to call 
            `clone_definitions`, which clones everything but the data
            (see example)

        Args:
            source (SdifFile): The source SdifFile to clone the NVTs from
        
        ## Example

        ```python    
        source_sdif = SdifFile("in.sdif")
        new_sdif = SdifFile("out.sdif", "w")
        new_sdif.clone_definitions(source_sdif)
        for frame in old_sdif:
            new_frame = new_sdif.new_frame(frame.signature, frame.time)
            # ... etc ...

        ```
        """
        for nvt in source.get_NVTs():
            self.add_NVT(nvt)
            
    def clone_definitions(self, SdifFile source):
        """
        Only for writing mode - Clone both NVT(s), frame and matrix definitions 

        Clone NVT, frame and matrix definitions from source, so after calling 
        this function you can start creating frames

        Args:
            source (SdifFile): The sdiffile to clone definitions from
        
        ## Example

        ```python

        infile = SdifFile("myfile.sdif")
        outfile = SdifFile("outfile.sdif", "w")
        outfile.clone_definitions(infile)
        for inframe in infile:
            with outfile.new_frame(inframe.signature) as outframe:
                matrixsig, data = inframe.get_one_matrix_data()
                outframe.add_matrix(matrixsig, data)
        
        ```
        """
        if not(self.this.Mode == eWriteFile or self.this.Mode == eReadWriteFile):
            raise IOError("This function is only possible for SdifFiles opened in write mode")
        self.clone_NVTs(source)
        self.clone_type_definitions(source)
        return self
    
    def clone_frames(self, SdifFile source, signatures_to_clone=None):
        """
        Clone all the frames in source which are included in 
        
        Args:
            source (SdifFile): The SdifFile to clone from
            signatures_to_clone (list[str]): A seq. of signature, or None to clone all
        
        Returns:
            None

        !!! note

            the use case for this function is when you want to
            modify some of the metadata but leave the data itself
            unmodified
        
        """
        if not(self.this.Mode == eWriteFile or self.this.Mode == eReadWriteFile):
            raise IOError("This function is only possible for SdifFiles opened in write mode")
        
        if signatures_to_clone is not None:
            sigs = set(asbytes(sig) for sig in signatures_to_clone)
        for frame0 in source:
            if signatures_to_clone is None or frame0.signature in sigs:
                frame1 = self.new_frame(frame0.signature, frame0.time)
                for matrix in frame0:
                    frame1.add_matrix(matrix.signature, matrix.get_data())
                frame1.write()
            
    def add_streamID(self, unsigned int numid, char *source, char *treeway):
        """
        This method is only there for completion. 

        It seems to be only used in old sdif types

        Args:
            numid (int): The numerical ID of the new stream
            source (str): ?? 
            treeway (str): ??

        Returns:
            None 
        """
        SdifStreamIDTablePutSID(self.this.StreamIDsTable,
            numid, source, treeway)

    def add_predefined_frametype(self, signature):
        """
        Add a predefined frame type with corresponding matrix definitions

        This type must be already defined globally. If not already defined, add 
        your definitions via `frametypes_set` and `matrixtypes_set`

        Args:
            signature (str): the 4-char string signature
        """
        sig = asbytes(signature)
        components = predefined_frametypes().get(sig)
        # a component is a strings '{Signature} {Description}'
        if not components:
            raise KeyError("signature not found")
        self.add_frame_type(sig, components)
        for comp in components:
            matrixsig, matrixrole = comp.split()
            column_names = SDIF_PREDEFINEDTYPES['matrixtypes'].get(asbytes(matrixsig))
            if not column_names:
                raise KeyError("Failed to fetch the column names for {sig}".format(sig=matrixsig))
            if isinstance(column_names, str):
                column_names = bytes(column_names)
            self.add_matrix_type(matrixsig, column_names)

    def write_all_ascii_chunks(self):
        """
        **Low-level Interface** 

        Once the NVTs and matrix and frame definitions have been added to the SdifFile,
        this methods writes them all together to disk and the SdifFile is ready to accept
        new frames.
        """
        if not(self.this.Mode == eWriteFile or self.this.Mode == eReadWriteFile):
            raise IOError("This function is only possible for SdifFiles opened in write mode")
        if self.write_status != eSdifGeneralHeader:
            return
        SdifFWriteAllASCIIChunks(self.this)
        self.write_status = eSdifAllASCIIChunks
        
    def new_frame(self, signature, SdifFloat8 time, SdifUInt4 streamID=0):
        """
        Create a new frame with given signature and at given time

        !!! note "Stream/Frame/Matrix"

            A SDIF file can have 1 or more streams. Each stream has multiple
            frames. A frame is a collection of matrixes at a given time.

        Args:
            signature (str): The signature of the new Frame
            time (float): The time of the new frame
            streamID (int): The ID of the stream
    
        Returns:
            (FrameW) A FrameW, used to write a (see example)
        
        ## Example
        
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

        """
        # ask for a new frame means that we are through with
        # defining the global header (ascii chunks) so verify that
        # we have written it
        if not(self.this.Mode == eWriteFile or self.this.Mode == eReadWriteFile):
            raise IOError("This function is only possible for SdifFiles opened in write mode")
        if self.write_status == eSdifGeneralHeader:
            self.write_all_ascii_chunks()
        return FrameW_new(self, str2sig(asbytes(signature)), time, streamID)
        
    def new_frame_one_matrix(self, frame_sig, SdifFloat8 time, matrix_sig,
                             c_numpy.ndarray matrixdata, SdifUInt4 streamID=0):
        """
        Create a frame containing only one matrix and write it
        
        This method creates the frame, creates a new matrix
        in the frame and writes it to disk, all at once

        Args:
            frame_sig (str): The frame signature
            time (float): The time of the frame
            matrix_sig (str): The matrix signature
            matrixdata (numpy.array): The data of the matrix, a 2D array
            streamID (int): The ID of the stream to add this frame/matrix to

        Returns:
            None
        
        !!! note

            use this method when you want to create a frame which
            contains only one matrix, like a 1TRC frame. It is more efficient
            than calling new_frame, add_matrix, write (see method 'new_frame')
        
        """
        if not(self.this.Mode == eWriteFile or self.this.Mode == eReadWriteFile):
            raise IOError("This function is only possible for SdifFiles opened in write mode")
        if self.write_status == eSdifGeneralHeader:
            self.write_all_ascii_chunks()
        cdef size_t frame_size = SdifSizeOfFrameHeader() + SdifSizeOfMatrix(
            <SdifDataTypeET>(dtype_numpy2sdif(matrixdata.descr.type_num)),
            matrixdata.shape[0], matrixdata.shape[1] # rows, cols
        )
        SdifFSetCurrFrameHeader(self.this, str2sig(asbytes(frame_sig)), frame_size, 1, streamID, time)
        SdifFWriteFrameHeader(self.this)
        if not matrixdata.flags.c_contiguous:
            matrixdata = np.ascontiguousarray(matrixdata)
        SdifFWriteMatrix(self.this, str2sig(asbytes(matrix_sig)), 
                         <SdifDataTypeET>dtype_numpy2sdif(matrixdata.descr.type_num),
                         matrixdata.shape[0], matrixdata.shape[1],   # rows, cols
                         matrixdata.data)
        self.write_status = eSdifMatrixData
        
    # low level functions to print info
    def print_NVT(self):
        """ **Low-Level Interface** """
        SdifFPrintAllNameValueNVT(self.this)
        
    def print_general_header(self):
        """ **Low-Level Interface** """
        cdef size_t n = SdifFPrintGeneralHeader(self.this)
        
    def print_all_ascii_chunks(self):
        """ **Low-Level Interface** """
        SdifFPrintAllASCIIChunks(self.this)
        
    def print_all_types(self):
        """ **Low-Level Interface** """
        SdifFPrintAllType(self.this)
        
    def print_matrix_header(self):
        """ **Low-Level Interface** """
        SdifFPrintMatrixHeader(self.this)
        
    def print_one_row(self):
        """ **Low-Level Interface** """
        SdifFPrintOneRow(self.this)
        
    def print_frame_header(self):
        """ **Low-Level Interface** """
        SdifFPrintFrameHeader(self.this)
        
    def print_all_stream_ID(self):
        """ **Low-Level Interface** """
        SdifFPrintAllStreamID(self.this)
    
    def frame_types_to_string(self):
        """
        returns a string with all frame types
        """
        cdef SdifStringT *sdifstr
        sdifstr = SdifStringNew()
        SdifFAllFrameTypeToSdifString(self.this, sdifstr)
        # out = PyString_from_SdifString(sdifstr)
        out = bytes_from_sdifstring(sdifstr).decode("ascii")
        SdifStringFree(sdifstr)
        return out
        
    def get_frame_types(self):
        """
        Returns a list of Frame Type Definitions (1FTD)

        Each FrameTypeDefinition is a FrameTypeDefinition(signature:bytes, components:list[Component])
        (a Component has the attributes signature:bytes, name:bytes, num:int)
        """
        return FrameTypesTable_to_list(self.this.FrameTypesTable)
        
    def matrix_types_to_string(self):
        """ 
        Returns a string with all matrix types

        Returns:
            (str) A string with all matrix types
        """
        cdef SdifStringT *sdifstr
        sdifstr = SdifStringNew()
        SdifFAllMatrixTypeToSdifString(self.this, sdifstr)
        out = bytes_from_sdifstring(sdifstr).decode("ascii")
        SdifStringFree(sdifstr)
        return out
        
    def get_matrix_types(self):
        """
        Get a list of matrix type definitions (1MTD)

        Returns:
            (list[str]) A list of matrix types, where each item is 
            a MatrixTypeDefinition
        """
        return MatrixTypesTable_to_list(self.this.MatrixTypesTable)
        
    def get_NVTs(self):
        """
        Return a list with all defined NameValueTables 
        
        Each NVT is converted to a python dict

        Returns:
            (list[dict[str, str]]) A list of NVTs, where each NVT is a
            dictionary with string keys and string values
        """
        return valuetables_to_dicts(self.this.NameValues)
        
    def get_stream_IDs(self):
        return streamidtable_to_list(self.this.StreamIDsTable)
    
            
