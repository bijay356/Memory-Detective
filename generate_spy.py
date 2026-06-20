import wave
import math
import struct

sample_rate = 44100

f = wave.open('d:/memory/assets/audio/spy_bg.wav', 'w')
f.setnchannels(1)
f.setsampwidth(2)
f.setframerate(sample_rate)

bpm = 110
beat_duration = 60.0 / bpm

sequence = [
    (82.41, 1.0, 0.8),
    (82.41, 1.0, 0.8),
    (98.00, 0.5, 0.8),
    (82.41, 1.5, 0.8),
    
    (103.83, 1.0, 0.8),
    (103.83, 1.0, 0.8),
    (98.00, 0.5, 0.8),
    (82.41, 1.5, 0.8),
]

data = bytearray()
for freq, beats, amp in sequence * 4:
    samples_in_note = int(beat_duration * beats * sample_rate)
    for i in range(samples_in_note):
        t = i / sample_rate
        env = math.exp(-2.0 * t)
        val = math.sin(2 * math.pi * freq * t) + 0.3 * math.sin(2 * math.pi * freq * 2 * t)
        val = val * env * amp * 0.8
        
        if (i % int(beat_duration * sample_rate)) < 500:
            val += (math.sin(i * 300) * 0.05) * math.exp(-20.0 * (i % int(beat_duration * sample_rate)) / sample_rate)
            
        sample = int(max(-1.0, min(1.0, val)) * 32767)
        data.extend(struct.pack('<h', sample))

f.writeframes(data)
f.close()
