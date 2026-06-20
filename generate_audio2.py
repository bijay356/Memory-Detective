import math
import wave
import struct
import random

def generate_spy_bg(filename, duration_sec=30, sample_rate=44100):
    num_samples = duration_sec * sample_rate
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        
        for i in range(num_samples):
            t = i / sample_rate
            
            # Tense drone (A4 + slightly detuned A4)
            freq1 = 440.0
            freq2 = 444.0
            drone1 = math.sin(2 * math.pi * freq1 * t)
            drone2 = math.sin(2 * math.pi * freq2 * t)
            drone = (drone1 + drone2) * 0.1
            
            # Slow ominous pulse (LFO)
            lfo = math.sin(2 * math.pi * 0.2 * t) # 0.2 Hz
            drone *= (0.5 + 0.5 * lfo)
            
            # Ticking clock (every 1 second)
            tick_env = 0
            time_in_sec = t % 1.0
            if time_in_sec < 0.05:
                tick_env = math.exp(-time_in_sec * 100)
            
            # Tick sound: short burst of noise or high freq
            tick = (random.random() * 2 - 1) * tick_env * 0.3
            
            # Mix
            mixed = drone + tick
            
            # Master volume
            mixed *= 0.8
            
            # Clip and pack
            mixed = max(-1.0, min(1.0, mixed))
            value = int(mixed * 32767.0)
            wav_file.writeframes(struct.pack('<h', value))

if __name__ == '__main__':
    print("Generating spy background drone...")
    generate_spy_bg(r'd:\memory\assets\audio\bg.wav')
    print("Done!")
