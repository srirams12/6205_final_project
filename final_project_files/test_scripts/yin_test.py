import numpy as np
from scipy.signal import butter, lfilter, iirfilter
import matplotlib.pyplot as plt
from scipy.io import wavfile

import serial
import wave

def yin(signal, sample_rate, fmin=100, fmax=1000, threshold=0.1):
    """
    Estimate the fundamental frequency (F0) of a signal using the YIN algorithm.

    Parameters:
    - signal: numpy array, the input signal
    - sample_rate: int, the sampling rate of the signal
    - fmin: float, the minimum frequency to search (in Hz)
    - fmax: float, the maximum frequency to search (in Hz)
    - threshold: float, the threshold for the cumulative mean normalized difference

    Returns:
    - f0: float, the estimated fundamental frequency in Hz
    """
    
    # Step 1: Calculate the difference function
    def difference_function(signal, max_lag):
        diff = np.zeros(max_lag)
        for t in range(1, max_lag):
            diff[t] = np.sum((signal[:-t] - signal[t:]) ** 2)
        return diff

    # Step 2: Cumulative mean normalized difference function
    def cumulative_mean_normalized_difference(diff):
        cmndf = np.zeros(len(diff))
        cmndf[0] = 1
        for t in range(1, len(diff)):
            cmndf[t] = diff[t] / ((1 / t) * np.sum(diff[1:t+1])) if diff[t] != 0 else 1
        return cmndf

    # Convert fmin and fmax to lag values
    max_lag = int(sample_rate / fmin)
    min_lag = int(sample_rate / fmax)

    # Compute the difference function and the cumulative mean normalized difference
    diff = difference_function(signal, max_lag)
    cmndf = cumulative_mean_normalized_difference(diff)

    # Step 3: Apply absolute threshold
    below_threshold = np.where(cmndf[min_lag:] < threshold)[0]
    if len(below_threshold) == 0:
        return 0  # No F0 detected

    # Step 4: Find the first dip below the threshold
    lag = below_threshold[0] + min_lag

    # Step 5: Parabolic interpolation around the minimum
    if 1 <= lag < len(cmndf) - 1:
        better_lag = lag + (cmndf[lag - 1] - cmndf[lag + 1]) / (2 * (cmndf[lag - 1] - 2 * cmndf[lag] + cmndf[lag + 1]))
    else:
        better_lag = lag

    # Step 6: Convert lag to frequency
    f0 = sample_rate / better_lag if better_lag > 0 else 0
    return f0

def butter_bandpass(lowcut, highcut, fs, order):
    nyquist = 0.5 * fs
    low = lowcut / nyquist
    high = highcut / nyquist
    b, a = iirfilter(order, [low, high], btype='band', ftype='butter')
    print(f'{fs=}')
    print(f'{b=}{a=}')
    return b, a

def butter_bandpass_filter(data, lowcut, highcut, fs, order):
    b, a = butter_bandpass(lowcut, highcut, fs, order=order)
    y = lfilter(b, a, data)
    return y

def split_signal_into_windows(signal, window_size):
    num_windows = len(signal) // window_size
    return [signal[window_size * i : window_size * (i + 1)] for i in range(num_windows)]

if __name__ == "__main__":

    frequency = 300
    sample_rate = 16000
    amplitude = 127
    t = np.linspace(0, 1, sample_rate, endpoint=False)
    t = t[:1000]
    sine_wave = amplitude * (np.sin(2 * np.pi * frequency * t) + 1)

    sample_rate, signal = wavfile.read('/Users/sriram/Documents/digital_systems/final_project/final_project_files/songs/scale16khz.wav')
    # sample_rate = 50000
    print(f'{sample_rate=}')
    # signal = signal[:160000]

    # signal = sine_wave
    # sample_rate = 16000
    signal = butter_bandpass_filter(signal, 100, 1000, sample_rate, 1)
    plt.plot([i for i in range(1000)], signal[:1000])
    plt.show()

    print(type(signal))
    duration = len(signal)/sample_rate  # seconds
    window_size = 500 # samples

    t_signal = np.linspace(0, duration, int(sample_rate * duration), endpoint=False)
    t_f0 = np.linspace(0, duration, int(sample_rate * duration / window_size), endpoint=False)
    signal_samples = split_signal_into_windows(signal, window_size)
    
    # yin each of the windows and plot F0 as a function of time
    f0 = []
    for sample in signal_samples:
        f0.append(min(yin(sample, sample_rate), 700))
    
    # f0 = butter_bandpass_filter(f0, 100, 3999, 8000, 3)

    # Apply YIN algorithm
    estimated_f0 = yin(signal, sample_rate)
    print(f"Estimated F0 for entire signal: {estimated_f0:.2f} Hz")
    # print(f0)
    plt.plot(t_signal, signal)
    ax = plt.gca()
    # ax.set_xlim([0.125, .225])
    plt.show()

    

    plt.plot(t_f0, f0)
    plt.scatter([0.5,1,1.5,2,2.5,3,3.5,4,4.5,5],[650,650,650,650,650,650,650,650,650,650])
    ax = plt.gca()
    # ax.set_xlim([0.125, .225])
    plt.show()


  
'''
bandpass filter coefficients with butter_bandpass_filter(signal, 100, 1500, 8000, 7)
b=array([ 0.00230078,  0.        , -0.01610549,  0.        ,  0.04831647,
        0.        , -0.08052745,  0.        ,  0.08052745,  0.        ,
       -0.04831647,  0.        ,  0.01610549,  0.        , -0.00230078])
       
a=array([ 1.00000000e+00, -8.62037209e+00,  3.46184237e+01, -8.63742328e+01,
        1.50451653e+02, -1.94382488e+02,  1.92545626e+02, -1.48631723e+02,
        8.98218959e+01, -4.22721495e+01,  1.52428611e+01, -4.08007393e+00,
        7.65817755e-01, -9.02598878e-02,  5.02138817e-03])
'''