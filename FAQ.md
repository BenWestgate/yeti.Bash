**Frequently Asked Questions**

**How do I create a Digital backup of my yeti.Bash wallet?**

Put bitcoin core and xprvwallet1-7 on 7 CDs.
label offline 1-7

Put pubwallet and bitcoin core on 7 CDs
label Watch-only

Xubuntu or Ubuntu studio linux distros have a built in CD burner software, install Brasero before creating the wallet if using Ubuntu
You could also use a formatted USB stick but they will lose data within 5 years so Do Not skip the paper backups of written seed words and printed descriptor.

You can also put a copy of descriptor.txt and the corresponding seed.txt (seed1.txt with xprvwallet1.dat, etc) on the disc which helps for restoring faster with yeti.

This will be automated in the coming weeks, for now you get a paper backup which is enough to securely store funds but slower to restore from.

**How do I spend from a digital backup?**

Insert "Watch-only" pub wallet CD into your single purpose ubuntu PC with a fully synced bitcoin core full node

Open pubwallet in bitcoin core. you may have to drop it in /.bitcoin/wallets/ folder to see it.

It will take a while to rescan, then Select a UTXO you had test deposited, click create unsigned transaction and save the PSBT file
Burn it to a disc, USB stick is OK for testing.

Then you take that PSBT media and a wiped clean, offline laptop running on live USB (e.g. "Try Xubuntu"), networking off, to each offline CD

copy core and the wallet file off the disc.

Navigate to bitcoin/bin/ folder, right click, open in terminal, type "./bitcoin-qt" and then open the xprvwallet in bitcoin core

Then insert the PSBT media and click file, load PSBT, and sign. Shutdown.

Go to next backup location, insert second xprv wallet CD, same steps, repeat for third.

Bring this final file back to your full node, file, load it and click "broadcast"

**How do I spend from a paper backup?**

Easy Answer: Use Yeticold.com if you made an m=3 wallet and follow the restore steps.

**How do I watch from a paper backup using Only Bitcoin Core?**

This requires a console command until I write an automated restore script, soon(TM).  For now, do this:

On a single purpose linux laptop fullnode. Open Bitcoin Core, create a blank, descriptor, watch-only wallet (private keys disabled)

Press Ctrl+T, type or type and paste 

importdescriptors '[{"desc": "entire descriptor", "timestamp": "now", "active": true}]'

You can now watch your yeti.Bash wallet.

**How do I spend from a paper backup using Only Bitcoin Core?**

This requires a couple console commands until I write an automated restore script, soon(TM)  For now, do this:

For spending/signing wallets, you do the same thing but on an offline laptop (for amounts >$50k we prefer to keep the private keys offline)

Put bitcoin core onto your formatted offline laptop running a Live OS like Xubuntu.

Open a blank text document, Type the first letter case sensitive of the first 4 columns left to right, top to bottom, type number words as the numeric character (ONE=1, etc)

Save it as a seed.txt

Open bitcoin core, create a blank, Non-descriptor wallet with private keys enabled, name it xprvwallet

Ctrl+T, then type

sethdseed "the seed"

dumpwallet privkey1

Go to bitcoin/bin folder, open that file and on line 6 you have your xprv, copy it to clipboard

Take your descriptor and replace whichever xpub corresponds to it with the xprv.  Save it as Descriptor.txt

For example if that was seed 2, you replace the second xpub with xprv you found in that file.

Return to core, Ctrl+T, type

getdescriptorinfo "your entire descriptor"

Grab the characters it returns in the checksum field.

Replace the characters after the "))#" in Descriptor.txt with these new letters and numbers, save the file and copy it to your clipboard.

It is now ready to be imported to your spending wallet. Create a blank descriptor wallet without private keys disabled, name it xprvwallet

Press Ctrl+T, select xprvwallet in the upper left, type or type and paste 

importdescriptors '[{"desc": "entire descriptor", "timestamp": "now", "active": true}]'

And you'll be ready to sign.

Your PSBT will need 3 signatures from 3 different backups before you can return to your full node and broadcast.

**How can I reach you for more Questions?**

yeticold.slack.com  or @BenWestgate_ on Twitter

**How can I donate to help further development?**

Buy Bitcoin, short BTC/USD with 100x leverage to get Liquidated or message me on Slack or Twitter for a donation address.

If there's a custom feature I haven't made yet that you'd like to see, this is a good way to get me to build it.
