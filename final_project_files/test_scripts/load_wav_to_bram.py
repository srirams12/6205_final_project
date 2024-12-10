import wave
import numpy as np
from scipy.io import wavfile
import matplotlib.pyplot as plt


# # Read the generated tones from the .wav file
# def load_wav_to_bram(wav_filename, bram_depth=8000):
#     with wave.open(wav_filename, "rb") as wav_file:
#         assert wav_file.getnchannels() == 1, "WAV file must be mono (1 channel)."
#         assert wav_file.getsampwidth() == 2, "WAV file must have 16-bit samples."
#         assert wav_file.getframerate() == 16000, "WAV file must have a 16 kHz sample rate."

#         nframes = wav_file.getnframes()
#         print(f"Total frames in WAV file: {nframes}")
        
#         # Read all frames and truncate or pad to bram_depth
#         raw_frames = np.frombuffer(wav_file.readframes(nframes), dtype=np.int16)
#         if len(raw_frames) > bram_depth:
#             print(f"Truncating to {bram_depth} samples.")
#             raw_frames = raw_frames[:bram_depth]
#         else:
#             print(f"Padding to {bram_depth} samples.")
#             raw_frames = np.pad(raw_frames, (0, bram_depth - len(raw_frames)), mode='constant', constant_values=0)

#         # Simulate BRAM assignment
#         bram = raw_frames.tolist()
#         for i in range(len(bram)):
#             print(f"bram[{i}] = {bram[i]}")
#         return bram

# # Example usage
# bram = load_wav_to_bram("tones.wav", bram_depth=8000)

sample_rate, signal = wavfile.read('/Users/sriram/Documents/digital_systems/final_project/final_project_files/test_scripts/tones.wav')
with open('input.mem', 'w') as f:
    for i in range(len(signal)):
        # print(f"bram[{i}] = {signal[i]};")
        # f.write(f"bram[{i}] = {signal[i]};\n")
        f.write(f'{hex(signal[i])[2:]}\n')

plt.plot([int(i) for i in signal[132000:132500]])
# plt.plot(signal)

plt.show()
