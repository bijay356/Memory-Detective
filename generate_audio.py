import math
import wave
import struct
import random

def generate_bg_music(filename, duration_sec, sample_rate=44100):
    num_samples = duration_sec * sample_rate
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        
        for i in range(num_samples):
            t = i / sample_rate
            
            # Base drone at 65 Hz (C2)
            base_freq = 65.0
            
            # Slow LFO modulating the amplitude and slightly the frequency
            lfo1 = math.sin(2 * math.pi * 0.1 * t) # 0.1 Hz
            lfo2 = math.sin(2 * math.pi * 0.05 * t) # 0.05 Hz
            
            freq = base_freq + (lfo2 * 2.0)
            
            # Sub-bass drone
            sample1 = math.sin(2 * math.pi * freq * t)
            
            # Minor third harmonic for eerie feel (C -> Eb)
            sample2 = math.sin(2 * math.pi * (freq * 1.189) * t) * 0.3
            
            # Fifth harmonic (G)
            sample3 = math.sin(2 * math.pi * (freq * 1.498) * t) * 0.2
            
            # A bit of low-passed noise
            noise = (random.random() * 2 - 1) * 0.05
            
            # Mix
            mixed = sample1 + sample2 + sample3 + noise
            
            # Envelopes
            envelope = 1.0
            if t < 2.0:
                envelope = t / 2.0 # Fade in
            elif t > duration_sec - 2.0:
                envelope = (duration_sec - t) / 2.0 # Fade out
                
            mixed = mixed * envelope * 0.4 * (0.8 + 0.2 * lfo1)
            
            # Clip and pack
            mixed = max(-1.0, min(1.0, mixed))
            value = int(mixed * 32767.0)
            wav_file.writeframes(struct.pack('<h', value))

def generate_click(filename, sample_rate=44100):
    duration_sec = 0.05 # very short click
    num_samples = int(duration_sec * sample_rate)
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        
        for i in range(num_samples):
            t = i / sample_rate
            
            # High pitched pop
            freq = 1500.0 * math.exp(-t * 50) # pitch envelope
            
            sample = math.sin(2 * math.pi * freq * t)
            
            # Fast amplitude decay
            envelope = math.exp(-t * 100)
            
            mixed = sample * envelope * 0.5
            
            mixed = max(-1.0, min(1.0, mixed))
            value = int(mixed * 32767.0)
            wav_file.writeframes(struct.pack('<h', value))

if __name__ == '__main__':
    print("Generating bg.wav (mysterious drone)...")
    generate_bg_music(r'd:\memory\assets\audio\bg.wav', 30) # 30 seconds loop
    print("Generating click.wav...")
    generate_click(r'd:\memory\assets\audio\click.wav')
    print("Done!")
