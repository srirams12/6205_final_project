import wave
import sys

def wav_to_mem(wav_filename, mem_filename, bram_depth=1024, bram_width=8):
    """
    Converts a .wav file to a .mem file for FPGA BRAM initialization.

    Parameters:
        wav_filename (str): Path to the input .wav file.
        mem_filename (str): Path to the output .mem file.
        bram_depth (int): Depth of the BRAM (number of addresses).
        bram_width (int): Width of the BRAM word in bits.
    """
    try:
        # Open the .wav file
        with wave.open(wav_filename, "rb") as wav_file:
            # Validate .wav file parameters
            # assert wav_file.getnchannels() == 1, "WAV file must be mono (1 channel)."
            # assert wav_file.getsampwidth() == 1, "WAV file must have 8-bit samples."
            assert wav_file.getframerate() == 16000, "WAV file must have a 16 kHz sample rate."

            print(f"Processing {wav_filename}")
            nframes = wav_file.getnframes()

            # Read all audio frames
            frames = wav_file.readframes(nframes)

            # Ensure the number of frames does not exceed BRAM depth
            if nframes > bram_depth:
                print(f"Warning: WAV file contains more frames ({nframes}) than BRAM depth ({bram_depth}). Truncating.")
                frames = frames[:bram_depth]

            # Write frames to .mem file
            with open(mem_filename, "w") as mem_file:
                for i, sample in enumerate(frames):
                    mem_file.write(f"{sample:02X}\n")
                # Pad the .mem file if frames are less than BRAM depth
                for _ in range(bram_depth - len(frames)):
                    mem_file.write("00\n")

            print(f"Conversion complete. Data saved to {mem_filename}")

    except AssertionError as e:
        print(f"Error: {e}")
    except Exception as e:
        print(f"Unexpected error: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 wav_to_mem.py <input.wav> <output.mem>")
        exit()

    input_filename = sys.argv[1]
    output_filename = sys.argv[2]

    # Convert the WAV file to a MEM file
    wav_to_mem(input_filename, output_filename)
