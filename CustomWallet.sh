# Click Files on the Left hand bar, Navigate to home/bitcoin/bin/
# Move this file into the home/bitcoin/bin/ folder
# Right click in the /bin/ folder once more and select "open in terminal" and paste the following command:
# chmod +x CustomWallet.sh
# Then paste the following command:
# ./CustomWallet.sh

m=3		# yeti wallet recommended value of 3 for the spending threshold
n=7		# yeti wallet recommened value of 7 for the number of signers
# create base58 alphabet, remove spaces between characters, store in variable base58_alphabet
base58_alphabet=$(echo {1..9} {A..H} {J..N} {P..Z} {a..k} {m..z} | sed 's/ //g')
# store the NATO Alphabet corresponding to base58_alphabet as array to_nato
to_nato=('ONE' 'TWO' 'THREE' 'FOUR' 'FIVE' 'SIX' 'SEVEN' 'EIGHT' 'NINE' 'ALPHA' 'BRAVO' 'CHARLIE' 'DELTA' 'ECHO' 'FOXTROT' 'GOLF' 'HOTEL' 'JULIET' 'KILO' 'LIMA' 'MIKE' 'NOVEMBER' 'PAPA' 'QUEBEC' 'ROMEO' 'SIERRA' 'TANGO' 'UNIFORM' 'VICTOR' 'WHISKEY' 'X-RAY' 'YANKEE' 'ZULU' 'alpha' 'bravo' 'charlie' 'delta' 'echo' 'foxtrot' 'golf' 'hotel' 'india' 'juliet' 'kilo' 'mike' 'november' 'oscar' 'papa' 'quebec' 'romeo' 'sierra' 'tango' 'uniform' 'victor' 'whiskey' 'x-ray' 'yankee' 'zulu')
#######################
# Displays WIF NATO seeds and Confirms they are written down correctly
#######################
backup() {
	j=1		# j is counter since this will be used inside another loop,
	sum=0		# sum holds the sum of the base 58 values to create a 5th checksum column of seed words for yeti compatibility and easier error recovery
	echo -e "\n\nWIF NATO Privacy Key $i\n\n"
	while read -n1 letter; do		# loop thru each character of seed, assign character to letter, sed command spaces digits so each is considered individually		
		num=$(( $(expr index "$base58_alphabet" "$letter") - 1))		# find index (position) of letter in base58_alphabet 1-58
		(( sum += num ))		# increase sum by num - 1
		echo -n ${to_nato[$num]}" "		# echos the NATO word for the letter, followed by space
		if [ $(( j % 4 )) == 0 ]; then		# if the counter is evenly divisible by 4, then...
			echo ${to_nato[$(( sum % 58 ))]}		# echo the NATO word for the checksum
			sum=0		# assign 0 to sum
		fi		# end if statement
		(( j++ ))	# increment counter
	done < <(echo -n $1) | column -t -s ' '		# inserts parameter (a seed) into the while read -n1 loop, then format while loop output into columns with space as delineator
	
	echo -e "\n\nWrite these 65 words down (case-sensitive) and Label them \"SEED $i\".\nIf you are only testing CreateWallet.sh you can skip writing these down and find yetiseed$i.txt in your home/Documents Folder.\n\nWhen you are finished press Enter."		# prompt user to hand-write
	read -n1	# wait for any key press
	clear		# clear terminal so user must type from paper backup
	echo -e "Confirm you have Written Down your seed words Correctly\n\nIf you are just testing CreateWallet.sh and don't plan to use large amounts you may paste from home/Documents/yetiseed$i.txt.\n\nIf you lose access to more than 4 of your seeds your bitcoin will be permanently lost.\n\nCover up the 5th Column of your written seed words. Type all Number Words as the Numeral, otherwise type the First Letter of each word. Start on line 1, left to right and continue through all rows until done.\n\n\tLIMA    ONE     victor  echo\n\tFOXTROT romeo   THREE   ECHO\n\nWould for example be entered as:  L1veFr3E\n\nInput on one line below without spaces and when finished press Enter.\n\n"
	read -n52 -e -p "WIF Key $i: "		# reads 52 characters of input then continues to next line
	echo ""		# echo new line	
	j=0			# reset counter
	retry=''		# empty string stored in retry, this is a flag thrown for typos
	while read -n1 letter; do		# loop thru each letter of seed, assign to letter.
		if [ "$letter" != "${REPLY:$j:1}" ]; then		# if the letter does not match the user's input...
			echo "Word $(( j + 1 )) does not match. Check Row $(( j / 4 + 1 )), Column $(( j % 4 + 1 ))."	# error message prints word number and location that don't match the seed
			retry=true		# store "true" in retry
		fi
		(( j++ ))
	done < <(echo $1)
	if [ "$retry" == '' ]; then		# if retry is blank, say key matches and exit function
		echo -e "WIF Key $i Matches.\n\n\nMake a Digital Backup\n\nBurn a CD-R with Descriptor.txt, yetiseed$i.txt and xprvwallet$i.dat from your home/Documents/ folder which just opened, label the disc \"SEED $i\", then place the written seed words and disc in an envelope.\n\nThen press Enter to Continue."
		nautilus ~/Documents		# opens home/Documents
		read -n1
	else
		echo -e "\n***Fix the above errors on The PAPER Backup.***\nThen press Enter."
		read -n1
		clear
		paper_backup $1		# if retry is true, call the function again.
	fi
}

