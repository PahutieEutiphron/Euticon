#!/bin/bash

# Default values
DOMAIN_FILE="domains.txt"
WAYBACK_ENABLED=true
MODE="slow"
ONLY_SUBDOMAINS=false
USE_HTTPX=false

# Help message
print_help() {
  echo "Recon Script - Subdomain enumeration and recon toolkit"
  echo ""
  echo "Usage: ./Euticon.sh [options]"
  echo ""
  echo "Options:"
  echo "  -f, --file <filename>     Use a file with input domains (default: domains.txt)"
  echo "      --fast                Skip slow operations (no amass, no crawling or grep scans)"
  echo "      --slow                Enable full recon (default mode)"
  echo "      --no-wayback          Skip wayback and gau data collection"
  echo "      --only-subdomains     Only enumerate and save subdomains (skip all other stages)"
  echo "      --use-httpx           Use httpx instead of httprobe for alive checking"
  echo "  -h, --help                Show this help message"
  echo ""
  echo "Example:"
  echo "  ./Euticon.sh -f urls.txt --fast --use-httpx"
  exit 0
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -f|--file) DOMAIN_FILE="$2"; shift ;;
    --no-wayback) WAYBACK_ENABLED=false ;;
    --fast) MODE="fast" ;;
    --slow) MODE="slow" ;;
    --only-subdomains) ONLY_SUBDOMAINS=true ;;
    --use-httpx) USE_HTTPX=true ;;
    -h|--help) print_help ;;
    *) echo "[!] Unknown parameter: $1"; exit 1 ;;
  esac
  shift
done

# Set working directories
mkdir -p output/{subs,alive,fff,wayback,scans,takeovers}

echo "[+] Cleaning input domains from $DOMAIN_FILE..."
cat "$DOMAIN_FILE" | sed 's/^\*\?\.//' | tee clean.txt > /dev/null

echo "[+] Enumerating subdomains..."
cat clean.txt | subfinder -silent >> output/subs/all.txt 2>/dev/null
cat clean.txt | assetfinder --subs-only >> output/subs/all.txt 2>/dev/null

if [ "$MODE" = "slow" ]; then
  echo "[+] Running amass (slow mode)..."
  cat clean.txt | while read domain; do
      amass enum -passive -d "$domain" -silent >> output/subs/all.txt 2>/dev/null
  done
fi

echo "[+] Deduplicating subdomains..."
sort -u output/subs/all.txt > output/subs/final.txt

if [ "$ONLY_SUBDOMAINS" = true ]; then
  echo "[+] ONLY_SUBDOMAINS flag is set. Skipping rest of recon."
  echo "[+] Done!"
  exit 0
fi

if [ "$USE_HTTPX" = true ]; then
  echo "[+] Probing with httpx..."
  cat output/subs/final.txt | httpx -silent -no-color -status-code | cut -d ' ' -f1 > output/alive/alive.txt
else
  echo "[+] Probing with httprobe..."
  cat output/subs/final.txt | sed 's/[\*_,]//g' | httprobe | sort -u > output/alive/alive.txt
fi

echo "[+] Crawling with fff..."
cat output/alive/alive.txt | fff -d 1 -S -o output/fff > /dev/null 2>&1

echo "[+] Scanning for suspicious keywords in .body files..."
find output/fff -type f -name '*.body' -exec grep -lriE 'api|token|key|password|admin|flag|auth|jwt' {} \; >> output/scans/suspicious.txt

echo "[+] Scanning for 403 Forbidden responses..."
find output/fff -type f -name '*.headers' -exec grep -lri '403 Forbidden' {} \; >> output/scans/forbidden.txt

echo "[+] Checking for subdomain takeovers with subzy..."
subzy run --targets output/subs/final.txt --hide_fails > output/takeovers/takeovers.txt

if [ "$WAYBACK_ENABLED" = true ]; then
  echo "[+] Scraping wayback + gau data..."
  cat output/subs/final.txt | waybackurls >> output/wayback/raw.txt
  cat output/subs/final.txt | gau >> output/wayback/raw.txt
  sort -u output/wayback/raw.txt > output/wayback/urls.txt

  echo "[+] Extracting URL parameters..."
  cat output/wayback/urls.txt | grep '?*=' | cut -d '=' -f 1 | sort -u > output/wayback/params.txt
  for line in $(cat output/wayback/params.txt); do echo "$line="; done

  echo "[+] Extracting JS/HTML/JSON/PHP/ASPX/etc extensions..."
  mkdir -p output/wayback/extensions
  for ext in js html json php aspx ts env log; do
      grep "\.${ext}" output/wayback/urls.txt >> output/wayback/extensions/${ext}1.txt
      sort -u output/wayback/extensions/${ext}1.txt >> output/wayback/extensions/${ext}.txt
      rm output/wayback/extensions/${ext}1.txt
  done
fi

echo "[+] Done!"

