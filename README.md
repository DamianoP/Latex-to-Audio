# Latex to Audio Converter

[![macOS](https://img.shields.io/badge/macOS-only-lightgrey.svg)](https://www.apple.com/macos)

This script converts a LaTeX document into a series of audio files, intelligently splitting the output by sections. It's designed to help you listen to academic papers, articles, or your own work on the go.

The script cleans the LaTeX source, converts it to plain text, and then splits the document based on `\section`, `\subsection`, and `\subsubsection` commands. It generates a separate MP3 file for the preamble (everything before the first section) and each subsequent section.

---

## Requirements

This script is designed for **macOS** and requires a few command-line tools.

*   **Perl**: Used for text processing. It is typically pre-installed on macOS.
*   **Pandoc**: A universal document converter, used here to transform LaTeX into plain text.
*   **FFmpeg**: A cross-platform tool for audio/video conversion, used here for MP3 encoding.

You can install Pandoc and FFmpeg using [Homebrew](https://brew.sh/):
```shell
brew install pandoc ffmpeg
```

---

## Usage

To use the script, run it from your terminal and provide the path to your LaTeX file as an argument:

```shell
./latexToAudio.sh path/to/your/document.tex
```

The script will create a new directory named `output_YYYY-MM-DD_HH-MM` in the current location, containing the generated text and audio files.

### Interactive Prompts
The script will ask for your confirmation twice:
1.  Before generating the audio files from the processed text.
2.  Before deleting the intermediate files (`.tex`, `.txt` temporary files) after the process is complete.

---

## Output File Structure

All output is saved in a timestamped directory (e.g., `output_2023-10-27_15-30`). Inside this directory, you will find:

*   `section_00.txt`: The plain text of your document's preamble.
*   `section_00.mp3`: The audio file for the preamble.
*   `section_01.txt`: The plain text for the first section.
*   `section_01.mp3`: The audio file for the first section.
*   ... and so on for all sections.

---

## How It Works

The conversion process is handled in several steps:

1.  **Cleaning**: The script uses `perl` to remove complex LaTeX environments (`figure`, `table`, `equation`, etc.) and commands (`\cite`, `\ref`) that don't translate well to audio. It also inserts a special `SPLIT_HERE` marker before each `\section` command.
2.  **Text Conversion**: The cleaned `.tex` file is converted to plain text using **Pandoc**.
3.  **Text Formatting**: A second `perl` script refines the plain text for a better listening experience. It handles line breaks, abbreviations (like `e.g.`, `i.e.`), and spacing to ensure the text-to-speech engine reads it naturally.
4.  **Section Splitting**: The script uses `awk` to split the formatted text into separate files using the `SPLIT_HERE` marker. The preamble is saved as `section_00`, the first section as `section_01`, and so on.
5.  **Audio Generation**: After you confirm at the prompt, the script iterates through each `section_XX` text file and:
    *   Uses the macOS `say` command to generate a temporary `.aiff` audio file.
    *   Uses **FFmpeg** to convert the `.aiff` file to a high-quality `.mp3`.
6.  **File Renaming**: The script renames the intermediate text files (e.g., `section_00`) to give them a `.txt` extension (e.g., `section_00.txt`).
7.  **Cleanup**: After a final confirmation, intermediate files are removed, leaving only the final `.txt` and `.mp3` files for each section.

---

## Customization

You can easily change the reading speed and the MP3 bitrate by editing the following variables at the top of the `latexToAudio.sh` script:

*   **`SPEED`**: Words per minute for the text-to-speech engine (default: `175`).
*   **`BITRATE`**: The bitrate for the output MP3 file (default: `256k`).

---

## Disclaimer

This software is provided "as-is", without warranty of any kind. The responsibility for the use of this script and any audio files it generates rests solely with the end-user. Users must ensure that their use of the script and its output complies with all applicable laws, including copyright.