# Script Begins Execution Here

clear
echo -e "Bitcoin Multi-signature Wallet Generator by Westgate Labs, LLC.\n\n\nDisconnect Network Cable\n\nIf you are using a network cable or laptop power cable unplug them now.\nAlso unplug all unnecessary peripherals, only a CD-R drive and printer are needed, if these are not yet installed, do so now.\nBecause this device will be used to generate private keys your Network Connection will be disabled when you press Enter.\n\nDo not reconnect this device to a network until you have erased the hard drive.\nFor Testing type 'nmcli networking on' afterwards in a terminal get back online.\n\nAfter you press Enter, Bitcoin core will load in a new window, click back to this terminal to continue when it does."
read -n1
nmcli networking off		# Disables Networking. if Testing, type 'nmcli networking on' in a new terminal to re-enable networking
clear -x
nmcli -p networking		# Displays so user can confirm Networking is Off.
echo -e "\n\n\nWhen Bitcoin Core has finished loading, press Enter to continue."
gnome-terminal -- ./bitcoin-qt -server		# Launch the Bitcoin GUI from a second terminal window, -server necessary to use Bitcoin-cli command line interface in this script
read -n1
echo -e "Choose Wallet Spend Threshold and Total Keys\n\nMultisig wallets have an m-of-n form, where m stands for number of signatures required to spend funds and n stands for maximum number of keys that are permitted to sign.\n\nHow many secure, geographically distributed (5+ miles apart) back-up locations do you have to store keys at? (Recommended value is 7.)\n"
read -p "n=" n		# assign input to variable n, yeti wallet recommends 7 for number of signers
echo ''
echo -e "How many keys do you wish to be required to spend funds? Value for m must be less than or equal to n. (Recommended value is 3.)\n"
read -p "m=" m		# assign input to variable m, yeti wallet recommends 3 for spending threshold
echo -e "\nGenerating $n Wallets, please wait...\n"

# Seed Generation and Descriptor Creation

echo -n "wsh(multi($m" > xprv_desc			# form beginning of pay-to-witness-script-hash multisig descriptor with spend threshold m signatures, save string as descriptor
for (( i = 1 ; i <= $n ; i++ )); do			# loop thru idented steps n times
	./bitcoin-cli createwallet $i			#create a wallet
	./bitcoin-cli -rpcwallet=$i dumpwallet $i	# dump the wallet to a walletdump file, this contains xprv and seed
	sed '6q;d' $i | tail -c112 > xprv$i		# find line 6 in file, trim line to xprv data, save as xprv
	echo -n ",$(< xprv$i)/*" >> xprv_desc		# append ",xprv/*" to xprv_desc
	grep "hdseed=1" $i | head -c52 > ~/Documents/yetiseed$i		#search for line with hdseed, trims line to WIF seed, save as yetiseed
	done
