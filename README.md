# Nabla•fs

Software for comparing the contents of two directories

## Description

Two folders `Source` & `Destination` are compared by structure, number of subfolders, files and their size. Completely matching elements are highlighted in green, those that differ are highlighted in red, and those present in only one catalog are highlighted in yellow.

The following operations are available in the context menu of elements:
  * Copy from source to destination
  * Copy from destination to source
  * Remove from source
  * Remove from destination
  * Rename (in source and destination, if exists)
  * Update (re-compare this item in the selected folders)
  * Bitewise compare (compare with `fcmp.exe` for files only)
  * Open (depending on type):
    - Folder
      * Open in Windows Explorer
      * Launch terminal (`cmder.exe`) in this folder
    - File
      * Open in Notepad (`Notepad++.exe`)
      * Open in Hex Editor (`Be.HexEditor.exe`)
      * Open parent folder in Windows Explorer
      * Launch terminal (`cmder.exe`) in parent folder

Also, when you call the context menu of an element, a comparative table of properties is displayed next to it.

Calling the context menu with the `shift` key pressed allows disabled menu items.

Paths to external callable programs `Cmder.exe`, `Notepad++.exe`, `Be.HexEditor.exe` are specified in the file `path.h`

![screen](https://raw.githubusercontent.com/c-not-around/nabla-fs/57846549dc99e197526507690c1a300b6dedf606/screen1.png)
![screen](https://raw.githubusercontent.com/c-not-around/nabla-fs/57846549dc99e197526507690c1a300b6dedf606/screen2.png)