# Micro -> Nano compiler

## Micro Instructions:
"Add_S" --row start "i" --column start "j" --rows to write "p" --columns to write "q"
store | &B[0][0] | i: 1 | j: 0 | p: 1 | q: 256 | 256

"read" -- "Add_D" -- "Add_S" --row starting point "i" --column starting point "j" --number of rows to read "p" --number of columns to read "q"

"Add_M" --row_start "i" --column start "j" --rows to write "e" --columns to write "q" p
MMM | &B[0][0] | i: 0 | j: 0 | e: 1 | q: 256 | p: 256 | 256 | 256

logical_and1

"logical_or" -- "Add_D" -- "Add_S" -- "i" -- "j" -- "p" --  "q"
logical_or1 test test 0 0 256 256

logical_xor

2d unsigned short int matrix -> file
file -> 1d int array (0 or 1)