#!/usr/bin/env python3
"""Customize a trusted, locally built ANLegacy IPA before signing."""
import argparse
import plistlib
import re
import zipfile
from io import BytesIO
from pathlib import Path

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("input", type=Path)
    p.add_argument("output", type=Path)
    p.add_argument("--name", default="ANLegacy")
    p.add_argument("--bundle-id", default="com.gigamox.anlegacy")
    p.add_argument("--icon", type=Path)
    a = p.parse_args()
    if a.input.resolve() == a.output.resolve():
        p.error("Input and output must differ")
    if not a.name.strip() or not re.fullmatch(r"[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+", a.bundle_id):
        p.error("Invalid display name or bundle ID")
    sizes = {"Icon.png":57,"Icon@2x.png":114,"Icon-72.png":72,
             "Icon-72@2x.png":144,"Icon-76.png":76,"Icon-76@2x.png":152,
             "Icon-120.png":120,"Icon-180.png":180,"Icon-167.png":167}
    replacements = {}
    if a.icon:
        from PIL import Image
        with Image.open(a.icon) as src:
            if src.format != "PNG" or src.width != src.height:
                p.error("Icon must be a square PNG")
            for name, size in sizes.items():
                rgba = src.convert("RGBA").resize((size,size), Image.Resampling.LANCZOS)
                rgb = Image.new("RGB", rgba.size, "white")
                rgb.paste(rgba, mask=rgba.getchannel("A"))
                buf = BytesIO()
                rgb.save(buf, format="PNG")
                replacements[name] = buf.getvalue()
    with zipfile.ZipFile(a.input) as zin:
        plists = [n for n in zin.namelist() if re.fullmatch(r"Payload/[^/]+\.app/Info\.plist", n)]
        if len(plists) != 1:
            p.error("Expected exactly one application bundle")
        plist = plists[0]
        prefix = plist.rsplit("/",1)[0] + "/"
        info = plistlib.loads(zin.read(plist))
        info["CFBundleDisplayName"] = a.name
        info["CFBundleName"] = a.name
        info["CFBundleIdentifier"] = a.bundle_id
        a.output.parent.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(a.output,"w",zipfile.ZIP_DEFLATED) as zout:
            for entry in zin.infolist():
                n = entry.filename
                if n.startswith(prefix+"_CodeSignature/") or n == prefix+"embedded.mobileprovision":
                    continue
                if n == plist:
                    data = plistlib.dumps(info,fmt=plistlib.FMT_BINARY)
                elif n.startswith(prefix) and n[len(prefix):] in replacements:
                    data = replacements.pop(n[len(prefix):])
                else:
                    data = zin.read(entry)
                zout.writestr(entry,data)
            for name,data in replacements.items():
                zout.writestr(prefix+name,data)
    print("Created",a.output,"— re-sign before installing")

if __name__ == "__main__":
    main()
