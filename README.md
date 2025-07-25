# Latex-to-Audio

[![macOS](https://img.shields.io/badge/macOS-only-lightgrey.svg)](https://www.apple.com/macos)

This script converts a LaTeX paper into a series of audio files, intelligently splitting the output by sections. 
It's designed to help you listen to academic papers, articles, or your own work on the go.

The script first cleans the LaTeX source by removing figures, tables, equations, and citations. 
It then splits the document based on `\section` commands and generates a separate MP3 file for the preamble and each subsequent section.

---

## How It Works

The conversion process is handled in several steps:

1.  **Cleaning**: The script uses `perl` to remove complex LaTeX environments (`figure`, `table`, `equation`, etc.) and commands (`\cite`, `\ref`) that don't translate well to audio.
2.  **Section Splitting**: It identifies `\section`, `\subsection`, and `\subsubsection` commands, using them as markers to split the document into multiple parts.
3.  **Text Conversion**: The cleaned `.tex` file is converted to plain text using **Pandoc**.
4.  **Text Formatting**: A second `perl` script refines the plain text for a better listening experience. It handles line breaks, abbreviations (like `e.g.`, `i.e.`), and spacing to ensure the text-to-speech engine reads it naturally.
5.  **Audio Generation**: For each section's text file, the script:
    * Uses the macOS `say` command to generate an `.aiff` audio file.
    * Uses **FFmpeg** to convert the `.aiff` file to a high-quality `.mp3`.
6.  **Cleanup**: Intermediate files are removed, leaving only the final `.txt` and `.mp3` files for each section.

---

## Requirements

This script is designed for **macOS** and requires a few command-line tools to be installed.

* **Perl**: Used for text processing. It is typically pre-installed on macOS.
* **Pandoc**: A universal document converter, used here to transform LaTeX into plain text.
* **FFmpeg**: A complete, cross-platform solution to record, convert and stream audio and video. It's used here for MP3 conversion.

You can install Pandoc and FFmpeg using [Homebrew](https://brew.sh/):
```
brew install pandoc ffmpeg
```

---
##  Configuration

You can easily change the reading speed and the MP3 bitrate by editing the following variables at the top of the latexToAudio.sh script:
* **SPEED**: Words per minute (default: 175).
* **BITRATE**: The bitrate for the output MP3 file (default: 256k).


## Future Work
1.  **Linux Support**: Create a version of the script that works on Linux. This would involve replacing the macOS-specific say command with a Linux-friendly text-to-speech engine like espeak-ng or a more advanced one like Coqui TTS.
2.  **Windows Support**: Investigate and implement a solution for Windows users.



## Disclaimer
This software is provided "as-is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose, and non-infringement.
The responsibility for the use of this script and any audio files it generates rests solely with the end-user. The author is not responsible for the content of the generated files or for how they are used, shared, or distributed.
In no event shall the author or copyright holders be liable for any claim, damages, or other liability arising from the use of this software. Users must ensure that their use of the script and its output complies with all applicable laws, including but not limited to copyright and intellectual property rights. The author of this code assumes no liability for any misuse or copyright infringement committed by the user.








