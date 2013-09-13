# rmemo
Rmemo is memo tool. rmemo is written by ruby
Rmemo like seem howm. howm run on editer, but rmemo is CLI.

# file
Rmemo.rb run script

# Data
Memo data save to '~/.rmemo' directory.
Directory:~/.rmemo/memo/[year]/[month]/[day]/[number]

# File Format
One memo is one file, and free format.
Rmemo view first line to be memo's title

# How to use?
## help
   $ rmemo.rb -h

## search
   $ rmemo.rb -s linux
   $ rmemo.rb -s /linux/

### search:ignore
   $ rmemo.rb -is linux
   $ rmemo.rb -s /linux/i

### search and title print
   $ rmemo.rb -ts linux

### search and contents print
   $ rmemo.rb -ps linux

### search by date
   $ rmemo.rb -ps linux -d 2013

   $ rmemo.rb -ps linux -d 2013-01

   $ rmemo.rb -ps linux -d 2013-01-03
