from __future__ import annotations
from ._pysdif import *
import os
import numpy as np
from typing import Union as U, Dict, List, Tuple
import tempfile


def as_sdiffile(s: U[str, SdifFile]) -> SdifFile:
    """
    Args:
        s: a path to a sdif or a SdifFile, in which case a new SdifFile
           is opened with the original path.

    NB: the original sdif or SdifFile is not modified
    """
    if isinstance(s, SdifFile):
        if s.mode != "r":
            raise ValueError("This works only for readonly SdifFiles")
        return SdifFile(s.name)
    return SdifFile(s)


def convert_1TRC_to_RBEP(sdiffile: U[str, SdifFile], metadata:dict=None) -> None:
    """
    Create a RBEP clone from a 1TRC file.

    Args:
        sdiffile: a SdifFile or the path to a sdif file
        metadata: any metadata to add to the RBEP file

    """
    sdiffile = as_sdiffile(sdiffile)
    filename = sdiffile.name
    outfile = os.path.splitext(filename)[0] + "-RBEP.sdif"
    o = SdifFile(outfile, 'w', 'RBEP')
    if metadata is not None:
        _update_NVTs(sdiffile, outfile, metadata)

    def data_convert_1TRC_RBEP(d: np.array):
        # normally, 1TRC matrices have index, freq, amp, phase
        # but Spear, for example, add columns to the 1TRC definition to 
        # store time offset
        # According to the IRCAM people, this is actually the right thing 
        # to do, instead of defining a new frame and matrix type, 
        # extend the existing one with bandwidth and offset.
        # But Loris and the Loris UGens in Supercollider expect to read 
        # RBEP frames, so the discussion is only theoretical: 
        # those SDIF files exist out there and we want to
        # be able to read them.
        num_rows = len(d)
        if num_rows > 0:
            empty_rows = np.zeros((num_rows, 2), dtype=d.dtype)
            out = np.hstack((d[:,:4], empty_rows))
            if not out.flags.contiguous:
                out = out.copy()
            return out
        return d    # an empty array
    for frame0 in sdiffile:
        if frame0.signature == '1TRC':
            frame1 = o.new_frame("RBEP", frame0.time)
            data = frame0.get_matrix_data()
            new_data = data_convert_1TRC_RBEP(data)
            frame1.add_matrix("RBEP", new_data)
            frame1.write()
    o.close()


def _asbytes(s: U[bytes, str]) -> bytes:
    if isinstance(s, bytes):
        return s
    elif isinstance(s, str):
        return s.encode("ascii")
    else:
        raise TypeError("s should be bytes or str")


def matrixtypes_for_predefined_frametype(sig: str) -> Dict[str, List[str]]:
    """
    Given a predefined frametype, return a list of matrix definitions
    included in the frame definition

    Args:
        sig: the signature, a 4-byte string

    Returns:
        the matrix definitions possible within the given frame
    """
    components = _predefined_frametypes_get(sig)
    if not components:
        raise KeyError("Frametype not found")
    matrixsignatures = {_asbytes(component.split()[0]) for component in components}
    allmatrixtypes = predefined_matrixtypes()
    d = {matrixsig:allmatrixtypes.get(matrixsig) for matrixsig in matrixsignatures}
    return d


def _predefined_frametypes_get(sig: str):
    return SDIF_PREDEFINEDTYPES['frametypes'].get(_asbytes(sig))


def frametypes_used(sdiffile: str) -> Set[str]:
    """
    Find all the frametypes used in this sdiffile

    Args:
        sdiffile (str): the path to a sdif file

    Returns:
        the set of frame signatures present in the given file

    """
    f = as_sdiffile(sdiffile)
    signatures = set()
    for frame in f:
        if frame.signature not in signatures:
            signatures.add(frame.signature)
    return signatures


