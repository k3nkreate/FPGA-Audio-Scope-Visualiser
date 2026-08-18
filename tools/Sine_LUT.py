import math

# Generate a 256-entry sine wave MIF file
# Values scaled from 0 to 255 (unsigned 8-bit)

DEPTH = 256   # number of entries
WIDTH = 8     # bits per entry

with open("sine_lut.mif", "w") as f:
    f.write(f"DEPTH = {DEPTH};\n")
    f.write(f"WIDTH = {WIDTH};\n")
    f.write("ADDRESS_RADIX = UNS;\n")   # addresses in decimal
    f.write("DATA_RADIX = UNS;\n")       # values in decimal
    f.write("CONTENT BEGIN\n")
    
    for i in range(DEPTH):
        angle = (2 * math.pi * i) / DEPTH          # 0 to 2π
        value = int(127.5 + 127.5 * math.sin(angle)) # scale to 0–255
        value = max(0, min(255, value))              # clamp to valid range
        f.write(f"  {i} : {value};\n")
    
    f.write("END;\n")

print("sine_lut.mif generated — 256 entries, 8-bit, unsigned")