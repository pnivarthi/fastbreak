"""Download a pinned public NBA archive; keep original files for provenance."""
import hashlib
import json
import pathlib
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]
REPO = 'NocturneBear/NBA-Data-2010-2024'

def fetch(url):
    request = urllib.request.Request(url, headers={'User-Agent': 'fastbreak-data-import'})
    with urllib.request.urlopen(request, timeout=120) as response:
        return response.read()

def main():
    commit = json.loads(fetch(f'https://api.github.com/repos/{REPO}/commits/main'))['sha']
    files = ['LICENSE', 'README.md', 'play_off_box_scores_2010_2024.csv',
             'play_off_totals_2010_2024.csv', 'regular_season_totals_2010_2024.csv']
    files += [f'regular_season_box_scores_2010_2024_part_{i}.csv' for i in range(1, 4)]
    dest = ROOT / 'data' / 'raw'
    dest.mkdir(parents=True, exist_ok=True)
    manifest = {'repository': f'https://github.com/{REPO}', 'commit': commit, 'files': []}
    for name in files:
        url = f'https://raw.githubusercontent.com/{REPO}/{commit}/{name}'
        data = fetch(url)
        (dest / name).write_bytes(data)
        manifest['files'].append({'file': name, 'url': url, 'bytes': len(data),
                                  'sha256': hashlib.sha256(data).hexdigest()})
        print(f'Downloaded {name}: {len(data):,} bytes', flush=True)
    (ROOT / 'data' / 'source.json').write_text(json.dumps(manifest, indent=2) + '\n')

if __name__ == '__main__':
    main()
