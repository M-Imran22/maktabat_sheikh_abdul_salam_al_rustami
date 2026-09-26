import os
import sys
import json
import re

# Ensure UTF-8 output on Windows console
if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

def natural_sort_key(s):
    """Sorts strings with embedded numbers naturally (e.g. 1, 2, 10 instead of 1, 10, 2)."""
    return [int(text) if text.isdigit() else text.lower() for text in re.split(r'(\d+)', s)]

def generate_catalog(source_dir, output_file):
    """
    Scans source_dir for all MP3 files, calculates metadata,
    and writes an audio_catalog.json compatible with Maktabat App.
    """
    if not os.path.isdir(source_dir):
        print(f"Error: Source directory not found: {source_dir}")
        return False

    print(f"Scanning audio files in: {source_dir}")
    catalog = []

    has_mutagen = False
    try:
        from mutagen.mp3 import MP3  # type: ignore
        has_mutagen = True
    except ImportError:
        print("Note: 'mutagen' package not found. Duration calculation will default to 0.")
        print("To install: pip install mutagen")

    for dirpath, dirnames, filenames in os.walk(source_dir):
        for f in filenames:
            # Strictly include only MP3 audio files
            if not f.lower().endswith('.mp3'):
                continue

            full_path = os.path.join(dirpath, f)
            rel_path = os.path.relpath(full_path, source_dir).replace('\\', '/')
            parts = rel_path.split('/')
            category = parts[0]
            subfolder = '/'.join(parts[1:-1]) if len(parts) > 2 else ''
            title = os.path.splitext(f)[0]
            size_mb = round(os.path.getsize(full_path) / (1024 * 1024), 2)

            duration_sec = 0
            if has_mutagen:
                try:
                    audio = MP3(full_path)
                    if audio.info and audio.info.length:
                        duration_sec = int(audio.info.length)
                except Exception:
                    pass

            m, s = divmod(duration_sec, 60)
            h, m = divmod(m, 60)
            duration_str = f"{h}:{m:02d}:{s:02d}" if h > 0 else f"{m:02d}:{s:02d}"

            catalog.append({
                "category": category,
                "subfolder": subfolder,
                "title": title,
                "fileName": f,
                "relativePath": rel_path,
                "durationSec": duration_sec,
                "durationStr": duration_str,
                "sizeMB": size_mb
            })

    # Sort naturally by relative path (Surahs 1..114, Lessons 001.. etc.)
    catalog.sort(key=lambda x: natural_sort_key(x["relativePath"]))

    os.makedirs(os.path.dirname(os.path.abspath(output_file)), exist_ok=True)
    with open(output_file, "w", encoding="utf-8") as fp:
        json.dump(catalog, fp, ensure_ascii=False, indent=2)

    print(f"\nSuccess! Indexed {len(catalog)} audio files into: {output_file}")
    file_size_kb = os.path.getsize(output_file) / 1024
    print(f"Catalog JSON file size: {file_size_kb:.1f} KB")

    # Category breakdown
    cats = {}
    for item in catalog:
        cats.setdefault(item["category"], 0)
        cats[item["category"]] += 1

    print("\nSummary by Collection:")
    for cat, count in sorted(cats.items()):
        print(f"  - {cat}: {count} tracks")

    return True

if __name__ == "__main__":
    default_source = r"D:\pc-data\Madrassa\Audio"
    source = sys.argv[1] if len(sys.argv) > 1 else default_source

    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.abspath(os.path.join(script_dir, ".."))
    out = os.path.join(project_root, "assets", "data", "audio_catalog.json")

    generate_catalog(source, out)
