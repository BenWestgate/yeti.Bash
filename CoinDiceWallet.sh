# Click Files on the Left hand bar, Navigate to home/bitcoin/bin/
# Move this file into the home/bitcoin/bin/ folder
# Right click in the /bin/ folder once more and select "open in terminal" and paste the following command:
# chmod +x CoinDiceWallet.sh
# Then paste the following command:
# ./CoinDiceWallet.sh

m=3		# yeti wallet recommends 3 for spending threshold
n=7		# yeti wallet recommends 7 for number of signers
user_rand=''	# stores user's choice for additional randomness
base2_format=$(printf '1'%256s | tr ' ' '0')		# store 1 followed by 256 zeros for keeping leading 0s on user dice rolled entropy

echo {1..9} {A..H} {J..N} {P..Z} {a..k} {m..z} | sed 's/ //g' > base58_alphabet		# create base58 alphabet, remove spaces between characters, save as base58_alphabet
echo "ONE TWO THREE FOUR FIVE SIX SEVEN EIGHT NINE ALPHA BRAVO CHARLIE DELTA ECHO FOXTROT GOLF HOTEL JULIET KILO LIMA MIKE NOVEMBER PAPA QUEBEC ROMEO SIERRA TANGO UNIFORM VICTOR WHISKEY X-RAY YANKEE ZULU alpha bravo charlie delta echo foxtrot golf hotel india juliet kilo mike november oscar papa quebec romeo sierra tango uniform victor whiskey x-ray yankee zulu" > toNATO	 # save the NATO Alphabet corresponding to base58_alphabet as toNATO
echo 80000000000000000000000000000000000000000000000000000000000000000001 > format	# empty (all 0s) hex private key with formatting bytes 0x80 for mainnet and 0x01 for compressed private keys.

# Display WIF NATO seeds and Confirm they are written down correctly



