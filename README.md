# yeti.Bash
A port of Yeticold.com to Shell 

Less than 100 lines of code stand between you and Bitcoin Core v0.21

Optimized for code review and auditability

Requires no dependences outside of bitcoin core and uses only standard gnu commands so can be run fully offline; an improvement on Yeti Wallet Level 3 security model

Suitable for Storing $50k to $20M of Bitcoin when executed on a clean always offline PC from a Linux Live OS.  (currently tested on Ubuntu 20.04 LTS, Xubuntu, Manjaro)

Seed words are backed up in a format 100% compatible with Yeti Wallets

Find original here: https://github.com/JWWeatherman/yeticold

Instructions for Use:

place CreateWallet.sh in the /bitcoin-0.21.0/bin/ folder
Right click empty space in this folder, select "Open in Terminal"
Enter ./bitcoind
Open a new terminal
If on ubunutu enter "chmod +x CreateWallet.sh" otherwise skip
Type ./CreateWallet.sh and follow instructions on screen.
If you get stuck closing, the terminal and starting over will use the same wallet seeds unless you have wiped your .bitcoin/wallets folder and removed wallet dump files from your /bitcoin-0.21.0/bin/ folder

To make a wallet with a different m of n than 3 of 7 (yeti recommeneded values for long-term storage by a single person) follow the above instructions but for CustomWallet.sh rather than CreateWallet.sh
