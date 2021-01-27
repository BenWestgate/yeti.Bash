# Click Files on the Left hand bar, Navigate to home/bitcoin/bin/
# Move this file into the home/bitcoin/bin/ folder
# Right click in the /bin/ folder once more and select "open in terminal" and paste the following command:
# chmod +x CreateWallet.sh
# Then paste the following command:
# ./CreateWallet.sh

gnome-terminal -- ./bitcoind		# Launch the Bitcoin Daemon in a second terminal window, necessary to use Bitcoin-cli command line interface in this script

echo -e "Bitcoin Multi-signature Wallet Generator by Westgate Labs, LLC.\n\n\nWhen the other terminal window has been open several seconds, press Enter to continue."
read -n1
m=3		# yeti wallet recommended value of 3 for the spending threshold
n=7		# yeti wallet recommened value of 7 for the number of signers

# Seed Generation and Descriptor Creation

echo "wsh(multi($m," >descriptor			# form beginning of pay-to-witness-script-hash multisig descriptor with spend threshold m signatures, save string as descriptor
for ((i = 1 ; i <= $n ; i++)); do			# loop thru idented steps n times
	./bitcoin-cli createwallet $i			#create a wallet
	./bitcoin-cli -rpcwallet=$i dumpwallet $i	# dump the wallet to a walletdump file, this contains xprv and seed
	sed '6q;d' $i|tail -c112 >xprv$i		# find line 6 in file, trim line to xprv data, save as xprv
	grep "hdseed=1" $i|head -c52 >seed$i		#search for line with hdseed, trims line to WIF seed, save as seed
	sed -i s/$/$(cat xprv$i)"\/*,"/ descriptor	#append "xprv/*," to descriptor
	done; wait
sed -i s/.$/"))"/ descriptor; wait			#replace last character , of string with )) to close parentheses from wsh(multi( and finish descriptor

# Get canonical xpub descriptor form, then create and backup the Watch-only wallet

./bitcoin-cli getdescriptorinfo "$(<descriptor)" |sed '2q;d'|cut -d '"' -f4 >descriptor		# getdescriptorinfo returns the descriptor in canonical form without private keys, trim, save as descriptor
./bitcoin-cli createwallet "pubwallet" true true "" true true true				# create blank descriptor wallet pubwallet.dat, disable prv keys for Watch-Only, no passphrase, avoid address reuse true, load on start-up true
./bitcoin-cli -rpcwallet="pubwallet" importdescriptors '[{"desc": "'$(<descriptor)'", "timestamp": "now", "active": true}]'		# import descriptor, scan from current block, set as active descriptor
./bitcoin-cli -rpcwallet="pubwallet" backupwallet pubwallet		# backup watch-only wallet as pubwallet.dat

# Get individual xpubs so they can be replaced one by one with corresponding xprv in descriptors for the n private key containing wallets and their backups

for ((i = 1 ; i <= $n ; i++)); do		# loop thru indented n times
	cut -d "," -f$((i+1)) <descriptor|head -c111 >xpub$i		# chop descriptor apart by commas, find each xpub starting in field 2, trim to xpub data, save as xpub
	sed "s/$(cat xpub$i)/$(cat xprv$i)/" descriptor|cut -d "#" -f1 >desc_with_xprv$i		# replace xpub with xprv in descriptor, remove checksum, save as desc_with_xprv
	sed -i s/$/#$(./bitcoin-cli getdescriptorinfo "$(cat desc_with_xprv$i)"|sed '3q;d'|cut -d \" -f4)/ desc_with_xprv$i		# call getdescriptorinfo, get line 3, cut by ", select field 4 which is checksum, append #checksum to desc_with_xprv
	./bitcoin-cli createwallet "xprvwallet$i" false true "" false true true		# create blank descriptor wallet xprvwallet, disable private keys false, no passphrase, avoid address reuse false, load on startup true
	./bitcoin-cli -rpcwallet=xprvwallet$i importdescriptors '[{"desc": "'$(cat desc_with_xprv$i)'", "timestamp": "now", "active": true}]'		# import desc_with_xprv to above wallet, scan from now, set as active descriptor in this wallet
	./bitcoin-cli -rpcwallet=xprvwallet$i backupwallet xprvwallet$i			# backup wallet to xprvwallet .dat
	done

# Display WIF NATO seeds and Confirm they are written down correctly

echo {1..9} {A..H} {J..N} {P..Z} {a..k} {m..z} | sed 's/ //g' >base58alphabet		# create base58 alphabet, remove spaces between characters, save as base58alphabet
echo "ONE TWO THREE FOUR FIVE SIX SEVEN EIGHT NINE ALPHA BRAVO CHARLIE DELTA ECHO FOXTROT GOLF HOTEL JULIET KILO LIMA MIKE NOVEMBER PAPA QUEBEC ROMEO SIERRA TANGO UNIFORM VICTOR WHISKEY X-RAY YANKEE ZULU alpha bravo charlie delta echo foxtrot golf hotel india juliet kilo mike november oscar papa quebec romeo sierra tango uniform victor whiskey x-ray yankee zulu" >toNATO	# save the NATO corresponding to base58alphabet as toNATO

