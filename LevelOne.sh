# Creates or Restores a Yeti L1 style Wallet
# place this file in your Bitcoin/bin/ folder
# right click in the folder and click 'open in terminal'
# then type chmod +x LevelOne.sh
# then type ./LevelOne.sh and follow instructions
# if there is an existing file named "L1" in Bitcoin/bin/ folder or a wallet named L1 in home/.bitcoin/wallets/ folder you will not be able to create or restore until you move these out of the way.
# 
check_cd() {
echo -e "Confirm Digital Backup $i\n\nInsert Seed Disc $i.\nClick files and open yetiseed.txt from the CD.\nDouble click the string of letters and numbers, Right click and then Copy it.\nReturn to this terminal and Right click to paste the seed.\n"
		read -n52 -p "Seed: "
		if [ "$REPLY" == "$(< yetiseed)" ]; then
			echo -e "\nSeed Matches for Disc $i of 5.\n\nEject the CD and put it in a non-descript envelope.\n\n"
		else
			echo -e "\nSeed does Not Match your new wallet.\n\nCheck that you have pasted correctly and if so, remake this disc using yetiseed.txt and yetiwallet.dat from $PWD folder.\n"
			check_cd
		fi
}
clear
echo -e "Level One Wallet Generator by Westgate Labs, LLC.\n\nMake sure your freshly installed Ubuntu operating system is connected to the Internet and has been Fully Updated.\n\nBecause this device will be used to generate a private key it is imperative you do Not use it for anything else besides Bitcoin Core Before or After creating your wallet until erasing your hard drive.\n\nPress Enter to continue."
read -n1
echo -e "Updating advanced package tool..."
sudo apt update		# updates apt package tool
echo -e "\nInstalling tor..."
sudo apt install tor		# installs tor proxy for bitcoin
echo -e "\nLaunching Bitcoin Core...\n\nWhen it has loaded press Enter."
gnome-terminal -- ./bitcoin-qt -proxy=127.0.0.1:9050		# Launch Bitcoin Core in new window, necessary to use Bitcoin-cli command line interface in this script, -proxy tells it to use Tor.
read -n1
clear -x
echo -e "Bitcoin blockchain is now synchronizing.\n
This may take a couple days to a couple weeks depending on the speed of your machine and connection.\n\nKeep your computer connected to A/C power and the Internet. If you get disconnected or your computer hangs, rerun this script.\n\nTo maximize the chances everything goes smoothly, sleep and suspend will be disabled when you press Enter"
read -n1
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
echo -e "\n\nWhile the blockchain is synchronizing you may Create and Backup or Restore your Level One Wallet.\n\nYou will be able to Recieve funds but not Send until the synchronization is complete.\n\nTo Create a new wallet type: new\n\nTo Restore an old Level One wallet type: restore\n\nTo Load a wallet already on this PC, press alt+tab and open bitcoin core and if necessary select L1 from the upper right Dropdown menu.\n"
read -p "Type 'new' or 'restore': "

if [ "$REPLY" == "new" ]; then
	echo -e "\n\nInstalling Brasero..."
	sudo apt install brasero	# installs brasero to burn CDs
	echo -e "\n\nCreating Wallet..."
	./bitcoin-cli createwallet L1 false false "" true false true		# create a wallet named 1, disable_private_keys=false, blank=false, no passphrase, avoid_reuse=true improves privacy by avoiding address reuse, descriptors=false, load_on_startup=true
	./bitcoin-cli -rpcwallet=L1 dumpwallet L1	# dump the wallet to a walletdump file, 1.txt, this contains hdseed
	./bitcoin-cli -rpcwallet=L1 backupwallet yetiwallet		# creates wallet file backup yetiwallet.dat
	grep "hdseed=1" L1 | head -c52 > yetiseed 		# search for line with hdseed, trims line to WIF seed, store in file yetiseed in home/Documents folder
	nautilus $PWD		# opens the current directory in a new window that the user will find yetiseed.txt and yetiwallet.dat
	echo -e "\n\nMake Digital Backups\n\nBurn 5 CD-Rs each containing: yetiseed.txt, yetiwallet.dat, L1.txt and LevelOne.sh from your $PWD folder which just popped up.\nLabel each disc \"SEED\".\n\nThen press Enter to Continue."
		read -n1
		clear -x
	for (( i = 1 ; i <= 5 ; i++ )); do
		check_cd
	done
	echo -e "Make a Test Deposit\n\nRecommended: Make a ~0.001 BTC test deposit and practice spending from your new Level One wallet before Geographically Distributing your seed packets and storing significant funds.\n\nPress Alt+Tab to open Bitcoin Core, if there is a dropdown menu on upper right select L1, then click 'Recieve' and 'Create new recieving address'. If the blockchain will not sync for a while, you may wish to use a fairly slow fee.\n\nWhen you have sent the test deposit, wait for the blockchain to sync and you will be able to Send it by clicking 'Send' in Bitcoin Core.\n\nYou may close this Terminal window now."
	read -n1
fi

if [ "$REPLY" == "restore" ]; then
nautilus /home/$USER/.bitcoin/
	echo -e "\n\nRestore from Digital Backup\n\nInsert a disc labled \"Seed\". Click files and open yetiseed.txt from the CD.\nDouble click the string of letters and numbers, Right click and then Copy it.\nReturn to this terminal and Right click to paste the seed.

You may also drag and drop yetiwallet.dat into your .bitcoin/ folder which just opened. Alt+Tab to Bitcoin Core then File>Load Wallet>yetiwallet to Load the wallet, then close this Terminal."
	read -n52 -p "Seed: "
	echo -e "\nCreating Blank Wallet..."
	./bitcoin-cli createwallet L1 false true "" false false true		# creates a new blank wallet, set to load on startup
	echo -e "Setting HD seed to your input..."
	./bitcoin-cli -rpcwallet=L1 sethdseed true "$REPLY"		#sets the HD seed of this wallet to HD seed
	echo -e "\n\nWallet Restored\n\nIf the blockchain has not yet synced you will not see your balance for a while.\nWhen it has you will be able to Send funds.\nPress Alt+Tab to open Bitcoin Core, if there is a dropdown menu on upper right select L1, then click 'Send' or 'Recieve'.\n\nYou may close this Terminal window now."
fi
		
	
