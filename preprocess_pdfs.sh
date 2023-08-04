#!/bin/bash

# echo make a copy of raw data
cp -vr ../data/tabme/raw/ ../data/tabme/preprocessed

echo resize pdfs and remove id information
find .../data/tabme/preprocessed -name "*.pdf" -exec sh -c "convert -density 150 '{}' -colorspace Gray -resize 1025x1025 -gravity NorthWest -shave 25x25 '{}' || { echo {} will be deleted; rm {}; }" \;
# fd -e pdf --full-path 'data/preprocessed' -x convert -verbose -density 150 {} -colorspace Gray -resize 1025x1025 -gravity NorthWest -shave 25x25 {}

# echo filter pdfs with more than 20 pages
# function len_pdf() {
# 	pdfinfo "$1" | grep -aF Pages | sed 's/Pages:[ ]*//g'
# }

# while read -r pdf_path; do
# 	if [[ $(len_pdf "$pdf_path") -gt 20 ]]; then
# 		echo "$pdf_path will be deleted"
# 		rm "$pdf_path"
# 	fi
# done < <(find ./data/preprocessed -name "*.pdf")

echo generate training, validation and testing data 18:1:1
find ../data/tabme/preprocessed -name "*.pdf" >../data/tabme/pdfs.txt
sort -R ../data/tabme/pdfs.txt >../data/tabme/pdfs.random.txt
head -n $(($(wc -l <../data/tabme/pdfs.random.txt) * 9 / 10)) ../data/tabme/pdfs.random.txt >../data/tabme/pdfs.train.txt
tail -n $(($(wc -l <../data/tabme/pdfs.random.txt) * 1 / 10 + 1)) ../data/tabme/pdfs.random.txt >../data/tabme/pdfs.val_test.txt
head -n $(($(wc -l <../data/tabme/pdfs.val_test.txt) * 1 / 2)) ../data/tabme/pdfs.val_test.txt >../data/tabme/pdfs.val.txt
tail -n $(($(wc -l <../data/tabme/pdfs.val_test.txt) * 1 / 2)) ../data/tabme/pdfs.val_test.txt >../data/tabme/pdfs.test.txt

mkdir -p ../data/tabme/train
xargs -I {} cp {} ../data/tabme/train/ <../data/tabme/pdfs.train.txt
mkdir -p ../data/tabme/val
xargs -I {} cp {} ../data/tabme/val/ <../data/tabme/pdfs.val.txt
mkdir -p ../data/tabme/test
xargs -I {} cp {} ../data/tabme/test/ <../data/tabme/pdfs.test.txt

rm ../data/tabme/pdfs.txt
rm ../data/tabme/pdfs.random.txt
rm ../data/tabme/pdfs.train.txt
rm ../data/tabme/pdfs.val_test.txt
rm ../data/tabme/pdfs.val.txt
rm ../data/tabme/pdfs.test.txt

echo convert pdfs to jpg folders
while read -r pdf_path; do
	pdf_name=$(basename "$pdf_path")
	pdf_name="${pdf_name%.*}"
	mkdir -p ../data/tabme/test/"$pdf_name"
	convert -density 150 "$pdf_path" -resize 1000x1000 "../data/tabme/test/$pdf_name/$pdf_name.jpg"
	rm "$pdf_path"
done < <(find ../data/tabme/test -name "*.pdf")

while read -r pdf_path; do
	pdf_name=$(basename "$pdf_path")
	pdf_name="${pdf_name%.*}"
	mkdir -p ../data/tabme/train/"$pdf_name"
	convert -density 150 "$pdf_path" -resize 1000x1000 "../data/tabme/train/$pdf_name/$pdf_name.jpg"
	rm "$pdf_path"
done < <(find ../data/tabme/train -name "*.pdf")

while read -r pdf_path; do
	pdf_name=$(basename "$pdf_path")
	pdf_name="${pdf_name%.*}"
	mkdir -p ../data/tabme/val/"$pdf_name"
	convert -density 150 "$pdf_path" -resize 1000x1000 "../data/tabme/val/$pdf_name/$pdf_name.jpg"
	rm "$pdf_path"
done < <(find ../data/tabme/val -name "*.pdf")

echo get test OCR using tesseract
export filter="../data/tabme/ocr_filter.awk"
while read -r pdf_path; do
	pdf_name="${pdf_path%.*}"
	tesseract -l eng --dpi 300 "$pdf_path" stdout tsv 2>/dev/null | $filter >"$pdf_name.tsv"
done < <(find ../data/tabme/test -name "*.jpg")

echo generate test virtual folders
python data/sample_folders.py ../data/tabme/test 11 25 >../data/tabme/test_folders.txt

echo get train OCR using tesseract
while read -r pdf_path; do
	pdf_name="${pdf_path%.*}"
	tesseract -l eng --dpi 300 "$pdf_path" stdout tsv 2>/dev/null | $filter >"$pdf_name.tsv"
done < <(find ../data/tabme/train -name "*.jpg")

echo generate train virtual folders
python data/sample_folders.py ../data/tabme/train 11 120 >../data/tabme/train_folders.txt

echo get validation OCR using tesseract
while read -r pdf_path; do
	pdf_name="${pdf_path%.*}"
	tesseract -l eng --dpi 300 "$pdf_path" stdout tsv 2>/dev/null | $filter >"$pdf_name.tsv"
done < <(find ../data/tabme/val -name "*.jpg")

echo generate validation virtual folders
python data/sample_folders.py ../data/tabme/val 11 25 >../data/tabme/val_folders.txt

# echo clean up
# rm -r ../data/tabme/preprocessed
