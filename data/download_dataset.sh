#!/bin/bash

cd data

echo download train.zip
wget https://www.dropbox.com/s/ohyhm2v3bhjf9l5/train.zip
unzip train.zip
rm train.zip

echo download val.zip
wget https://www.dropbox.com/s/bw4uhwlnkamq4rd/val.zip
unzip val.zip
rm val.zip

echo download test.zip
wget https://www.dropbox.com/s/87qwjo1nlga3d54/test.zip
unzip test.zip
rm test.zip
