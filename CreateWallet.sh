# Click Files on the Left hand bar, Navigate to home/bitcoin/bin/
# Move this file into the home/bitcoin/bin/ folder
# Right click in the /bin/ folder once more and select "open in terminal" and paste the following command:
# bash CreateWallet.sh
# Be sure your system has either Brasero or Xfburn CD burning software installed and you can print.

m=3		# yeti wallet recommended value of 3 for the spending threshold
n=7		# yeti wallet recommended value of 7 for the number of signers
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
	echo -e "\n\nWIF NATO Seed $i\n\n"
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
		echo -e "WIF Key $i Matches.\n\n\nMake a Digital Backup\n\nLabel a blank CD-R \"SEED$i\", then insert it into your CD drive.\nA data CD project will open with the 3 files needed on this disc once you press Enter. Click 'Burn'.\nClose the burner software when finished.\n\nThe files xprvwallet$i, yetiseed$i and Descriptor from your home/Documents/ folder will be burned."
		read -n1
		brasero -d ~/Documents/xprvwallet$i ~/Documents/yetiseed$i ~/Documents/Descriptor bitcoin-qt	# launches a data project in brasero with the 3 files to burn
		xfburn -d ~/Documents/xprvwallet$i ~/Documents/yetiseed$i ~/Documents/Descriptor bitcoin-qt 	# launches a data project in xfburn with the 3 files to burn
		echo -e "\n\nPlace the written seed words and \"SEED $i\" disc in a non-descript envelope.\nFor Testing with small amounts, you may use USB flash drives but these aren't durable enough for long-term storage and make a thick, conspicuous seed packet.\nPress Enter to Continue."
		read -n1
	else
		echo -e "\n***Fix the above errors on The PAPER Backup.***\nThen press Enter."
		read -n1
		clear
		backup $1		# if retry is true, call the function again.
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
./bitcoin-qt -server &		# Launch the Bitcoin GUI from background process, -server necessary to use Bitcoin-cli command line interface in this script
read -n1

# Seed Generation and Descriptor Creation
for (( i = 1 ; i <= $n ; i++ )); do			# loop thru idented steps n times
	./bitcoin-cli createwallet $i			#create a wallet
	./bitcoin-cli -rpcwallet=$i dumpwallet $i	# dump the wallet to a walletdump file, this contains xprv and seed
	grep "hdseed=1" $i | head -c52 > ~/Documents/yetiseed$i		#search for line with hdseed, trims line to WIF seed, save as yetiseed
	xprv=$(grep "# extended private masterkey: " $i | tail -c112)"/*"		# find line 6 in file, trim line to xprv data, save as xprv	
	descriptor+=",$xprv"		# append ",xprv/*" to xprv_desc
	xprv_desc="wpkh($xprv)"#$(./bitcoin-cli getdescriptorinfo "wpkh($xprv)" | sed '3q;d' | cut -d '"' -f4)		# call getdescriptorinfo, get line 3, cut by ", select field 4 which is checksum, append #checksum to desc_with_xprv
	./bitcoin-cli createwallet "xprvwallet$i" false true "" false true true		# create blank descriptor wallet xprvwallet, disable private keys false, no passphrase, avoid address reuse false, load on startup true
	./bitcoin-cli -rpcwallet=xprvwallet$i importdescriptors '[{"desc":"'$xprv_desc'","timestamp": "now", "active": true}]'		# "import desc_with_xprv to above wallet, scan from now, set as active descriptor in this wallet
	./bitcoin-cli -rpcwallet=xprvwallet$i backupwallet ~/Documents/xprvwallet$i	# backup wallet to xprvwallet .dat
done

# Get canonical xpub descriptor form, then create and backup the Watch-only wallet
echo "wsh(multi($m$descriptor))"
# getdescriptorinfo returns the descriptor in canonical form without private keys, trim, save as descriptor
./bitcoin-cli getdescriptorinfo "wsh(multi($m$descriptor))" | sed '2q;d'| cut -d '"' -f4 > ~/Documents/Descriptor
# create blank descriptor wallet pubwallet.dat, disable prv keys for Watch-Only, no passphrase, avoid address reuse true, load on start-up true
cat ~/Documents/Descriptor
./bitcoin-cli createwallet "pubwallet" true true "" true true true
# import descriptor, scan from current block, set as active descriptor
./bitcoin-cli -rpcwallet="pubwallet" importdescriptors '[{"desc": "'$(< ~/Documents/Descriptor)'", "timestamp": "now", "active": true}]'
# backup watch-only wallet as pubwallet.dat
./bitcoin-cli -rpcwallet="pubwallet" backupwallet ~/Documents/pubwallet
# display seed words and prompt to make a CD-R of yetiseed .txt and Descriptor.txt
for (( i=1 ; i <= n ; i++ )); do backup $(< ~/Documents/yetiseed$i); done
# Yeti wallet creation is done here.  Descriptor.txt and the yetiseed1-7.txt in home/Documents folder are enough to spend and restore the wallet for less than $50k stored.

# Display Descriptor for printing and burning.
clear -x
echo -e "\nThis is your Descriptor:\n\n$(< ~/Documents/Descriptor)\n\nYou will need it to spend or watch the balance of your wallet.\n\n\nPrint a Paper Backup\n\nPrint 7 copies of Descriptor located in your home/Documents/ folder and store a copy with each handwritten WIF NATO seed.\n\nLibreOffice Writer will open the file when you press Enter. Press Ctrl+P in LibreOffice Writer to Print. Close LibreOffice Writer when done by pressing Alt+F4."
read -n1

libreoffice --writer ~/Documents/Descriptor		# launches libreoffice writer to print the descriptor
echo -e "\n\nMake a Digital Backup\n\nA new data CD project will open with the 2 files you need to burn to 7 discs once you press enter. Click 'Burn'.\nClose the burner software when finished. Label the discs \"Watch Only.\"\n\nThe files pubwallet and Descriptor from your home/Documents/ folder will be burned.\n\n"
read -n1
brasero -d ~/Documents/pubwallet ~/Documents/Descriptor	bitcoin-qt # launches a data project in brasero with the 2 files to burn
xfburn -d ~/Documents/pubwallet ~/Documents/Descriptor bitcoin-qt # launches a data project in xfburn with the 2 files to burn
echo -e "\nWhen you have verified all printed copies are legible, burned and labeled the discs, place one paper descriptor and one \"Watch Only\" disc into each envelope containing a handwritten seed.\nPress Any Key to continue."

read -n1		# waits for any key press while user prints & burns
clear -x		# clears screen
echo -e "Make a Test Deposit\n\nRecommended: Make a ~0.001 BTC test deposit and practice spending from your new multi-signature wallet before Geographically Distributing your seed packets and storing significant funds.\n\nPress Alt+Tab to open Bitcoin Core, select pubwallet from the dropdown menu on upper right, then click 'Recieve' and 'Create new recieving address'. \n\nWhen you have sent the test deposit, shutdown this PC and insert the disc labled \"Watch Only\" into your Online PC."
