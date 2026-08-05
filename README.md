# yeti.Bash
An experimental port of Yeticold.com to Shell 

Less than 100 lines of code stand between you and Bitcoin Core v0.21

Optimized for code review and auditability

Requires no dependencies outside of bitcoin core and uses only standard gnu commands so can be run fully offline; an improvement on Yeti Wallet Level 3 security model

Currently tested on Ubuntu 20.04 LTS, Xubuntu, Manjaro

Seed words are backed up on paper in a format 100% compatible with Yeti Wallets

Find original here: https://github.com/JWWeatherman/yeticold

For real funds in a trust minimized multi-signature setup follow: https://github.com/bitcoin/bitcoin/blob/master/doc/multisig-tutorial.md


How to Use:

Put CreateWallet.sh in bitcoin/bin folder

Right-click in folder, select "Open in Terminal"

Open a new Terminal

Enter "chmod +x CreateWallet.sh"

Enter ./CreateWallet.sh and follow instructions on screen.


**To make a non 3-of-7 multisig wallet, use instructions above with CustomWallet.sh not CreateWallet.sh

**To make a multisig wallet with additional randomness from coin flips or dice rolls, use instructions above with CoinDiceWallet.sh

**To Make or Restore a Yeti Level One style single signature wallet for spending use LevelOne.sh
