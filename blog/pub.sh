#!/bin/bash

hugo
rsync -avz --progress --delete public/ gwind.hk:/data/production/gwind.me/
