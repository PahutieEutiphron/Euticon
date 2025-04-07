Euticon.sh

A fast and modular subdomain recon and content discovery script. Originally built for personal use in real-world penetration tests, but may also be helpful to others performing similar assessments. Inspired by the recon script from the TCM Security Practical Ethical Hacking (PEH) course.

What It Does:

Cleans input domains

Enumerates subdomains

Deduplicates and filters

Probes live hosts (httpx or httprobe)

Crawls live targets with fff

Scans for:

Sensitive keywords (e.g., API keys, JWTs, auth tokens)

403 Forbidden responses

Subdomain takeover candidates (with subzy)

Optionally scrapes Wayback URLs (unless --no-wayback is passed)

Dependencies:

Make sure these are installed and in your $PATH:

assetfinder (https://github.com/tomnomnom/assetfinder)

amass (https://github.com/owasp-amass/amass)

httpx or httprobe (https://github.com/projectdiscovery/httpx, https://github.com/tomnomnom/httprobe)

fff (https://github.com/tomnomnom/fff)

subzy (https://github.com/PentestPad/subzy)

gau and waybackurls (https://github.com/lc/gau, https://github.com/tomnomnom/waybackurls)

Standard Unix tools: bash, grep, find, cat, sort, etc.

Usage:

You must provide a file named domains.txt in the root directory containing wildcard domains (e.g., example.com, *.test.com), one per line. By default, the script reads from this file.

Alternatively, you can specify a custom domain file using the -f flag:

./Euticon.sh -f custom_domains.txt [--no-wayback] [--use-httpx] [--fast]

Flags:

-f, --file

Use a file with input domains (default: domains.txt)

--fast

Skip slow operations (no amass, no crawling or grep scans)

--slow

Enable full recon mode (default)

--no-wayback

Skip Wayback Machine and gau data collection

--only-subdomains

Only enumerate and save subdomains (skips all other stages)

--use-httpx

Use httpx instead of httprobe for alive checking

-h, --help

Show usage instructions and available options

Output Structure

Results are neatly organized under the output/ folder:

output/
├── alive/                   # Probed alive hosts
├── fff/                     # Crawled files (.body / .headers)
├── scans/
│   ├── forbidden.txt        # Files returning 403
│   ├── suspicious.txt       # Files with sensitive content
├── subs/                    # Subdomain results
├── takeovers/              # Subdomain takeover scan results
└── wayback/ (optional)     # gau + wayback scraping

Example Usage

echo "*.example.com" > domains.txt
./Euticon.sh --use-httpx --fast

Pro Tip:

Customize keyword grep logic to your recon style.

License

MIT License — free to use, modify, and share.

About

Maintained by Tudor - https://www.linkedin.com/in/tudor-lasuschevici/ | Pentester | Inspired by the recon script from the TCM Security Practical Ethical Hacking (PEH) course.
# Euticon
# Euticon
