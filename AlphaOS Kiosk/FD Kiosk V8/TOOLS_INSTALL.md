# Optional CLI tools (opencode, Codex, Gemini)

These helpers are handy for support/troubleshooting. Start by ensuring `curl` exists.

## 1) Install curl (if missing)
```bash
sudo apt update
sudo apt install -y curl
```
sudo nano /etc/apt/sources.list

deb http://deb.debian.org/debian trixie main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
deb http://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware

Crtl+O, enter,ctrl+x
## 2) Install opencode (includes Codex CLI)
```bash
curl -fsSL https://opencode.ai/install | bash
export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$PATH"
opencode --version
codex --help   # Codex CLI is bundled; this should print usage
```

## 3) Install Gemini CLI (optional)
```bash
sudo apt install -y python3-pip
python3 -m pip install --user pipx
python3 -m pipx ensurepath
pipx install gemini-cli
export GEMINI_API_KEY="<your-key-from-Google-AI-Studio>"
gemini --help
gemini models list
```

## 4) Quick verification
- `opencode --version`
- `codex --help`
- `gemini --help` (if installed)
