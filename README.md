# Archive

Any further development has been transfered to [torge](https://github.com/TUVIMEN/torge).

# tpb

A shell script for searching torrents on thepiratebay.

![example](example.gif)

## Requirements

 - [hgrep](https://github.com/TUVIMEN/hgrep)
 - xclip

## Installation

    install -m 755 tpb /usr/bin

## Usage

Just type 'tpb "your search"', choose what you want and the magnet link will be copied to your clipboard.

Search for the biggest linux isos

    tpb -s size 'linux iso'

Search for the smallest linux isos on second page

    tpb -s rsize -p 2 'linux iso'

Search different domain for linux isos and change delimiter to space

    tpb -D ' ' -d 'http://otherdomain.to' 'linux iso'

Get some help

    tpb -h
