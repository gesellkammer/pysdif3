from __future__ import absolute_import

from ._pysdif import (
    SdifFile,
    predefined_frametypes,
    predefined_matrixtypes,
    Component,
    str2signature,
    signature2str,
    NoFrame,
    NoMatrix,
    SdifOrderError,
    MatrixTypeDefinition,
    FrameTypeDefinition,
    logger,
    sdif_init
)

from . import _pysdif
from . import tools

import atexit

@atexit.register
def _cleanup():
    _pysdif.sdif_cleanup()

del atexit 
del absolute_import

_pysdif.sdif_init()