displayCheckSeed() {

	for letter in $(sed 's/./& /g' seed$i); do		# loop thru each character of seed, assign that character to letter, the sed command spaces the digits so each is considered individually
		echo $(($(expr index $(< base58alphabet) $letter)-1))		# find index (position) of letter in base58alphabet, subtract 1 from result so output ranges from 0-57
		done >WIFnum$i		# save list of numbers as WIFnum
		
	j=1; sum=0		# j is now the counter since this will be used inside another loop, sum keeps track of the sum of the base 58 values for creating a 5th checksum column in seed words for yeti compatibility and error recovery
	for num in $(<WIFnum$i); do		# loop thru each line of WIFnum, assign value to num 
		((sum+=num))			# increase sum by num
		if [ $((j%4)) != 0 ];		# if the counter is not evenly divisible by 4...
			then echo -n $num$' '	# print num and a space without a new line
			else echo $num$' '$((sum%58))' '; sum=0		# when it is evenly divisible by 4, print num space 'remainder of sum divided by 58', assign 0 to sum, new line
		fi		# end if statement
		((j++))		# increment counter
		done >WIFnumCheck$i		# save output to WIFnumCheck
	echo -e "\n\nWIF NATO (yeti-style) Seed $i\n\n"
	j=1
	for word in $(<WIFnumCheck$i); do		# loop thru each number in WIFnumCheck, assign value to word
		echo -n $(cut -d" " -f$((word+1)) toNATO)		# add 1 to word, select that field from toNATO, using spaces as delimiters, print that NATO word without a new line
		if [ $((j%5)) != 0 ];			# if the counter is not evenly divisible by 5...
			then echo -n ' '		# print a space without a new line
			else echo ''			# start a new line after the 5th word
		fi
		((j++))
		done|column -s ' ' -t
	echo -e "\n\nWrite these 65 words down (case-sensitive) and Label them \"Seed $i\".\n\nWhen you are finished press Enter."; read -n1 -e; clear		# prompt user to hand-write, wait for any key press, then clear terminal so they must type from paper backup
	echo -e 'Confirm you have Written Down your seed words Correctly\n\nCover up the 5th Column of your written seed words. You will Type the First Letter of each word and all numbers as the Numeral. Start on line 1, left to right and continue through all rows until done.\n\n\tLIMA    ONE     victor  echo\n\tFOXTROT romeo   THREE   ECHO\n\nWould for example be entered as:  L1veFr3E\n\nInput on one line below without spaces and when finished press Enter.\n\n'
	read -n52 -e -p "WIF Seed $i: "; wait; echo ''		# reads 52 characters of input then continues to next line
	
	j=1; echo '' >retry		# empty string saved as retry, this is a flag thrown for typos
	
	cat seed$i| while read -n1 letter; do		# loop thru each letter of seed, assign to letter
		if [ "$letter" != "$(echo $REPLY|cut -c$((j)))" ];		# if the letter does not match the user's input...
			then echo -e "Word $j does not match. Check Row "$(((j-1)/4+1))", Column "$(((j-1)%4+1))"."		# error message prints word number and location that don't match the seed
			echo "fail" >retry		# save string "fail" as retry
		fi
		((j++))
	done
	
	while [ "$(cat retry)" == "fail" ]; do		# when retry is equal to "fail"...
		echo ''; read -n52 -e -p "Try Again: "; wait; echo ''		# read 52 characters of input again
		j=1; echo '' >retry			# reset counter and save empty string to retry
		cat seed$i| while read -n1 letter; do	# loop thru each letter of seed again, assign to letter
			if [ "$letter" != "$(echo $REPLY|cut -c$(($j)))" ];
				then echo -e "Word $j does not match. Check Row "$(((j-1)/4+1))", Column "$(((j-1)%4+1))"."; echo 'fail'>retry
			fi
			((j++))
		done
	done
	echo -e "\nWIF Seed $i Matches."
	
}

for  ((i = 1 ; i <= n ; i++)); do	# loop thru seed display and check n times
	displayCheckSeed		# calls above function in curly braces
	done

# Display Descriptor and a test Deposit Address

echo -e "\n\nThis is your Descriptor:\n\n$(<descriptor)\n\nYou will need it to spend or watch the balance of your wallet.\n\nPrint $n copies of descriptor.txt located in your home/bitcoin/bin/ folder and store a copy with each handwritten WIF NATO seed.\n\nWhen you have verified all printed copies are legible, Press Any Key to continue."
read -n1	# waits for any key press while user prints
clear		# clears screen
./bitcoin-cli -rpcwallet=pubwallet getnewaddress >testAddress		# get a new address from pubwallet, save as testAddress
echo -e "Recommended: Make a ~0.001 BTC test deposit and practice spending from your new multi-signature wallet before Geographically Distributing your seed packets and storing significant funds.\n\nHere is your wallet's first Deposit Address:\n\n$(<testAddress)\n\nWhen you have sent the test deposit, shutdown this PC and insert the disc labled \"Watch Wallet\" into your Online PC."