echo -n "))" >> xprv_desc				# append )) to close parentheses from wsh(multi( and finish descriptor

# Get canonical xpub descriptor form, then create and backup the Watch-only wallet

# getdescriptorinfo returns the descriptor in canonical form without private keys, trim, save as descriptor
./bitcoin-cli getdescriptorinfo "$(< xprv_desc)" | sed '2q;d'| cut -d '"' -f4 > ~/Documents/Descriptor
# create blank descriptor wallet pubwallet.dat, disable prv keys for Watch-Only, no passphrase, avoid address reuse true, load on start-up true
./bitcoin-cli createwallet "pubwallet" true true "" true true true
# import descriptor, scan from current block, set as active descriptor
./bitcoin-cli -rpcwallet="pubwallet" importdescriptors '[{"desc": "'$(< ~/Documents/Descriptor)'", "timestamp": "now", "active": true}]'
# backup watch-only wallet as pubwallet.dat
./bitcoin-cli -rpcwallet="pubwallet" backupwallet ~/Documents/pubwallet

# Yeti wallet creation is done here.  Descriptor.txt and the yetiseed1-7.txt in home/Documents folder are enough to spend and restore the wallet for less than $50k stored.

# Get individual xpubs so they can be replaced one by one with corresponding xprv in descriptors for the n private key containing wallets and their backups

for ((i = 1 ; i <= $n ; i++)); do		# loop thru indented n times
	cut -d "," -f$(( i + 1 )) < ~/Documents/Descriptor | head -c111 > xpub$i			# chop descriptor apart by commas, find each xpub starting in field 2, trim to xpub data, save as xpub
	sed "s/$(< xpub$i)/$(< xprv$i)/" descriptor | cut -d "#" -f1 > desc_with_xprv$i	# replace xpub with xprv in descriptor, remove checksum, save as desc_with_xprv
	echo -n "#$(./bitcoin-cli getdescriptorinfo "$(< desc_with_xprv$i)" | sed '3q;d' | cut -d '"' -f4)" >> desc_with_xprv$i		# call getdescriptorinfo, get line 3, cut by ", select field 4 which is checksum, append #checksum to desc_with_xprv
	./bitcoin-cli createwallet "xprvwallet$i" false true "" false true true		# create blank descriptor wallet xprvwallet, disable private keys false, no passphrase, avoid address reuse false, load on startup true
	./bitcoin-cli -rpcwallet=xprvwallet$i importdescriptors '[{"desc": "'$(< desc_with_xprv$i)'", "timestamp": "now", "active": true}]'		# import desc_with_xprv to above wallet, scan from now, set as active descriptor in this wallet
	./bitcoin-cli -rpcwallet=xprvwallet$i backupwallet ~/Documents/xprvwallet$i	# backup wallet to xprvwallet .dat
	backup $(< ~/Documents/yetiseed$i)	# display seed words and prompt to make a CD-R of yetiseed .txt xprvwallet .dat and Descriptor.txt
	done

# Display Descriptor and a test Deposit Address

echo -e "\n\nThis is your Descriptor:\n\n$(< ~/Documents/Descriptor)\n\nYou will need it to spend or watch the balance of your wallet.\n\nPrint $n copies of Descriptor.txt and Burn pubwallet.dat and Descriptor.txt to $n CD-Rs. These files are located in your home/Documents/ folder which just opened, label the discs \"Watch Wallet\" and store a copy with each handwritten WIF NATO seed.\n\nWhen you have verified all printed copies are legible, Press Any Key to continue."
nautilus ~/Documents		# opens the folder containing the descriptor.
read -n1		# waits for any key press while user prints & burns
clear -x		# clears screen
echo -e "Make a Test Deposit\n\nRecommended: Make a ~0.001 BTC test deposit and practice spending from your new multi-signature wallet before Geographically Distributing your seed packets and storing significant funds.\n\nPress Alt+Tab to open Bitcoin Core, select pubwallet from the dropdown menu on upper right, then click 'Recieve' and 'Create new recieving address'. \n\nWhen you have sent the test deposit, shutdown this PC and insert the disc labled \"Watch Wallet\" into your Online PC."
read -n1
