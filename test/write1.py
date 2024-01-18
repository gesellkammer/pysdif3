from pysdif import *
import numpy as np
logger.setLevel("DEBUG")


sdifile = SdifFile("write1.sdif", "w")
sdifile.add_NVT({"creator": "Olive"})
sdifile.add_NVT({"Force_fcmax": "No", "MarkBeta": "0.050000", "MarkGamma": "5.000000", "VoiceThreshold": "0.600000", "TransThreshold": "0.200000", "MarkAlpha": "4.000000", "External_f0": "No", "f0_fmin": "50.000000", "f0_fmax": "1000.000000", "MethodEpocs": "ener", "LpcOrder": "None"})
sdifile.add_matrix_type('ITDS',"SamplingRate")
sdifile.add_matrix_type('1PSO',"Position, Fundamentalfrequency, VoicingFlag, VoicingCoefficient, VoicingCuttingFrequency, Periods, Mod, TransitoireFlag")
sdifile.add_frame_type("1PSO", ["1PSO PSOLA", "ITDS sr"])

times = [0, 0.1, 0.2, 0.3]
pitches = [0, 10, 20, 30]
harmonic_rates = [0, 0.01, 0.02, 0.03]
argmins = [0, 1, 2, 3]
sr = 44100

for i, offset in enumerate(times):
	frame = sdifile.new_frame("1PSO", offset)
	frame.add_matrix("ITDS", np.array([[float(sr)]]))
	frame.add_matrix("1PSO", np.array([[pitches[i], harmonic_rates[i], argmins[i], 0., 0., 0., 0., 0.]]))
	frame.write()
sdifile.close()

