# yeti.Bash
A port of Yeticold.com to Shell 

Less than 100 lines of code stand between you and Bitcoin Core v0.21

Optimized for code review and auditability

Requires no dependences outside of bitcoin core and uses only standard gnu commands so can be run fully offline; an improvement on Yeti Wallet Level 3 security model

Suitable for Storing $50k to $20M of Bitcoin when executed on a clean always offline PC from a Linux Live OS.  (currently tested on Ubuntu 20.04 LTS, Xubuntu, Manjaro)

Seed words are backed up in a format 100% compatible with Yeti Wallets

Find original here: https://github.com/JWWeatherman/yeticold

Instructions for Use:

Put CreateWallet.sh in bitcoin/bin folder

Right-click in folder, select "Open in Terminal"

Enter ./bitcoind

Open a new Terminal

Enter "chmod +x CreateWallet.sh"

Enter ./CreateWallet.sh and follow instructions on screen.

To make a Multisignature wallet with a different m of n than 3 of 7, follow instructions above but for CustomWallet.sh rather than CreateWallet.sh
