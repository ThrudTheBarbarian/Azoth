#genRsrc

```
Usage: genRsrc <options> where options are from:

  -d|--source-dir        :specify the source directory
  -o|--output-file-stem  :specify the output file directory
  -x|--output-x-size     :width of the atlas image (512)
  -y|--output-y-size     :height of the atlas image (512)
  -h|--help              : This wonderful help
```

Used to create an atlas image of all the files in a given directory (or the current directory if not specified). An atlas is used to generate the cursors, symbols font, and UI components (thus making it skinnable, though at the moment some work might need to be done to make the UI truly portable) 
