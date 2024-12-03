import numpy as np
from scipy.io import wavfile
import matplotlib.pyplot as plt
import numpy as np

from yin_test import yin

sample_rate, signal = wavfile.read('/Users/sriram/Documents/digital_systems/final_project/test_scripts/c_sing.wav')

def decimal_to_fixed_point_hex(decimal_number):
    """
    Converts a decimal number to a 32-bit fixed-point hexadecimal representation.
    Handles signed numbers by properly accounting for two's complement.

    :param decimal_number: Decimal number to convert.
    :return: 8-character hexadecimal string.
    """
    # Multiply by 2^16 to scale the number (16 fractional bits)
    scaled_value = int(decimal_number * (2 ** 16))
    
    # Ensure the value fits in signed 32 bits (handle negative numbers correctly)
    if scaled_value < 0:
        # Convert to two's complement representation for negative numbers
        fixed_point_value = (scaled_value + (1 << 32)) & 0xFFFFFFFF
    else:
        fixed_point_value = scaled_value & 0xFFFFFFFF  # Mask to 32 bits
    
    # Convert to hexadecimal (without '0x' prefix)
    hex_value = hex(fixed_point_value)[2:].zfill(8)  # 8 hex digits (32 bits)
    
    return hex_value
'''7th order'''
# b=[ 0.00230078,  0.        , -0.01610549,  0.        ,  0.04831647,
#         0.        , -0.08052745,  0.        ,  0.08052745,  0.        ,
#        -0.04831647,  0.        ,  0.01610549,  0.        , -0.00230078]     
# a=[ 1.00000000e+00, -8.62037209e+00,  3.46184237e+01, -8.63742328e+01,
#         1.50451653e+02, -1.94382488e+02,  1.92545626e+02, -1.48631723e+02,
#         8.98218959e+01, -4.22721495e+01,  1.52428611e+01, -4.08007393e+00,
#         7.65817755e-01, -9.02598878e-02,  5.02138817e-03]

'''6th order'''
# b=[ 0.00061982,  0.        , -0.00371892,  0.        ,  0.0092973 ,
#         0.        , -0.01239641,  0.        ,  0.0092973 ,  0.        ,
#        -0.00371892,  0.        ,  0.00061982]
# a=[ 1.00000000e+00, -8.98154179e+00,  3.72467446e+01, -9.44470387e+01,
#         1.63287720e+02, -2.02946951e+02,  1.86030698e+02, -1.26748678e+02,
#         6.37100333e+01, -2.30396155e+01,  5.68949517e+00, -8.61309766e-01,
#         6.04442988e-02]

'''5th order'''
# b=[ 0.00211167,  0.        , -0.01055837,  0.        ,  0.02111673,
#         0.        , -0.02111673,  0.        ,  0.01055837,  0.        ,
#        -0.00211167]
# a=[  1.        ,  -7.47720181,  25.38201249, -51.63048255,
#         69.8176229 , -65.65256167,  43.4962858 , -20.04826803,
#          6.15172796,  -1.13461586,   0.09548109]

'''3rd order'''
b=[ 0.02437105,  0.        , -0.07311316,  0.        ,  0.07311316,
        0.        , -0.02437105]
a=[ 1.        , -4.4614112 ,  8.40866782, -8.64817056,  5.15417372,
       -1.68812945,  0.23499724]


# b = [0.5, 0.5]  # Feedforward coefficients (numerator)
# a = [1.0, -0.25]  # Feedback coefficients (denominator)


def iir_filter(x, b, a):
    """
    Apply an IIR filter to the input signal `x` with feedforward coefficients `b`
    and feedback coefficients `a`.
    
    :param x: Input signal (array of floats).
    :param b: Feedforward coefficients (list or array).
    :param a: Feedback coefficients (list or array).
    :return: Filtered output signal.
    """
    # Length of the input signal
    N = len(x)
    # Initialize the output signal and history of inputs and outputs
    y = np.zeros(N)
    x_history = np.zeros(len(b)-1)  # Input history
    y_history = np.zeros(len(a)-1)  # Output history
    
    # Iterate through the input signal
    for n in range(N):
        # Calculate the output using the IIR equation
        output = b[0]*x[n] + np.dot(b[1:], x_history) - np.dot(a[1:], y_history)  # a[0] is assumed to be 1, no need to multiply
        
        if n == 6:
            print(f'{b[0]*x[n] + b[1]*x_history[0] - a[1]*y_history[0] + b[2]*x_history[1] - a[2]*y_history[1] + b[3]*x_history[2] - a[3]*y_history[2] + b[4]*x_history[3] - a[4]*y_history[3] + b[5]*x_history[4] - a[5]*y_history[4]=}')
            print(f'{x_history=}')
            print(f'{y_history=}')

        # Update output history
        y_history[1:] = y_history[:-1]
        y_history[0] = output

        x_history[1:] = x_history[:-1]
        x_history[0] = x[n]


        
        # Store the output signal
        y[n] = output
    
    return y

step = [127]
for i in range(255):
    step.append(255)

output = iir_filter(signal, b, a)
print(f'{output[:10]=}')

# yinned = yin(output[10000:10500],8000)
# print(f'{yinned=}')

plt.plot([i for i in range(len(signal))], signal)
plt.show()
plt.plot([i for i in range(len(output))], output)
plt.show()

for i in range(len(a)):
    print(f'a[{i}] = 32\'h{decimal_to_fixed_point_hex(a[i])};')
for i in range(len(b)):
    print(f'b[{i}] = 32\'h{decimal_to_fixed_point_hex(b[i])};')