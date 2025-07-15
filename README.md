## Dockvert

**Dockvert** is a lightweight, Docker-powered CLI tool for fast, dependency-free file conversion. Convert images, documents, audio, video, archives, and markup formats with one script and zero local setup.

> 💡 Powered by Docker. No dependencies. Convert anything.

---

### Features

- 🔍 **Auto file-type detection**
- 📦 **Batch & interactive conversion**
- 🐳 **Isolated tools using Docker containers**
- 🧰 **Supports major formats**: `jpg`, `png`, `pdf`, `docx`, `mp4`, `mp3`, `zip`, `md`, `html`, `tex`, and more
- ♻️ **Force rebuild support** via `--rebuild`

### Quick Start

Clone & Set Up:

```bash
git clone https://github.com/remvze/dockvert.git
cd dockvert
chmod +x dockvert.sh
```

### Requirements

- 🐳 Docker installed and running
- ✨ (Optional) `fzf` for interactive mode

### Example

```bash
./dockvert.sh resume.docx pdf
./dockvert.sh image.png jpg
./dockvert.sh video.mov mp4
./dockvert.sh notes.md html
```
