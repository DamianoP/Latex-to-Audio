#!/bin/bash

# ==============================================================================
# Usage:
#   ./latexToAudio.sh input.tex
# ==============================================================================

# --- CONFIGURAZIONE ---
SPEED=175
BITRATE="256k"
INPUT_FILE="$1"

if [ -z "$INPUT_FILE" ]; then
  echo "Error: No input file specified."
  echo "Usage: $0 path/to/your/file.tex"
  exit 1
fi

OUTPUT_DIR="./output_$(date +'%Y-%m-%d_%H-%M')"
CLEAN_TEX_STEP1="${OUTPUT_DIR}/01_cleaned.tex"
CLEAN_TEX_STEP2="${OUTPUT_DIR}/02_plain_unformatted.txt"
FINAL_FULL_TEXT="${OUTPUT_DIR}/03_full_text_formatted.txt"

echo "--- Creating output directory ---"
mkdir -p "$OUTPUT_DIR"

echo "--- Latex cleaning (1) ---"
perl -0777 -pe '
  # Removing citation, ref, label
  s/\\cite\{[^\}]+\}//g;
  s/\\ref\{[^\}]+\}//g;
  s/\\label\{[^\}]+\}//g;

  # Removing figures, tables, equations, align, ecc.
  s/\\begin\{(figure|table|equation|align|align\*|verbatim|lstlisting)\}.*?\\end\{\1\}//sg;

  # Trasform section/subsection/subsubsection 
  # Adding special marker
  s/\\section\{([^\}]+)\}/SPLIT_HERE\n\n=== \1 ===\n\n/g;
  s/\\subsection\{([^\}]+)\}/\n\n--- \1 ---\n\n/g;
  s/\\subsubsection\{([^\}]+)\}/\n\n~~~ \1 ~~~\n\n/g;

' "$INPUT_FILE" > "$CLEAN_TEX_STEP1"

echo "--- Latex to plain text conversion ---"
pandoc -s "$CLEAN_TEX_STEP1" -t plain -o "$CLEAN_TEX_STEP2"

echo "--- Formatting the text for reading ---"
perl -00 -pe '
  s/\n/ /g;                                  # Removeing newline -> text to single line
  s/ +/ /g;                                  # Multiple spaces -> single space
  s/(\d)\. (\d)/$1§§§§$2/g;                  # Decimal numbers

  # Protects common abbreviations with temporary tokens
  my %abbr = map { $_ => $_ } qw(
    e.g. i.e. etc. cf. vs. Fig. figs. eq. Eq. approx. Dr. Prof. No. vol. pp. Art.
  );
  foreach my $a (keys %abbr) {
    (my $safe = $a) =~ s/\./§§§/g;
    s/\b\Q$a\E\b/$safe/g;
  }

  # Start a new line after a full stop/exclamation mark/question mark only if followed by a CAPITAL LETTER or a section marker.
  s/([\.!?]) +([A-Z])/$1\n$2/g;
  s/([\.!?]) +(===)/$1\n$2/g;

  s/§§§§/./g;                               # Restore decimal places
  s/§§§/./g;                                # Restore abbreviations

  # Sections and subsections with blank lines around them
  s/ *=== ([^\n]+) === */\n\n$1\n\n/g;
  s/ *--- ([^\n]+) --- */\n\n$1\n\n/g;
  s/ *~~~ ([^\n]+) ~~~ */\n\n$1\n\n/g;

  # Removes spaces before commas and periods
  s/ +,/,/g;
  s/ +\././g;

' "$CLEAN_TEX_STEP2" > "$FINAL_FULL_TEXT"

echo "--- Dividing text into sections ---"
awk -v dir="$OUTPUT_DIR" '
  BEGIN {
    # Initialise the counter and the name of the first file (for the text before the first section)
    file_count = 0;
    out_file = sprintf("%s/section_%02d", dir, file_count);
  }
  # Search for the line containing our marker
  /SPLIT_HERE/ {
    # Increases the counter and defines the name of the new file
    file_count++;
    out_file = sprintf("%s/section_%02d", dir, file_count);
    # Skip this line to avoid writing "SPLIT_HERE" in the files
    next;
  }
  {
    # Writes every line (non-marker) to the current output file.
    print >> out_file;
  }
' "$FINAL_FULL_TEXT"


echo "---  Audio files generation ---"
read -p "Do you want to generate audio files for each section? (y/n): " confirm
if [[ ! "$confirm" =~ ^[yY]$ ]]; then
  echo "Operation cancelled. No audio files will be generated."
  echo "You can find the text files in: ${OUTPUT_DIR}"
  exit 0
fi

for section_file in "${OUTPUT_DIR}"/section_*; do
  # Ignoring empty files
  if [ ! -s "$section_file" ]; then
    rm "$section_file"
    continue
  fi

  base_name=$(basename "$section_file")
  output_aiff="${OUTPUT_DIR}/${base_name}.aiff"
  output_mp3="${OUTPUT_DIR}/${base_name}.mp3"
  
  echo "  -> Processing ${base_name}..."

  echo "    Generating audio file: ${output_aiff}"
  say -r "$SPEED" -f "$section_file" -o "$output_aiff"

  echo "    Converting to MP3: ${output_mp3}"
  ffmpeg -i "$output_aiff" -b:a "$BITRATE" -vn "$output_mp3" >/dev/null 2>&1
done

# 7. Cleaning up intermediate files
echo "--- Cleaning ---"
rm -f "${OUTPUT_DIR}"/*.aiff
rm -f "${OUTPUT_DIR}"/01_cleaned.tex
rm -f "${OUTPUT_DIR}"/02_plain_unformatted.txt
rm -f "${OUTPUT_DIR}"/03_full_text_formatted.txt

# Let's rename the final files for clarity.
echo "--- Renamin files ---"
for f in "${OUTPUT_DIR}"/section_*; do
    if [ -f "$f" ]; then
        num=$(echo "$f" | sed 's/.*section_//')
        mv "$f" "${OUTPUT_DIR}/sezione_${num}.txt"
        if [ -f "${f}.mp3" ]; then
            mv "${f}.mp3" "${OUTPUT_DIR}/sezione_${num}.mp3"
        fi
    fi
done

echo "--- Process completed successfully! ---"
echo "Output: ${OUTPUT_DIR}"
