import urllib.request
import ssl
import sys
import os

ssl._create_default_https_context = ssl._create_unverified_context

url = 'https://services.gradle.org/distributions/gradle-9.1.0-all.zip'
user_home = os.path.expanduser('~')
dest_dir = os.path.join(user_home, '.gradle', 'wrapper', 'dists', 'gradle-9.1.0-all', '7wzd0jkjit61aq2p43wpjgij9')
dest_file = os.path.join(dest_dir, 'gradle-9.1.0-all.zip')

os.makedirs(dest_dir, exist_ok=True)

print(f'Downloading to: {dest_file}')
try:
    req = urllib.request.Request(url, headers={
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    })
    
    with urllib.request.urlopen(req, timeout=300) as response:
        total_size = int(response.headers.get('Content-Length', 0))
        print(f'Content-Length: {total_size}')
        
        with open(dest_file, 'wb') as f:
            downloaded = 0
            while True:
                chunk = response.read(8192)
                if not chunk:
                    break
                f.write(chunk)
                downloaded += len(chunk)
                if total_size > 0:
                    percent = (downloaded / total_size) * 100
                    print(f'\rDownloaded: {downloaded}/{total_size} bytes ({percent:.1f}%)', end='')
                else:
                    print(f'\rDownloaded: {downloaded} bytes', end='')
    
    print(f'\nDownload completed successfully! Saved to: {dest_file}')
    print(f'File size: {os.path.getsize(dest_file)} bytes')
    
except Exception as e:
    print(f'Error: {e}')
    sys.exit(1)