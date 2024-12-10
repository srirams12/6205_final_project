import numpy as np
import wave
import struct
import matplotlib.pyplot as plt
def generate_wav_from_frequencies(frequencies, duration=0.5, sample_rate=16000, output_filename="output.wav"):
    """
    Generates a .wav file from a list of frequencies.

    Parameters:
        frequencies (list): List of frequencies (Hz) to generate tones for.
        duration (float): Duration (seconds) of each tone. Default is 0.5 seconds.
        sample_rate (int): Sampling rate in Hz. Default is 16,000 Hz.
        output_filename (str): Name of the output .wav file.
    """
    amplitude = 127  # Maximum amplitude for 16-bit audio
    total_samples = int(duration * sample_rate)
    
    # Create a list to hold all samples
    all_samples = []

    for freq in frequencies:
        t = np.linspace(0, duration, total_samples, endpoint=False)  # Time vector
        wave_samples =  (amplitude * np.sin(2 * np.pi * freq * t) + amplitude).astype(np.uint8)  # Generate sine wave
        # print(min(t))
        # print(f'{min(wave_samples)=}')
        # plt.plot(t[:100], wave_samples[:100])
        # plt.show()
        all_samples.extend(wave_samples)

    # Convert to bytes
    all_samples = np.array(all_samples, dtype=np.uint8)
    with wave.open(output_filename, 'wb') as wav_file:
        # Set parameters: 1 channel, 2 bytes per sample, sample rate, number of frames
        wav_file.setnchannels(1)  # Mono audio
        wav_file.setsampwidth(1)  # 16-bit audio
        wav_file.setframerate(sample_rate)
        wav_file.writeframes(all_samples.tobytes())

    print(f"WAV file generated: {output_filename}")

if __name__ == "__main__":
    # Example: List of frequencies
    # frequencies = [440, 554, 659, 880]  # A4, C#5, E5, A5
    frequencies = [
    392.00,  # G4
    261.63,  # C4
    261.63,  # C4
    311.13,  # Eb4
    392.00,  # G4
    392.00,  # G4
    392.00,  # G4
    392.00,  # G4
    415.30,  # Ab4
    349.23,  # F4
    349.23,  # F4
    415.30,  # Ab4
    523.25,  # C5
    523.25,  # C5
    392.00,  # G4
    392.00,  # G4
    261.63,  # C4
    261.63,  # C4
    261.63,  # C4
    311.13,  # Eb4
    392.00,  # G4
    392.00,  # G4
    392.00,  # G4
    392.00,  # G4
    349.23,  # F4
    349.23,  # F4
    311.13,  # Eb4
    293.66,  # D4
    261.63   # C4
]
    
    for i in range(len(frequencies)):
        print(f'song_note_frequencies[{i}] = {int(frequencies[i]+3)};')

    # frequencies = [
    #     262,
    #     294,
    #     329,
    #     349,
    #     392,
    #     440,
    #     493,
    #     523
    # ]
    # generate_wav_from_frequencies(frequencies, duration=0.5, sample_rate=16000, output_filename="tones_scale.wav")
