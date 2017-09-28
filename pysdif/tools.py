from ._pysdif import *
import os
import numpy 


def as_sdiffile(s):
    """
    s: a path to a sdif or a SdifFile, in which case a new SdifFile
       is opened with the original path.

    NB: the original sdif or SdifFile is not modified
    """
    if isinstance(s, SdifFile):
        if s.mode != "r":
            raise ValueError("This works only for readonly SdifFiles")
        return SdifFile(s.name)
    return SdifFile(s)


def convert_1TRC_to_RBEP(sdiffile, metadata=None):
    """
    Create a RBEP clone from this 1TRC file.
    """
    sdiffile = as_sdiffile(sdiffile)
    filename = sdiffile.name
    outfile = os.path.splitext(filename)[0] + "-RBEP.sdif"
    o = SdifFile(outfile, 'w', 'RBEP')
    if metadata is not None:
        _update_NVTs(sdiffile, outfile, metadata)

    def data_convert_1TRC_RBEP(d):
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
            empty_rows = numpy.zeros((num_rows, 2), dtype=d.dtype)
            out = numpy.hstack((d[:,:4], empty_rows))
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


def asbytes(s):
    if isinstance(s, bytes):
        return s
    elif isinstance(s, str):
        return s.encode("ascii")
    else:
        raise TypeError("s should be bytes or str")


def matrixtypes_for_predefined_frametype(sig):
    """
    Given a predefined frametype, return the matrix definitions
    included in the frame definition
    """
    components = predefined_frametypes_get(sig)
    if not components:
        raise KeyError("Frametype not found")
    matrixsignatures = {asbytes(component.split()[0]) for component in components}
    allmatrixtypes = predefined_matrixtypes()
    d = {matrixsig:allmatrixtypes.get(matrixsig) for matrixsig in matrixsignatures}
    return d


def predefined_frametypes_get(sig):
    return SDIF_PREDEFINEDTYPES['frametypes'].get(asbytes(sig))


def frametypes_used(sdiffile):
    """
    Find all the frametypes used in this sdiffile

    * sdiffile: the path to a sdif file
    * Returns:  a set of signatures. 

    NB: to find the components of a frame, do

    predefined_frametypes_get(signature)
    """
    f = as_sdiffile(sdiffile)
    signatures = set()
    for frame in f:
        if frame.signature not in signatures:
            signatures.add(frame.signature)
    return signatures


def add_type_definitions(infile, outfile, metadata=None):
    """
    Writes predefined types explicitely

    infile: the path to a .sdif file
    outfile: it can be the same as infile
    metadata: a dictionary with metadata to be added to
              the metadata already present

    Will add the type definitions to the file so that it can be read 
    without a modified SdifTypes.STYP 
    """
    # frametypes = frametypes_used(infile)
    # infile = SdifFile(infile)
    insdif = as_sdiffile(infile)
    definedFrametypes = {ftd.signature: ftd.components 
                         for ftd in insdif.get_frame_types()}
    frametypesUsed = frametypes_used(infile)
    undefinedFrameSignatures = {asbytes(sig) for sig in frametypesUsed 
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
            columns = globalMatrixtypes.get(asbytes(matrixsig))
            assert columns is not None
            matricesToBeAdded.append((matrixsig, columns))
    print(framesToBeAdded, matricesToBeAdded)
    outsdif = SdifFile(outfile, "w").clone_definitions(insdif)
    for frame in insdif:
        with outsdif.new_frame(frame.signature, frame.time) as outframe:
            for m in frame:
                outframe.add_matrix(m.signature, m.get_data(copy=True))
    outsdif.close()

    
def repair_RBEP(sdiffile, metadata=None):
    """
    add the type definitions to a RBEP file as written by, for example, loris
    in the same step you can update the metadata of the sdif file
    """
    assert SdifFile(sdiffile).signature == "RBEP"
    return add_type_definitions(sdiffile, metadata=metadata, inplace=True)

        
def write_metadata(sdif_filename, metadata={}, inplace=True):
    """
    produce a copy of the sdif file with the metadata given. if there was any metadata
    already defined in the source file, it will be overwritten.
    
    """
    suffix = "-M"
    insdif = SdifFile(sdif_filename)
    if not inplace:
        outsdif = SdifFile(os.path.splitext(sdif_filename)[0] + suffix + ".sdif", 'w')
    else:
        import tempfile
        outsdif = SdifFile(tempfile.mktemp(), 'w')
    outsdif.add_NVT(metadata)
    # and now, clone everything
    outsdif.clone_type_definitions(insdif)
    outsdif.clone_frames(insdif)
    infile = insdif.name
    outfile = outsdif.name
    outsdif.close()
    insdif.close()
    if inplace:
        os.remove(infile)
        os.rename(outfile, infile)

        
def update_metadata(sdiffile, metadata, inplace=True):
    """
    update the metadata of the given sdiffile. any name already present in 
    the original file with be updated with the new value, new names will
    be added. other name-value pairs will be left untouched.
    
    this is the same as the 'update' method in python:
    
    a = {...}
    a.update({...})
    
    NB: only the first NVT is taken into consideration, if present,
    other NVTs are passed untouched.
    
    """
    suffix = "-M"
    insdif = as_sdiffile(sdiffile)
    if not inplace:
        outsdif = SdifFile(os.path.splitext(sdif_filename)[0] + suffix + ".sdif", 'w')
    else:
        import tempfile
        outsdif = SdifFile(tempfile.mktemp(), 'w')
    _update_NVTs(insdif, outsdif, metadata)
    outsdif.clone_type_definitions(insdif)
    outsdif.clone_frames(insdif)
    infile = insdif.name
    outfile = outsdif.name
    outsdif.close()
    insdif.close()
    if inplace:
        os.remove(infile)
        os.rename(outfile, infile)

        
def get_metadata(sdiffile):
    """
    returns a python dict with the metadata defined in sdiffile
    """
    metadata = as_sdiffile(sdiffile).get_NVTs()
    if len(metadata) == 1:
        return metadata[0]
    return metadata

    
def get_signature(sdiffile):
    return as_sdiffile(sdiffile).signature

    
def _update_NVTs(insdif, outsdif, metadata):
    nvts = insdif.get_NVTs()
    nvts[0].update(metadata)
    for nvt in nvts: 
        outsdif.add_NVT(nvt)

        
def time_range(sdiffile):
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
    

def check_matrix_exists(sdiffile, frame_sig, matrix_sig):
    sdiffile = SdifFile(sdiffile)
    for frame in sdiffile:
        if frame.signature == frame_sig:
            for matrix in frame:
                if matrix.signature == matrix_sig:
                    return True
    return False        


