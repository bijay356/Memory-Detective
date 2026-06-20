import math
import wave
import struct

def generate_mi_bassline(filename, num_loops=8, sample_rate=44100):
    # Frequencies
    G2 = 98.00
    Bb2 = 116.54
    C3 = 130.81
    F2 = 87.31
    Fs2 = 92.50

    # Pattern: (freq, duration_sec, amplitude)
    beat = 0.35 # Slightly faster
    pattern1 = [
        (G2, beat * 1.5, 0.4),
        (0,  beat * 0.1, 0.0), # rest
        (G2, beat * 1.4, 0.4),
        (0,  beat * 0.1, 0.0),
        (Bb2, beat * 0.4, 0.5),
        (0,  beat * 0.1, 0.0),
        (C3,  beat * 0.4, 0.5),
        (0,  beat * 0.1, 0.0),
    ]
    pattern2 = [
        (G2, beat * 1.5, 0.4),
        (0,  beat * 0.1, 0.0), # rest
        (G2, beat * 1.4, 0.4),
        (0,  beat * 0.1, 0.0),
        (F2, beat * 0.4, 0.5),
        (0,  beat * 0.1, 0.0),
        (Fs2, beat * 0.4, 0.5),
        (0,  beat * 0.1, 0.0),
    ]

    sequence = (pattern1 + pattern2) * num_loops

    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        
        for freq, duration, amp in sequence:
            num_samples = int(duration * sample_rate)
            
            for i in range(num_samples):
                t = i / sample_rate
                
                if freq == 0:
                    mixed = 0
                else:
                    # Sawtooth-like wave with low pass feel
                    wave1 = math.sin(2 * math.pi * freq * t)
                    wave2 = math.sin(2 * math.pi * freq * 2 * t) * 0.5
                    wave3 = math.sin(2 * math.pi * freq * 3 * t) * 0.25
                    
                    mixed = (wave1 + wave2 + wave3) * amp
                    
                    # Simple attack/decay envelope
                    if t < 0.05:
                        mixed *= (t / 0.05) # Attack
                    elif t > duration - 0.05:
                        mixed *= ((duration - t) / 0.05) # Release
                
                value = int(mixed * 32767.0)
                wav_file.writeframes(struct.pack('<h', value))

if __name__ == '__main__':
    print("Generating M:I style background track...")
    generate_mi_bassline(r'd:\memory\assets\audio\bg.wav')
    print("Done!")
