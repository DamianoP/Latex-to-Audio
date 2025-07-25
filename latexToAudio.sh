#!/bin/bash

# ==============================================================================
# Usage:
#   ./latexToAudio.sh input.tex
#
# Description:
#   This script converts a LaTeX document into multiple MP3 audio files,
#   one for each section.
# ==============================================================================
# --- CONFIGURATION ---
SPEED=175
BITRATE="256k"
INPUT_FILE="$1"

# --- VALIDATION ---
if [ -z "$INPUT_FILE" ]; then
  echo "Error: No input file specified."
  echo "Usage: $0 path/to/your/file.tex"
  exit 1
fi

if ! [ -f "$INPUT_FILE" ]; then
  echo "Error: Input file not found at '$INPUT_FILE'"
  exit 1
fi
OUTPUT_DIR="./output_$(date +'%Y-%m-%d_%H-%M')"
CLEAN_TEX_STEP1="${OUTPUT_DIR}/01_cleaned.tex"
CLEAN_TEX_STEP2="${OUTPUT_DIR}/02_plain_unformatted.txt"
FINAL_FULL_TEXT="${OUTPUT_DIR}/03_full_text_formatted.txt"

echo "--- Creating output directory: ${OUTPUT_DIR} ---"
mkdir -p "$OUTPUT_DIR"

echo "--- Step 1: Cleaning LaTeX source ---"
# This perl script removes environments and commands that are not suitable for audio conversion
# and inserts a 'SPLIT_HERE' marker before each new section.
perl -0777 -pe '
  # Removing citation, ref, label
  s/\\cite\{[^\}]+\}//g;
  s/\\ref\{[^\}]+\}//g;
  s/\\label\{[^\}]+\}//g;

  # Removing figures, tables, equations, align, ecc.
  s/\\begin\{(figure|table|equation|align|align\*|verbatim|lstlisting)\}.*?\\end\{\1\}//sg;

  # Transform section/subsection/subsubsection 
  # Adding special marker
  s/\\section\{([^\}]+)\}/SPLIT_HERE\n\n=== \1 ===\n\n/g;
  s/\\subsection\{([^\}]+)\}/\n\n--- \1 ---\n\n/g;
  s/\\subsubsection\{([^\}]+)\}/\n\n~~~ \1 ~~~\n\n/g;

' "$INPUT_FILE" > "$CLEAN_TEX_STEP1"

echo "--- Step 2: Converting LaTeX to plain text ---"
pandoc -s "$CLEAN_TEX_STEP1" -t plain -o "$CLEAN_TEX_STEP2"

echo "--- Step 3: Formatting text for a better reading experience ---"
# This perl script formats the plain text for a more natural audio narration.
perl -00 -pe '
  s/\n/ /g;                                  # Removeing newline -> text to single line
  s/ +/ /g;                                  # Multiple spaces -> single space
  s/(\d)\. (\d)/$1§§§§$2/g;                  # Decimal numbers

  # Protect common abbreviations with temporary tokens
  my %abbr = map { $_ => $_ } qw(
    e.g. i.e. etc. cf. vs. Fig. figs. eq. Eq. approx. Dr. Prof. No. vol. pp. Art.
  );
  foreach my $a (keys %abbr) {
    (my $safe = $a) =~ s/\./§§§/g;
    s/\b\Q$a\E\b/$safe/g;
  }

  # Start a new line after a sentence-ending punctuation mark
  s/([\.!?]) +([A-Z])/$1\n$2/g;
  s/([\.!?]) +(===)/$1\n$2/g;

  s/§§§§/./g;                               # Restore decimal numbers
  s/§§§/./g;                                # Restore abbreviations

  # Format section headers with blank lines
  s/ *=== ([^\n]+) === */\n\n$1\n\n/g;
  s/ *--- ([^\n]+) --- */\n\n$1\n\n/g;
  s/ *~~~ ([^\n]+) ~~~ */\n\n$1\n\n/g;

  # Clean up spacing around punctuation
  s/ +,/,/g;
  s/ +\././g;

' "$CLEAN_TEX_STEP2" > "$FINAL_FULL_TEXT"

echo "--- Step 4: Splitting text into section files ---"
awk -v dir="$OUTPUT_DIR" '
  BEGIN {
    # Flag to track if we have passed the first section marker.
    # We will only start writing after the first marker is found.
    start_writing = 0; 
    file_count = 0;
  }
  {
    if (match($0, /SPLIT_HERE/)) {
      # This is a line with a marker.

      # Extract content before and after the marker.
      before_marker = substr($0, 1, RSTART - 1);
      after_marker = substr($0, RSTART + RLENGTH);

      # If we were already writing, the content before the marker belongs to the previous section.
      if (start_writing == 1 && length(before_marker) > 0) {
        print before_marker >> out_file;
      }
      
      # Now, we start a new section file.
      start_writing = 1; # Enable writing from now on.
      file_count++;
      out_file = sprintf("%s/section_%02d", dir, file_count);
      
      # Print the content after the marker to the new file.
      if (length(after_marker) > 0) {
        print after_marker >> out_file;
      }
    } else {
      # This is a line without a marker.
      # Only print it if we have passed the first marker.
      if (start_writing == 1) {
        print >> out_file;
      }
    }
  }
' "$FINAL_FULL_TEXT"


echo "--- Step 5: Generating audio files ---"
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

rm -f "${OUTPUT_DIR}"/*.aiff

echo "--- Step 6: Cleaning up intermediate files ---"
read -p "Do you want to clean temp files? (y/n): " confirm
if [[ "$confirm" =~ ^[yY]$ ]]; then
  rm -f "${OUTPUT_DIR}"/01_cleaned.tex
  rm -f "${OUTPUT_DIR}"/02_plain_unformatted.txt
  rm -f "${OUTPUT_DIR}"/03_full_text_formatted.txt
fi


# Let's rename the final files for clarity.
echo "--- Step 7: Renaming final files ---"
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
echo "Output files are in: ${OUTPUT_DIR}"
