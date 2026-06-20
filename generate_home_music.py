import wave
import math
import struct

sample_rate = 44100
f = wave.open('d:/memory/assets/audio/home_bg.wav', 'w')
f.setnchannels(1)
f.setsampwidth(2)
f.setframerate(sample_rate)

bpm = 70
beat_duration = 60.0 / bpm

sequence = [
    ([110.0, 130.81, 164.81, 246.94], 4.0, 0.5),
    ([110.0, 130.81, 164.81, 246.94], 4.0, 0.5),
    ([87.31, 110.0, 130.81, 164.81], 4.0, 0.5),
    ([87.31, 110.0, 130.81, 164.81], 4.0, 0.5),
]

data = bytearray()
for _ in range(2):
    for freqs, beats, amp in sequence:
        samples_in_note = int(beat_duration * beats * sample_rate)
        for i in range(samples_in_note):
            t = i / sample_rate
            env = math.exp(-0.3 * t)
            
            val = 0
            for freq in freqs:
                val += math.sin(2 * math.pi * freq * t) * 0.6
                val += math.sin(2 * math.pi * freq * 2 * t) * 0.2
            
            val = (val / len(freqs)) * env * amp
            val += (math.sin(i * 1234.567) * 0.01) # gentle noise
            
            sample = int(max(-1.0, min(1.0, val)) * 32767)
            data.extend(struct.pack('<h', sample))

f.writeframes(data)
f.close()
