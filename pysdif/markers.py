from .tools import check_matrix_exists
from ._pysdif import SdifFile


class Marker(object):
    __slots__ = ('begin', 'end', 'data', 'type', 'id')

    def __init__(self, marker_type, begin, end, data, marker_id=None):
        self.type = marker_type
        self.begin = begin
        self.end = end
        self.data = data
        self.id = marker_id

    def __repr__(self):
        return "%s <%f, %f>" % (self.type, self.begin, self.end)

    def __getitem__(self, i):
        if i == 0:
            return self.begin
        elif i == 1:
            return self.end
        else:
            raise IndexError

    def __iter__(self):
        return (self.begin, self.end)


class TransientMarker(Marker):
    def __init__(self, begin, end, data):
        Marker.__init__(self, 'transient', begin, end, data)
        

class MarkerNoWidth(Marker):
    def __init__(self, marker_type, time, data):
        Marker.__init__(self, marker_type, time, time, data)
    
    def __repr__(self):
        return "%s <%f>" % (self.marker_type, self.begin)


class SpectralPosDiffMarker(MarkerNoWidth):
    def __init__(self, time, data):
        MarkerNoWidth.__init__(self, 'spectraldif+', time, data)
        

class SpectralNegDiffMarker(MarkerNoWidth):
    def __init__(self, time, data):
        MarkerNoWidth.__init__(self, 'spectraldif-', time, data)
        
                    
def read_transient_markers(sdiffile):
    if not check_matrix_exists(sdiffile, '1MRK', 'XTRD'):
        raise ValueError("no transient values found in this file")
    markers = []
    for frame in SdifFile(sdiffile):
        if frame.signature == '1MRK':
            for matrix in frame:
                if matrix.signature == '1BEG':
                    t0 = frame.time
                    index0 = matrix.get_data()[0]
                elif matrix.signature == 'XTRD':
                    values = matrix.get_data()[0].copy()
                elif matrix.signature == '1END':
                    index1 = matrix.get_data()[0, 0]
                    assert index1 == index0
                    markers.append(TransientMarker(t0, frame.time, values))
    return markers