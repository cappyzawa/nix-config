#!/usr/bin/env python3
"""Create a solid color PNG and set it as wallpaper."""
import struct
import zlib
import subprocess
import sys

def create_solid_png(r, g, b, path):
    """Create a 1x1 pixel PNG with the given RGB color."""
    def make_chunk(chunk_type, data):
        chunk_data = chunk_type + data
        crc = zlib.crc32(chunk_data) & 0xffffffff
        return struct.pack('>I', len(data)) + chunk_data + struct.pack('>I', crc)

    with open(path, 'wb') as f:
        # PNG signature
        f.write(b'\x89PNG\r\n\x1a\n')
        # IHDR chunk: width=1, height=1, bit_depth=8, color_type=2 (RGB)
        ihdr_data = struct.pack('>IIBBBBB', 1, 1, 8, 2, 0, 0, 0)
        f.write(make_chunk(b'IHDR', ihdr_data))
        # IDAT chunk: compressed image data
        raw_data = struct.pack('BBBB', 0, r, g, b)  # filter byte + RGB
        idat_data = zlib.compress(raw_data, 9)
        f.write(make_chunk(b'IDAT', idat_data))
        # IEND chunk
        f.write(make_chunk(b'IEND', b''))

def set_wallpaper(path):
    """Set the wallpaper using osascript."""
    script = f'tell application "System Events" to tell every desktop to set picture to "{path}"'
    subprocess.run(['/usr/bin/osascript', '-e', script], check=True)

if __name__ == '__main__':
    # akari-night background color: #25231F
    png_path = '/tmp/akari-wallpaper.png'
    create_solid_png(0x25, 0x23, 0x1F, png_path)
    set_wallpaper(png_path)
    print(f'Wallpaper set to {png_path}')