#######################################
# Display WIF NATO seeds and Confirm they are written down correctly
# Globals:
#   i
#   seed$i
#   base58_alphabet
#   filename
#   toNATO
# Arguments:
#   None
# Outputs:
#   Displays Seed Words on standard output
#######################################
paper_backup() {
	
	for letter in $(sed 's/./& /g' $filename'seed'$i); do	# loop thru each character of seed, assign character to letter, sed command spaces digits so each is considered individually
		echo $(( $(expr index $(< base58_alphabet) $letter) - 1 ))		# find index (position) of letter in base58_alphabet, subtract 1 from result so output ranges from 0-57
	done > WIFnum$i		# save list of numbers as WIFnum
		
	j=1		# j is counter since this will be used inside another loop,
	sum=0		# sum holds the sum of the base 58 values to create a 5th checksum column of seed words for yeti compatibility and easier error recovery
	for num in $(< WIFnum$i); do		# loop thru each line of WIFnum, assign value to num
		(( sum += num ))			# increase sum by num
		if [ $(( j % 4 )) != 0 ];		# if the counter is not evenly divisible by 4...
			then echo -n $num$' '	# print num and a space without a new line
			else echo $num$' '$(( sum % 58 )); sum=0		# when it is evenly divisible by 4, print num space 'remainder of sum divided by 58', assign 0 to sum, new line
		fi		# end if statement
		(( j++ ))		# increment counter
	done > WIFnumCheck$i		# save output to WIFnumCheck
	echo -e "\n\nWIF NATO (yeti-style) Seed $i\n\n"
	j=1
	for word in $(< WIFnumCheck$i); do		# loop thru each number in WIFnumCheck, assign value to word
		echo -n $(cut -d" " -f$(( word + 1 )) toNATO)		# add 1 to word, select that field from toNATO, using spaces as delimiters, print that NATO word without a new line
		if [ $(( j % 5 )) != 0 ];			# if the counter is not evenly divisible by 5...
			then echo -n ' '		# print a space without a new line
			else echo ''			# start a new line after the 5th word
		fi
		(( j++ ))
	done | column -s ' ' -t
	
	echo -e "\n\nWrite these 65 words down (case-sensitive) and Label them \"SEED $i\".  When you are finished press Enter.\n"		# prompt user to hand-write
	read -n1	# wait for any key press
	clear		# clear terminal so user must type from paper backup
	echo -e 'Confirm you have Written Down your seed words Correctly\n\nCover up the 5th Column of your written seed words. Type all Number Words as the Numeral, otherwise type the First Letter of each word. Start on line 1, left to right and continue through all rows until done.\n\n\tLIMA    ONE     victor  echo\n\tFOXTROT romeo   THREE   ECHO\n\nWould for example be entered as:  L1veFr3E\n\nInput on one line below without spaces and when finished press Enter.\n\n'
	read -n52 -e -p "WIF Seed $i: "		# reads 52 characters of input then continues to next line
	wait
	echo ''		# echo new line	
	j=1			# reset counter
	echo '' > retry		# empty string saved as retry, this is a flag thrown for typos
	
	cat $filename'seed'$i | while read -n1 letter; do		# loop thru each letter of seed, assign to letter.  TODO remove pipe to while which requires the retry flag to be a file
		if [ "$letter" != "$(echo $REPLY | cut -c$j)" ]; then		# if the letter does not match the user's input...
			echo "Word $j does not match. Check Row $(( (j - 1) / 4 + 1 )), Column $(( (j - 1) % 4 + 1 ))."	# error message prints word number and location that don't match the seed
			echo "fail" > retry		# save string "fail" as retry
		fi
		(( j++ ))
	done
	
	while [ "$(< retry)" == "fail" ]; do		# when retry is equal to "fail"...
		echo ''
		read -n52 -e -p "Try Again: "		# read 52 characters of input again
		wait
		echo ''
		j=1			# reset counter
		echo '' > retry	# save empty string to retry
		cat $filename'seed'$i | while read -n1 letter; do	# loop thru each letter of seed again, assign to letter TODO remove pipe to while
			if [ "$letter" != "$(echo $REPLY | cut -c$j)" ]; then
				echo "Word $j does not match. Check Row $(( (j - 1) / 4 + 1 )), Column $(( (j - 1) % 4 + 1 ))."
				echo "fail" > retry
			fi
			(( j++ ))
		done
	done
	echo -e "\nWIF Seed $i Matches."
}

#######################################
# Exclusive Or (XOR) two input arguments.
# Arguments:
#   Two 256-bit binary strings to be XOR'd
# Outputs:
#   Writes exclusive or of both arguments to standard output
#######################################
XOR() {
	for  (( j = 1 ; j <= 256 ; j++ )); do
		echo -n $(( $(echo $1 | cut -c$j) ^ $(echo $2 | cut -c$j) ))
	done
}

