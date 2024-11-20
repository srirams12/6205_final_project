import numpy as np
from scipy.signal import butter, lfilter, iirfilter
import matplotlib.pyplot as plt
from scipy.io import wavfile

import serial
import wave


# opens serial port, waits for 6 seconds of 8kHz audio data, writes it to output.wav

# set to proper serial port name and WAV!
# find the port name using test_ports.py
# CHANGE ME


def yin(signal, sample_rate, fmin=50, fmax=1500, threshold=0.1):
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
    print(f'{b=}{a=}')
    return b, a

def butter_bandpass_filter(data, lowcut, highcut, fs, order):
    b, a = butter_bandpass(lowcut, highcut, fs, order=order)
    y = lfilter(b, a, data)
    return y

def split_signal_into_windows(signal, window_size):
    num_windows = len(signal) // window_size
    return [signal[window_size * i : window_size * (i + 1)] for i in range(num_windows)]

def run_live():
    plt.ion()
    fig, ax = plt.subplots()
    line, = ax.plot([i for i in range(100)], np.zeros(100))  # Initialize with zeros
    ax.set_ylim(0, 1000)
    ax.set_xlim(0, 100)
    ax.set_xlabel('Time (s)')
    ax.set_ylabel('Amplitude')

    SERIAL_PORT_NAME = "/dev/cu.usbserial-8874042402F51"
    BAUD_RATE = 115200

    WINDOW = 600

    ser = serial.Serial(SERIAL_PORT_NAME,BAUD_RATE)
    print("Serial port initialized")

    print("Starting recording")
    ypoints = np.array([])
    freqs = []
    i = 0
    while True:
        val = int.from_bytes(ser.read(),'little')
        # print(len(ypoints))

        ypoints = np.append(ypoints, val)
        if len(ypoints) > WINDOW:
            ypoints = ypoints[1:]
            if ((i+1)%(WINDOW//3)==0):
                filtered = butter_bandpass_filter(ypoints, 10000, 20000, 8000, 7)
                new_freq = yin(filtered, 8000)
                if len(freqs) > 1:
                    # freqs.append(new_freq * .5 + freqs[-1] * .3 + freqs[-2] * .2)
                    if new_freq < 100:
                        freqs.append(freqs[-1])
                    elif abs(new_freq - freqs[-1]) > 50:
                        freqs.append(new_freq * .2 + freqs[-1] * .8)
                    else:
                        freqs.append(new_freq)
                else:
                    freqs.append(new_freq)
                if len(freqs) > 100:
                    freqs = freqs[1:]
                if len(freqs) == 100:
                    print('asdf')
                    line.set_ydata(freqs)
                    fig.canvas.draw()
                    fig.canvas.flush_events()
                print(new_freq)
                
        i = i + 1
        # print(i)

# run_live()

# Example usage
if __name__ == "__main__":
    sample_rate, signal = wavfile.read('c_sing.wav')
    _, noise = wavfile.read('noise.wav')

    # signal = np.subtract(signal, noise)
    signal = butter_bandpass_filter(signal, 100, 1500, 8000, 7)
    # for i in range(10000, 10100):
    #     print(signal[i])
    duration = len(signal)/sample_rate  # seconds
    window_size = 500 # samples

    t_signal = np.linspace(0, duration, int(sample_rate * duration), endpoint=False)
    t_f0 = np.linspace(0, duration, int(sample_rate * duration / window_size), endpoint=False)
    signal_samples = split_signal_into_windows(signal, window_size)
    
    # yin each of the windows and plot F0 as a function of time
    f0 = []
    for sample in signal_samples:
        f0.append(min(yin(sample, sample_rate), 700))

    # Apply YIN algorithm
    estimated_f0 = yin(signal, sample_rate)
    print(f"Estimated F0 for entire signal: {estimated_f0:.2f} Hz")
    # print(f0)
    plt.plot(t_signal, signal)
    ax = plt.gca()
    # ax.set_xlim([0.125, .225])
    plt.show()

    

    plt.plot(t_f0, f0)
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