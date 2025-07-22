#!/usr/bin/env python3
# ABOUTME: Searches GitHub for CLAUDE.md files and outputs repo names with raw URLs
# ABOUTME: Ultra-simple version that prints pipe-delimited format to stdout

import requests
import json
import sys
import os
import argparse
from datetime import datetime
from pathlib import Path

def main():
    parser = argparse.ArgumentParser(description='Collect CLAUDE.md files from GitHub')
    parser.add_argument('--pages', type=int, default=1, help='Number of pages to fetch (default: 1)')
    parser.add_argument('--download', action='store_true', help='Download files to timestamped directory')
    args = parser.parse_args()

    # Get GitHub token from environment
    token = os.getenv('GITHUB_TOKEN')
    if not token:
        print("Error: GITHUB_TOKEN environment variable required", file=sys.stderr)
        print("Get a token at: https://github.com/settings/tokens", file=sys.stderr)
        return

    headers = {'Authorization': f'token {token}'}

    # Setup download directory if needed
    download_dir = None
    if args.download:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        download_dir = Path(f"claude_files_{timestamp}")
        download_dir.mkdir(exist_ok=True)
        print(f"Downloading to: {download_dir}", file=sys.stderr)
    else:
        # Print header for CSV output
        print("repo|raw_url")

    # Fetch multiple pages
    for page in range(1, args.pages + 1):
        response = requests.get(f'https://api.github.com/search/code?q=filename:CLAUDE.md&per_page=100&page={page}', headers=headers)
        data = response.json()

        if 'message' in data:
            print(f"Error on page {page}: {data['message']}", file=sys.stderr)
            continue

        if 'items' not in data or not data['items']:
            break

        # Process each item
        for item in data['items']:
            repo = item['repository']['full_name']
            # Get the actual filename and commit hash from html_url
            html_url = item.get('html_url', '')
            filename = item.get('name', 'CLAUDE.md')

            # Extract commit hash from html_url
            commit_hash = 'main'  # default fallback
            if 'blob/' in html_url:
                commit_hash = html_url.split('blob/')[1].split('/')[0]

            raw_url = f"https://raw.githubusercontent.com/{repo}/{commit_hash}/{filename}"

            if args.download:
                # Download file with smart naming
                owner, repo_name = repo.split('/')
                safe_filename = f"{owner}___{repo_name}___CLAUDE.md"
                file_path = download_dir / safe_filename

                try:
                    file_response = requests.get(raw_url)
                    file_response.raise_for_status()

                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(file_response.text)

                    print(f"Downloaded: {repo} ({filename})", file=sys.stderr)
                except Exception as e:
                    print(f"Error downloading {repo}: {e}", file=sys.stderr)
            else:
                # Print CSV line
                print(f"{repo}|{raw_url}")

if __name__ == "__main__":
    main()
