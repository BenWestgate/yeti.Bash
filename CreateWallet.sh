# Click Files on the Left hand bar, Navigate to home/bitcoin/bin/
# Move this file into the home/bitcoin/bin/ folder
# Right click in the /bin/ folder once more and select "open in terminal" and paste the following command:
# chmod +x CreateWallet.sh
# Then paste the following command:
# ./CreateWallet.sh

gnome-terminal -- ./bitcoind		#Launches the Bitcoin Daemon in a second terminal window, needed to use Bitcoin-cli command line interface in this script.

echo -e "Bitcoin Multi-signature Wallet Generator by Westgate Labs, LLC.\n\n\nWhen the other terminal window has been open several seconds, press Enter to continue."
read -n1
m=3		#yeti wallet recommended value of 3 for the spending threshold
n=7		#yeti wallet recommened value of 7 for the number of signers
#forms beginning of witness script hash multisig descriptor with spend threshold m signatures, save string as descriptor
echo "wsh(multi($m,">descriptor		#
for ((i = 1 ; i <= $n ; i++)); do
	./bitcoin-cli createwallet $i
	./bitcoin-cli -rpcwallet=$i dumpwallet $i
	sed '6q;d' $i|tail -c112 >xprv$i
	grep "hdseed=1" $i|head -c52 >seed$i
	sed -i s/$/$(cat xprv$i)"\/*,"/ descriptor		#appends "xprv/*," to descriptor
	done; wait
sed -i s/.$/"))"/ descriptor; wait		#replace last character of string with )) to close parentheses from wsh(multi( and finish descriptor
 
./bitcoin-cli getdescriptorinfo "$(<descriptor)" |sed '2q;d'|cut -d '"' -f4 >descriptor		#getdescriptorinfo returns the descriptor in canonical form without private keys, trim, save as descriptor
./bitcoin-cli createwallet "pubwallet" true true "" true true true		#create blank descriptor wallet pubwallet.dat, disable prv keys for Watch-Only, avoid address reuse true, load on start-up
./bitcoin-cli -rpcwallet="pubwallet" importdescriptors '[{"desc": "'$(<descriptor)'", "timestamp": "now", "active": true}]'		#import descriptor, scan from current block, set as active descriptor
./bitcoin-cli -rpcwallet="pubwallet" backupwallet pubwallet		#backs up watch-only wallet
	
for ((i = 1 ; i <= $n ; i++)); do
	cut -d "," -f$((i+1)) <descriptor|head -c111 >xpub$i
	sed "s/$(cat xpub$i)/$(cat xprv$i)/" descriptor|cut -d "#" -f1 >desc_with_xprv$i
	sed -i s/$/#$(./bitcoin-cli getdescriptorinfo "$(cat desc_with_xprv$i)"|sed '3q;d'|cut -d \" -f4)/ desc_with_xprv$i
	./bitcoin-cli createwallet "xprvwallet$i" false true "" false true true
	./bitcoin-cli -rpcwallet=xprvwallet$i importdescriptors '[{"desc": "'$(cat desc_with_xprv$i)'", "timestamp": "now", "active": true}]'
	./bitcoin-cli -rpcwallet=xprvwallet$i backupwallet xprvwallet$i
	done

#display & check WIF NATO format
echo {1..9} {A..H} {J..N} {P..Z} {a..k} {m..z} | sed 's/ //g'>base58alphabet		#create base58 alphabet, save as base58alphabet
echo "ONE TWO THREE FOUR FIVE SIX SEVEN EIGHT NINE ALPHA BRAVO CHARLIE DELTA ECHO FOXTROT GOLF HOTEL JULIET KILO LIMA MIKE NOVEMBER PAPA QUEBEC ROMEO SIERRA TANGO UNIFORM VICTOR WHISKEY X-RAY YANKEE ZULU alpha bravo charlie delta echo foxtrot golf hotel india juliet kilo mike november oscar papa quebec romeo sierra tango uniform victor whiskey x-ray yankee zulu" >toNATO

displayCheckSeed() {

	for letter in $(sed 's/./& /g' seed$i); do
		echo $(($(expr index $(< base58alphabet) $letter)-1))
		done >WIFnum$i
		
	j=1; sum=0
	for num in $(<WIFnum$i); do 
		((sum+=num))
		if [ $((j%4)) != 0 ];
			then echo -n $num$' '
			else echo $num$' '$((sum%58))' '; sum=0
		fi
		((j++))
		done >WIFnumCheck$i
	echo -e "\n\nWIF NATO (yeti-style) Seed $i\n\n"
	j=1
	for word in $(<WIFnumCheck$i); do
		echo -n $(cut -d" " -f$((word+1)) toNATO)
		if [ $((j%5)) != 0 ];
			then echo -n ' '
			else echo ''
		fi
		((j++))
		done|column -s ' ' -t
	echo -e "\n\nWrite these 65 words down (case-sensitive) and Label them \"Seed $i\".\n\nWhen you are finished press Enter."; read -n1 -e; clear
	echo -e 'Confirm you have Written Down your seed words Correctly\n\nCover up the 5th Column of your written seed words. You will Type the First Letter of each word and all numbers as the Numeral. Start on line 1, left to right and continue through all rows until done.\n\n\tLIMA    ONE     victor  echo\n\tFOXTROT romeo   THREE   ECHO\n\nWould for example be entered as:  L1veFr3E\n\nInput on one line below without spaces and when finished press Enter.\n\n'
	read -n52 -e -p "WIF Seed $i: "; wait; echo ''
	
	j=1; echo '' >retry
	
	cat seed$i| while read -n1 letter; do
		if [ "$letter" != "$(echo $REPLY|cut -c$((j)))" ];
			then echo -e "Word $j does not match. Check Row "$(((j-1)/4+1))", Column "$(((j-1)%4+1))"."
			echo "fail" >retry
		fi
		((j++))
	done
	
	while [ "$(cat retry)" == "fail" ]; do
		echo ''; read -n52 -e -p "Try Again: "; wait; echo ''
		j=1; echo '' >retry
		cat seed$i| while read -n1 letter; do
			if [ "$letter" != "$(echo $REPLY|cut -c$(($j)))" ]; 
				then echo -e "Word $j does not match. Check Row "$(((j-1)/4+1))", Column "$(((j-1)%4+1))"."; echo 'fail'>retry
			fi
			((j++))
		done
	done
	echo -e "\nWIF Seed $i Matches."
	
}

n=7
for  ((i = 1 ; i <= n ; i++)); do
	displayCheckSeed
	done
	
echo -e "\n\nThis is your Descriptor:\n\n$(<descriptor)\n\nYou will need it to spend or watch the balance of your wallet.\n\nPrint $n copies of descriptor.txt located in your home/bitcoin/bin/ folder and store a copy with each handwritten WIF NATO seed.\n\nWhen you have verified all printed copies are legible, Press Any Key to continue."
read -n1
./bitcoin-cli -rpcwallet=pubwallet getnewaddress >testAddress
echo -e "\n\nRecommended: Make a ~0.001 BTC test deposit and practice spending from your new multi-signature wallet before Geographically Distributing your seed packets and storing significant funds.\n\nHere is your wallet's first Deposit Address:\n\n$(<testAddress)\n\nWhen you have sent the test deposit, shutdown this PC and insert the disc labled \"Watch Wallet\" into your Online PC."
