import math
import wave
import struct

def generate_pad(filename, freq, duration_sec=0.5, sample_rate=44100):
    num_samples = int(duration_sec * sample_rate)
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        
        for i in range(num_samples):
            t = i / sample_rate
            
            # FM Synthesis for a "synth bell" or "glassy" tone
            modulator = math.sin(2 * math.pi * (freq * 2.0) * t) * 1.5
            carrier = math.sin(2 * math.pi * freq * t + modulator)
            
            # Envelope (fast attack, exponential decay)
            envelope = math.exp(-t * 6.0)
            
            mixed = carrier * envelope * 0.5
            mixed = max(-1.0, min(1.0, mixed))
            value = int(mixed * 32767.0)
            wav_file.writeframes(struct.pack('<h', value))

if __name__ == '__main__':
    print("Generating instrument pads...")
    # C major 7th chord: C5, E5, G5, B5
    freqs = [523.25, 659.25, 783.99, 987.77]
    for i, freq in enumerate(freqs):
        generate_pad(rf'd:\memory\assets\audio\pad_{i}.wav', freq)
    print("Done!")