def add_type_definitions(infile: str, outfile: str, metadata: Dict[str, str]=None
                         ) -> None:
    """
    Writes predefined types explicitely

    Args:
        infile: the path to a .sdif file
        outfile: it can be the same as infile
        metadata: a dictionary with metadata to be added to the metadata already present

    Will add the type definitions to the file so that it can be read without a 
    modified `SdifTypes.STYP` 
    """
    insdif = as_sdiffile(infile)
    definedFrametypes = {ftd.signature: ftd.components 
                         for ftd in insdif.get_frame_types()}
    frametypesUsed = frametypes_used(infile)
    undefinedFrameSignatures = {_asbytes(sig) for sig in frametypesUsed 
                                if sig not in definedFrametypes}
    globalFrametypes = predefined_frametypes()
    globalMatrixtypes = predefined_matrixtypes()
    matricesToBeAdded = []
    framesToBeAdded = []
    for framesig in undefinedFrameSignatures:
        components = globalFrametypes.get(framesig)
        framesToBeAdded.append((framesig, components))
        if not components:
            raise KeyError("Frame {sig} is not explicitely defined and is was not"
                           "found in the predefined types".format(sig=framesig))
        for componentstr in components:
            matrixsig, descr = componenstr.split()
            columns = globalMatrixtypes.get(_asbytes(matrixsig))
            assert columns is not None
            matricesToBeAdded.append((matrixsig, columns))
    print(framesToBeAdded, matricesToBeAdded)
    outsdif = SdifFile(outfile, "w").clone_definitions(insdif)
    for frame in insdif:
        with outsdif.new_frame(frame.signature, frame.time) as outframe:
            for m in frame:
                outframe.add_matrix(m.signature, m.get_data(copy=True))
    outsdif.close()

    
def repair_RBEP(sdiffile: str, metadata:Dict[str, str]=None) -> None:
    """
    Add the type definitions to a RBEP file

    Some libraries (loris, for example), use RBEP frame types/matrix types 
    without including the definition in the sdif file. This function
    clones a given sdif file and ensures that it has all needed 
    definitions
    """
    assert SdifFile(sdiffile).signature == "RBEP"
    return add_type_definitions(sdiffile, metadata=metadata, inplace=True)

        
def write_metadata(sdif_filename: str, metadata:Dict[str, str], outfile: str=None 
                   ) -> None:
    """
    Add metadata to a sdif file

    Produce a copy of the sdif file with the metadata given. If there was any 
    metadata already defined in the source file, it will be overwritten.
    If no outfile is given, the sdif file is modified in place

    Args:
        sdif_filename: the filename of the source sdif file
        outfile: the outfile to generate, or None to modify the source file in place
        matadata: the metadata to add
    
    """
    if outfile is None:
        inplace = True
        outfile = tempfile.mktemp(suffix=".sdif")
    else:
        inplace = False

    insdif = SdifFile(sdif_filename)
    outsdif = SdifFile(outfile, "w")
    outsdif.add_NVT(metadata)
    outsdif.clone_type_definitions(insdif)
    outsdif.clone_frames(insdif)
    outsdif.close()
    insdif.close()
    if inplace:
        os.remove(infile)
        os.rename(outfile, sdif_filename)

        
def update_metadata(sdiffile: str, metadata: Dict[str, str], outfile: str=None):
    """
    Update the metadata of the given sdiffile. 

    Any key already present in the original file will be updated with the 
    new value, new keys will be added. Other key: value pairs will be left 
    untouched.
    
    !!! note 

        Only the first NVT is taken into consideration. Other NVTs, if present,
        are left untouched.
    
    """
    if outfile is None:
        inplace = True
        outfile = tempfile.mktemp(suffix=".sdif")
    else:
        inplace = False

    insdif = SdifFile(sdif_filename)
    outsdif = SdifFile(outfile, "w")
    _update_NVTs(insdif, outsdif, metadata)
    outsdif.clone_type_definitions(insdif)
    outsdif.clone_frames(insdif)
    outsdif.close()
    insdif.close()
    if inplace:
        os.remove(infile)
        os.rename(outfile, sdif_filename)

    
def _update_NVTs(insdif, outsdif, metadata):
    nvts = insdif.get_NVTs()
    nvts[0].update(metadata)
    for nvt in nvts: 
        outsdif.add_NVT(nvt)

        
def time_range(sdiffile: str) -> Tuple[float, float]:
    """
    Returns the first and last times of all frames in this sdiffile
    """
    f = as_sdiffile(sdiffile)
    f.rewind()
    frame = next(f)
    t0 = frame.time
    for frame in f:
        pass
    t1 = frame.time
    return t0, t1
    

def check_matrix_exists(sdiffile: str, frame_sig: str, matrix_sig: str) -> bool:
    sdiffile = SdifFile(sdiffile)
    for frame in sdiffile:
        if frame.signature == frame_sig:
            for matrix in frame:
                if matrix.signature == matrix_sig:
                    return True
    return False        


