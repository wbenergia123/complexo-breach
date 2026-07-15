import struct, sys, os
from PIL import Image

def read_spr(path):
    with open(path, 'rb') as f:
        data = f.read()
    ident, version, type_, texformat, boundingradius, width, height, numframes, beamlength, synctype = \
        struct.unpack('<4siiifiiifi', data[0:40])
    assert ident == b'IDSP', f"not a GoldSrc sprite: {ident}"
    offset = 40
    numcolors = struct.unpack('<H', data[offset:offset+2])[0]
    offset += 2
    palette = []
    for i in range(numcolors):
        r, g, b = data[offset], data[offset+1], data[offset+2]
        palette.append((r, g, b))
        offset += 3

    frames = []
    for i in range(numframes):
        group = struct.unpack('<i', data[offset:offset+4])[0]
        offset += 4
        if group != 0:
            # group frame: nof int, then nof floats (intervals), then nof simple-frame blocks
            nof = struct.unpack('<i', data[offset:offset+4])[0]
            offset += 4 + nof * 4  # skip intervals
            for _ in range(nof):
                ox, oy = struct.unpack('<ii', data[offset:offset+8]); offset += 8
                fw, fh = struct.unpack('<ii', data[offset:offset+8]); offset += 8
                pixels = data[offset:offset+fw*fh]; offset += fw*fh
                frames.append((ox, oy, fw, fh, pixels))
        else:
            ox, oy = struct.unpack('<ii', data[offset:offset+8]); offset += 8
            fw, fh = struct.unpack('<ii', data[offset:offset+8]); offset += 8
            pixels = data[offset:offset+fw*fh]; offset += fw*fh
            frames.append((ox, oy, fw, fh, pixels))
    return palette, frames, texformat, (width, height, numframes)

def frame_to_png(palette, frame, texformat, out_path):
    ox, oy, w, h, pixels = frame
    img = Image.new('RGBA', (w, h))
    px = img.load()
    for y in range(h):
        for x in range(w):
            idx = pixels[y*w + x]
            r, g, b = palette[idx]
            if texformat == 1:  # SPR_ADDITIVE: brightness = alpha, black = transparent
                a = max(r, g, b)
            elif idx == 255:  # SPR_NORMAL/ALPHATEST: last palette color = transparent key (common convention)
                a = 0
            else:
                a = 255
            px[x, y] = (r, g, b, a)
    img.save(out_path)
    return w, h

if __name__ == '__main__':
    src_dir = "/Users/willianbatista/Downloads/realistic-muzzle-flash/sprites/sprites"
    out_dir = "/private/tmp/claude-501/-Users-willianbatista/16552154-9b48-4c20-8eb1-47944160f429/scratchpad/spr_frames"
    os.makedirs(out_dir, exist_ok=True)
    for fname in ("muzzleflash1.spr", "muzzleflash2.spr", "muzzleflash3.spr"):
        path = os.path.join(src_dir, fname)
        palette, frames, texformat, meta = read_spr(path)
        print(f"{fname}: texformat={texformat} meta={meta} frames_found={len(frames)}")
        base = fname.replace('.spr', '')
        for i, fr in enumerate(frames):
            outp = os.path.join(out_dir, f"{base}_frame{i}.png")
            w, h = frame_to_png(palette, fr, texformat, outp)
            print(f"  frame{i}: {w}x{h} -> {outp}")