#######################################
# Gets binary randomness from seed$i, prompts for coin flips or dice rolls, XORs, and packages into WIF new_seed$i.
# Globals:
#   i
#   seed$i
#   base58_alphabet
#   base2_format
#   rolls
#   faces
# Arguments:
#   None
#######################################
add_rand() {
	for letter in $(sed 's/./& /g' seed$i); do		# loop thru each character of seed, assign that character to letter, the sed command spaces the digits so each is considered individually
		echo -n ' '$(( $(expr index $(< base58_alphabet) $letter) - 1 ))		# find index (position) of letter in base58_alphabet, subtract 1 from result so output ranges from 0-57
	done > seedNum$i		# save list of numbers as WIFnum
	j=$(wc -c < seed$i)		#set decrementor to number of characters in seed, 52
	for num in $(< seedNum$i); do
		(( j-- ))
		echo "$num*58^$j" | BC_LINE_LENGTH=0 bc
	done | paste -sd+ | BC_LINE_LENGTH=0 bc > bigNum$i
	echo 'obase=16;ibase=A;'$(< bigNum$i) | BC_LINE_LENGTH=0 bc > ExtendedPrivKey$i
	hex_WIF=$(< ExtendedPrivKey$i)
	echo 'obase=2;ibase=16;'$(< ExtendedPrivKey$i) | BC_LINE_LENGTH=0 bc | cut -c9-264 > RandomnessFromCore$i
	echo -e "\nSeed $i from Bitcoin Core\n\nWIF Format:           $(< seed$i)\nBase58 Decoded:      $(< seedNum$i)\nBase16 Decoded:       ${hex_WIF:0:2}  ${hex_WIF:2:64}  ${hex_WIF:66:2} ${hex_WIF:68}\nSeed $i Randomness:    $(< RandomnessFromCore$i)"

	if [ "$user_rand" == "coins" ]; then
		echo -e "\nEnter coin flips below on one line, without spaces, in exact sequence they were flipped, input tails as 0 and heads as 1.\n"
		read -n 256 -p "Input 256 Coin Flips: "
		echo -n $REPLY > user_entropy$i
		echo -e -n "\n\nSeed $i ⊕  Coin Flips: "
	else
		echo -e "\nEnter Dice Rolls below on one line, without spaces, in exact sequence they were rolled, input the number rolled, 1 through $faces.\n"
		if [ $faces -ge 10 ]; then		# tell them to type letters for face values 10+
			echo -e "If the number is 10 Use CapsLock to type 'A', 11 B, 12 C, 13 D, 14 E, 15 F, 16 G, 17 H, 18 I, 19 J, 20 K, ... \n"
		fi		
		read -n $rolls -e -p "Input $rolls Dice Rolls: "
		for (( j = 0; j<${#REPLY}; j++ )); do
			echo -n -e $( echo $num_shift | cut -c$(( $( expr index "$num_shift" "${REPLY:$j:1}" ) - 2 )) )
		done > base"$faces"rolls$i
		unpadded_entropy=$(echo "obase=2;ibase=$faces; $(< base"$faces"rolls$i)" | BC_LINE_LENGTH=0 bc)
		echo "obase=2;ibase=2;$unpadded_entropy + $base2_format" | BC_LINE_LENGTH=0 bc  | tail -c257 | head -c256 > user_entropy$i
		echo -e "\nBase2 Encoded Rolls:  "$(< user_entropy$i)
		echo -e -n "\nSeed $i ⊕  Dice Rolls: "
	fi
	
	XOR $(< user_entropy$i) $(< RandomnessFromCore$i) > XOR$i
	echo $(< XOR$i)
	echo 'obase=16;ibase=2;'$(< XOR$i) | BC_LINE_LENGTH=0 bc > XOR_hex$i
	echo 'obase=16;ibase=16;'$(< XOR_hex$i)'*100+'$(< format) | BC_LINE_LENGTH=0 bc > privkey$i
	#WIF seeds have format: a leading 0x80 byte, 32 entropy bytes, a 0x01 byte for compressed public keys, and then 4 checksum bytes which are the leading 4 bytes of the preceeding.
	echo -n $(< privkey$i) > privkeycheck$i
	echo -n $(xxd -r -p privkey$i | sha256sum | xxd -r -p | sha256sum | cut -b1-8 | tr a-z A-Z) >> privkeycheck$i
	hex_WIF=$(< privkeycheck$i)
	echo 'obase=58;ibase=16;'$(< privkeycheck$i) | BC_LINE_LENGTH=0 bc > base58key$i
	for digit in $(< base58key$i); do
		echo -n $(cut -b$((10#$digit+1)) base58_alphabet)
	done > new_seed$i
	echo -e "Base16 Encoded:       ${hex_WIF:0:2}  ${hex_WIF:2:64}  ${hex_WIF:66:2} ${hex_WIF:68}\nBase58 Encoded:      $(< base58key$i)\nWIF format:            $(sed 's/./&  /g' new_seed$i)"
}


gnome-terminal -- ./bitcoind		# Launch the Bitcoin Daemon in a second terminal window, necessary to use Bitcoin-cli command line interface in this script, command maybe xterm or konsole in other linux desktops
clear
echo -e "Custom Bitcoin Multi-signature Wallet Generator by Westgate Labs, LLC.\n\n\nWhen the other terminal window has been open several seconds, press Enter to continue."
read -n1
clear
echo -e "Choose Wallet Spend Threshold and Total Keys\n\nMultisig wallets have an m-of-n form, where m stands for number of signatures required to spend funds and n stands for maximum number of keys that are permitted to sign.\n\nHow many secure, geographically distributed (5+ miles apart) back-up locations do you have to store keys at? (Recommended value is 7.)\n"
read -p "n=" n		# assign input to variable n, 
echo -e "\nHow many keys do you wish to be required to spend funds? Value for m must be less than or equal to n. (Recommended value is 3.)\n"
read -p "m=" m		# assign input to variable m, 

echo "wsh(multi($m," > xprv_desc				# form beginning of pay-to-witness-script-hash multisig descriptor with spend threshold m signatures, save string as xprv_desc

echo -e "\n\nOptional: Add Additional Randomness\n\nYour Bitcoin Seed is the secret piece of data that allows you to control the bitcoin as long as you have access to it. Yeti uses Bitcoin Core to generate your seeds, but if you would like to provide additional randomness you can do so here.\n\nThis is not necessary. If there were concerns that Bitcoin Core was not random enough adding randomness would not require this script. This can't be harmful. You will not reduce the randomness of your seed no matter what data you provide. A good way to create randomness is to shake a box of coins and or roll fair dice.\n\nEnter 'coins' to flip coins or 'dice' to roll dice. To Skip, Press Enter.\n"
          	
read -p "Add randomness with: " user_rand
if [ "$user_rand" == "dice" ]; then
	echo -e "\nHow many faces do your dice have?"
	read faces
	rolls=$(echo "256 * l(2) / l($faces)+.99999999" | bc -l | cut -d"." -f1)		#calculates number of rolls to reach 256 bits entropy depending on faces of die.
	num_shift=$(echo {0..9} {A..Z})		# sequence of all numbers that may be entered for dice so I can shift each roll entered one the left since dice faces start at 1 not 0  
elif [ "$user_rand" == "coins" ]; then
	faces=2
else 
	filename=''		#original seed and wallet dump will be used to generate wallet since no randomness will be added
fi
		#generate seeds and add its xprv to xprv_desc descriptor file and confirm each seed was written down one by one.
for (( i = 1 ; i <= n ; i++ )); do			# loop thru idented steps n times
	echo -e "\n\nCreating Seed $i..."
	./bitcoin-cli createwallet $i			#create a wallet
	./bitcoin-cli -rpcwallet=$i dumpwallet $i	# dump the wallet to a walletdump file, this contains xprv and seed
	grep "hdseed=1" $i | head -c52 > seed$i	#search for line with hdseed, trims line to WIF seed, save as seed
	if [ "$user_rand" != "" ]; then
		add_rand
		echo -e "\n\nSetting New HD Seed $i..."
		./bitcoin-cli createwallet new_$i false true "" false false false		#create a new blank wallet, do not load on startup
		./bitcoin-cli -rpcwallet=new_$i sethdseed true $(< new_seed$i)		#sets the HD seed of this wallet to HD seed created by combining user randomness with original seed.  Will fail if new seed is not random enough (for example xoring original randomness with itself to get all 0s)
		./bitcoin-cli -rpcwallet=new_$i dumpwallet new_$i
		filename='new_'		#tell program to use new wallet dump and new seed files to get extended private keys and seed from
	fi
	sed '6q;d' $filename$i | tail -c112 > xprv$i		# find line 6 in wallet dump file, trim line to xprv data, save as xprv
	sed -i s/$/$(< xprv$i)"\/*,"/ xprv_desc		#append "xprv/*," to descriptor
	paper_backup
done

# Get canonical xpub descriptor form, then create and backup the Watch-only wallet TODO descriptor forms improperly when using dice rolls, test if fresh folders fixes first.

sed -i s/.$/"))"/ xprv_desc		# replace last character , of string with )) to close parentheses from wsh(multi( and finish xprv descriptor
wait
	# getdescriptorinfo returns the descriptor in canonical form without private keys, trim, save as descriptor
./bitcoin-cli getdescriptorinfo "$(< xprv_desc)" | sed '2q;d' | cut -d '"' -f4 > descriptor
	# create blank descriptor wallet pubwallet.dat, disable prv keys for Watch-Only, no passphrase, avoid address reuse true, load on start-up true
./bitcoin-cli createwallet "pubwallet" true true "" true true true
# import descriptor, scan from current block, set as active descriptor
./bitcoin-cli -rpcwallet="pubwallet" importdescriptors '[{"desc": "'$(< descriptor)'", "timestamp": "now", "active": true}]'		
./bitcoin-cli -rpcwallet="pubwallet" backupwallet pubwallet		# backup watch-only wallet as pubwallet.dat

# Get individual xpubs so they can be replaced one by one with corresponding xprv in descriptors for the n private key containing wallets and their backups

for (( i = 1 ; i <= $n ; i++ )); do		# loop thru indented n times
	cut -d "," -f$(( i + 1 )) < descriptor | head -c111 > xpub$i		# chop descriptor apart by commas, find each xpub starting in field 2, trim to xpub data, save as xpub
	sed "s/$(< xpub$i)/$(< xprv$i)/" descriptor | cut -d "#" -f1 > desc_with_xprv$i	# replace xpub with xprv in descriptor, remove checksum, save as desc_with_xprv
	# call getdescriptorinfo, get line 3, cut by ", select field 4 which is checksum, append #checksum to desc_with_xprv
	sed -i s/$/#$(./bitcoin-cli getdescriptorinfo "$(< desc_with_xprv$i)" | sed '3q;d' | cut -d \" -f4)/ desc_with_xprv$i
	# create blank descriptor wallet xprvwallet, disable private keys false, no passphrase, avoid address reuse false, load on startup true
	./bitcoin-cli createwallet "xprvwallet$i" false true "" false true true		
	# import desc_with_xprv to above wallet, scan from now, set as active descriptor in this wallet
	./bitcoin-cli -rpcwallet=xprvwallet$i importdescriptors '[{"desc": "'$(< desc_with_xprv$i)'", "timestamp": "now", "active": true}]'
	./bitcoin-cli -rpcwallet=xprvwallet$i backupwallet xprvwallet$i			# backup wallet to xprvwallet .dat
done

# Display Descriptor and a test Deposit Address

echo -e "\n\nThis is your Descriptor:\n\n$(< descriptor)\n\nYou will need it to spend or watch the balance of your wallet.\n\nPrint $n copies of descriptor.txt located in your home/bitcoin/bin/ folder and store a copy with each handwritten WIF NATO seed.\n\nWhen you have verified all printed copies are legible, Press Any Key to continue."
read -n1	# waits for any key press while user prints
clear		# clears screen
./bitcoin-cli -rpcwallet=pubwallet getnewaddress > testAddress		# get a new address from pubwallet, save as testAddress
echo -e "Recommended: Make a ~0.001 BTC test deposit and practice spending from your new multi-signature wallet before Geographically Distributing your seed packets and storing significant funds.\n\nHere is your wallet's first Deposit Address:\n\n$(< testAddress)\n\nWhen you have sent the test deposit, shutdown this PC and insert the disc labled \"Watch Wallet\" into your Online PC."
