# Click Files on the Left hand bar, Navigate to home/bitcoin/bin/
# Move this file into the home/bitcoin/bin/ folder
# Right click in the /bin/ folder once more and select "open in terminal" and paste the following command:
# chmod +x SecretWallet.sh
# Then paste the following command:
# ./SecretWallet.sh

# If home/.bitcoin/wallets/ folder is not empty or bitcoin/bin/ folder has walletdump files manually move them out of the way first.
# To rerun script and get different Privacy keys you must kill bitcoind task or restart your machine, In addition to moving the above files.

# CONSTANTS

# create base58 alphabet, remove spaces between characters, store in variable base58_alphabet
base58_alphabet=$(echo {1..9} {A..H} {J..N} {P..Z} {a..k} {m..z} | sed 's/ //g')
# store the NATO Alphabet corresponding to base58_alphabet as array to_nato
to_nato=('ONE' 'TWO' 'THREE' 'FOUR' 'FIVE' 'SIX' 'SEVEN' 'EIGHT' 'NINE' 'ALPHA' 'BRAVO' 'CHARLIE' 'DELTA' 'ECHO' 'FOXTROT' 'GOLF' 'HOTEL' 'JULIET' 'KILO' 'LIMA' 'MIKE' 'NOVEMBER' 'PAPA' 'QUEBEC' 'ROMEO' 'SIERRA' 'TANGO' 'UNIFORM' 'VICTOR' 'WHISKEY' 'X-RAY' 'YANKEE' 'ZULU' 'alpha' 'bravo' 'charlie' 'delta' 'echo' 'foxtrot' 'golf' 'hotel' 'india' 'juliet' 'kilo' 'mike' 'november' 'oscar' 'papa' 'quebec' 'romeo' 'sierra' 'tango' 'uniform' 'victor' 'whiskey' 'x-ray' 'yankee' 'zulu')
xprv_format="0488ADE4000000000000000000"		# hex string for a master xprv that an HD seed would derive for m/0 index, chain code, 00 and privkey data and checksum bytes would follow.

cyan='\033[1;36m'
yellow='\033[1;33m'
blue='\033[1;34m'
nc='\033[0m' # No Color
######### Arrays
key_entropy=()		# stores privacy keys' randomness
xprv=()			# stores xprvs from privacy keys
secret_xprv=()		# stores secret xprvs derived from secret seeds
chain_code=()		# stores secret chain codes
privkey_data=()		# stores hprivate key data including leading 0 byte
cipher_xprv=()		# stores cipher xprvs

# FUNCTIONS

paper_backup() {
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
	
	echo -e "\n\nWrite these 65 words down (case-sensitive) and Label them \"SEED $i\".\n\nIf you are only testing SecretWallet.sh you can skip writing these down.\nWhen you are finished press Enter."		# prompt user to hand-write
	read -n1	# wait for any key press
	clear		# clear terminal so user must type from paper backup
	echo -e "Confirm you have Written Down your seed words Correctly\n\nIf you are just testing SecretWallet.sh and don't plan to use large amounts you may close this terminal.\n\nIf you lose access to more than $(( n - m )) of your Privacy Keys your bitcoin will be permanently lost.\n\nCover up the 5th Column of your written seed words. Type all Number Words as the Numeral, otherwise type the First Letter of each word. Start on line 1, left to right and continue through all rows until done.\n\n\tLIMA    ONE     victor  echo\n\tFOXTROT romeo   THREE   ECHO\n\nWould for example be entered as:  L1veFr3E\n\nInput on one line below without spaces and when finished press Enter.\n\n"
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
		echo -e "WIF Key $i Matches.\n\nPlace it in the envelope containing the CD-R labeled \"SEED $i\".\nThen press Enter to Continue."
		read -n1
	else
		echo -e "\n***Fix the above errors on The PAPER Backup.***\nThen press Enter."
		read -n1
		clear
		paper_backup $1		# if retry is true, call the function again.
	fi
}

test_deposit() {
# get a new address from input wallet, prints
echo -e -n "\nTest Decoy Wallet $1\n\nRecommended: Make a ~0.001 BTC test deposit and practice spending from Wallet $1 before Geographically Distributing your seed packets and storing significant decoy funds.\n\nHere is Wallet $1's first Deposit Address:\n\n$(./bitcoin-cli -rpcwallet=$1 getnewaddress)\n\nWhen the test deposit confirms, insert the disc containing $1.dat into your Online PC and open it with Bitcoin Core to spend it.\n
To continue meanwhile, Press Enter."
if (( h == 1 )); then
	echo -e "\n\n${yellow}Privacy Warning${nc}: Unfortunately, since not all privacy keys are in the descriptor, if you spend from this Decoy wallet it can reveal to a sophisticated attacker with 1 backup that this form of encryption has been used, he still needs a 2nd backup to actually see the secret. Testing the decoy is not necessary, if you can spend from the secret wallet, you can spend from your decoy wallets with sufficient keys."
fi
read -n1
}

#######################
# takes any length base58 string and echos the hex value
########################

base58_to_hex() {
# loop thru each character of $1, assign that character to letter, the sed command spaces the digits so each is considered individually, find index (position) of letter in base58_alphabet, subtract 1 from result so echo output ranges from 0-57, store in base58num, set decrementor to number of characters of input, calculate sum of all base58 digits, store in big_num, convert big_num to hexadecimal echo to standard output
	base58num=$(while read -n1 letter; do echo -n ' '$(( $(expr index "$base58_alphabet" "$letter") - 1 )); done < <(printf $1))
	len=${#1}		# length of the base58check input.
	big_num=$(for num in $base58num; do (( len-- )); echo "$num*58^$len" | BC_LINE_LENGTH=0 bc; done | paste -sd+ | BC_LINE_LENGTH=0 bc)
	hex=$(echo 'obase=16;ibase=A;'$big_num | BC_LINE_LENGTH=0 bc)
}

hex_to_base58check() {
	hex="$1$(checksum $1)"		# add checksum to input
	base58num=$(echo 'obase=58;ibase=16;'$hex | BC_LINE_LENGTH=0 bc)
	base58=$(for digit in $base58num; do
		echo -n ${base58_alphabet:$(( 10#$digit )):1}		# convert to base58 letters and numbers
	done)
}


decode_seed() {
	base58_to_hex $1
	key_entropy[$i]=${hex:2:64}
	echo -e "\nDecoding Key $i from Bitcoin Core...\n\nWIF Format:     $1\nBase58 Decoded:$base58num\nBase16 Key:  ${hex:0:2} ${hex:2:64} ${hex:66:2} ${hex:68}\nKey $i Entropy:  ${hex:2:64}"
}

decode_xprv() {
	base58_to_hex $1
	chain_code[$k]=${hex:25:64}
	privkey_data[$k]=${hex:89:66}
	echo -e "\nGetting Chain Code from ${blue}Secret $k${nc}'s Extended Private Masterkey...\n\nxprv Format:    ${blue}$1${nc}\nBase58 Decoded:$base58num\nBase16 Decoded: "0${hex:0:7} ${hex:7:2} ${hex:9:8} ${hex:17:8} ${hex:25:64} ${hex:89:2} ${hex:91:64} ${hex:155:8}"\nChain code $k:   ${hex:25:64}"
}

encode_seed() {
	hex_to_base58check $1		# add 4 checksum bytes, convert to base58
	echo -e "Hex Encoded: ${hex:0:2} ${hex:2:64} ${hex:66:2} ${hex:68}\nBase58 Encoded:$base58num\nWIF Format:     $base58"
}

encode_xprv() {
	hex_to_base58check $1		# add 4 checksum bytes convert to base58
	echo -e "Base16 Encoded: ${hex:0:8} ${hex:8:2} ${hex:10:8} ${hex:18:8} ${hex:26:64} ${hex:90:2} ${hex:92:64} ${hex:156:8}\nBase58 Encoded:$base58num\nxprv Format:    ${cyan}$base58${nc}"
}

xor() {
  {
    echo "${1}" | # start pipeline with first parameter
      fold -w 16 | # break into 16 char lines (note: 4-bit hex char * 16 = 64 bits)
      sed 's/^/0x/' | # prepend '0x' to lines to tell shell their hex numbers
      nl # number the lines (we do this to match corresponding ones)
    echo "${2}" | # do all the same to the second parameter
      fold -w 16 | 
      sed 's/^/0x/' | 
      nl
  } | # coming into this pipe we have lines: 1,...,n,1,...,n 
  sort -n | # now sort so lines are: 1,1,...,n,n
  cut -f 2 | # cut to keep only second field (blocks), ditching the line numbers
  paste - - | # paste to join every-other line with tabs (now two-field lines)
  while read -r a b; do # read lines, assign 'a' and 'b' to the two fields 
    printf "%#0${#a}x" "$(( a ^ b ))" # do the xor and left-pad the result
  done |
  sed 's/0x//g' | # strip the leading '0x' (here for clarity instead of in the loop)
  paste -s -d '\0' - | # join all the blocks back into to a big hex string
  tr a-z A-Z		# capitalize
}

checksum() {
# perform double sha256 hash and take first 8 hex characters (4 bytes)
    xxd -p -r <<<"$1" | openssl dgst -sha256 -binary | openssl dgst -sha256 -binary | xxd -p -c 80 | head -c 8 | tr a-z A-Z
}

# Begin Execution of Script here

# If terminal fails to open your linux desktop, right click in the bitcoin/bin folder open terminal and type "./bitcoind"
gnome-terminal -- ./bitcoind		# Launch the Bitcoin Daemon in a second terminal window, necessary to use Bitcoin-cli command line interface in this script. 
clear
echo -e "Secret Bitcoin Multi-signature Wallet Generator by Westgate Labs, LLC.\n\n\nWhen the other terminal window has been open several seconds, press Enter to continue."
read -n1
echo -e "Disconnect Network Cable\n\nIf you are using a network cable or laptop power cable unplug them now.\nAlso unplug all unnecessary peripherals, only a CD-R drive and printer are needed, if these are not yet installed, do so now.\nBecause this device will be used to generate private keys your Network Connection will be disabled when you press Enter.\n\nDo not reconnect this device to a network until you have erased the hard drive.\nFor Testing type 'nmcli networking on' afterwards in a terminal get back online."
read -n1
nmcli networking off		# if Testing, type 'nmcli networking on' in a new terminal to re-enable
nmcli -p networking
clear -x

echo -e "Choose Secret Wallet Spend Threshold and Total Privacy Keys\n\nMultisig wallets have an m-of-n form, where m stands for number of keys required to spend funds and n stands for number of privacy keys to be created.\n\nHow many secure, geographically distributed (5+ miles apart) back-up locations do you have to store keys at? (Recommended value is 6.)\n"
read -p "n=" n		# assign input to variable n
echo -e "\nHow many keys do you wish to be required to spend Secret Wallet funds? Value for m must be less than or equal to $n. (Recommended value is 3.)\n"
read -p "m=" m		# assign input to variable m

# TODO use recursive function call to generate all secret seeds for any privacy threshold, not just threshold 2. Use $# , how many arguments were passed to function, for XOR.
k=0
i=0
for (( i = 0 ; i <= n ; i++ )); do			# loop thru idented steps n + 1 times
	echo -e "\n\n\nCreating Privacy Key $i...\n"
	./bitcoin-cli createwallet $i			# create a wallet
	./bitcoin-cli -rpcwallet=$i dumpwallet $i	# dump the wallet to a walletdump file, this contains xprv and hdseed
	seed=$(grep "hdseed=1" $i | head -c52) 	# search for line with hdseed, trims line to WIF seed, store in seed[]
	decode_seed $seed		# converts seed to hex to see entropy payload
	for (( j = 1 ; j < i ; j++ )); do
		(( k++ ))
		echo -e "\n\nCreating Secret Seed $k...\n"
		echo -e "Key $j Entropy:  ${key_entropy[$j]}\nKey $i Entropy:  ${key_entropy[$i]}"
		echo -e -n "Key $j ⊕  Key $i: "
		key=$(xor ${key_entropy[$j]} ${key_entropy[$i]})	# combine entropy from key j and i to make new key
		echo $key		# prints result	
		encode_seed 80${key}01		# WIF seeds have format: leading 0x80 byte, 32 entropy bytes, a 0x01 byte for compressed public keys
		./bitcoin-cli createwallet secret$k false true "" false false false	# create a new blank wallet named secret, do not load on startup
		./bitcoin-cli -rpcwallet=secret$k sethdseed true "$base58"		# sets the HD seed of this wallet to secret HD seed created by xoring
		./bitcoin-cli -rpcwallet=secret$k dumpwallet secret$k			# dumps wallet to get xprv from secretSeed
		secret_xprv[$k]=$(sed '6q;d' secret$k | tail -c112)			# find line 6 in wallet dump file, trim to xprv data, store in secret_xprv[]
		secret_desc+=",${blue}${secret_xprv[$k]}${nc}/*"			# appends ",secret_xprv[]/*" to secret_desc, colors secret_xprv[] blue.
		decode_xprv ${secret_xprv[$k]}		# converts xprv to hex
		echo -e "\nCreating ${cyan}Cipher $k${nc}'s Extended Private Masterkey...\n\nKey 0 Entropy:  ${key_entropy[0]}\nChain code $k:   ${chain_code[$k]}"
		echo -e -n "Key 0 ⊕  CC $k:  "
		cc_xor=$(xor ${key_entropy[0]} ${chain_code[$k]})		
		echo $cc_xor
		encode_xprv $xprv_format$cc_xor${privkey_data[$k]}
		cipher_xprv[$k]=$base58		# append cipher xprv to cipher array
		cipher_desc+=",${cyan}$base58${nc}/*"		# append ",cipher_xprv[]/*" to cipher_desc, color cipher_xprv[] cyan
	done
	if (( i > 0 )); then
		xprv[$i]=$(sed '6q;d' $i | tail -c112)	# find line 6 in wallet dump file, trim line to xprv data, store in xprv[]
		echo $seed > ~/Documents/seed$i		# places seed backup in home/Documents/ folder
		#paper_backup $seed			# have not decided if best to confirm words here or at the end.
		echo -e "\n\nPrivacy ${yellow}Key $i${nc}'s Extended Private Masterkey: ${yellow}${xprv[$i]}${nc}"
	fi
done
l=1
add=1
for (( i=2 ; i < m ; i++ )); do
	(( l += add ))		# calculate spend threshold l for secret descriptor multi, may differ from m but will function equivalent.
	(( add++ ))
done	
secret_desc="wsh(multi($l"$secret_desc
secret_desc+="))"		# add closing parentheses
echo -e "\n\n\n\nThis is your Extended Private Masterkey Secret Descriptor: $secret_desc\n"
secret_desc=${secret_desc//'\033[1;34m'}	# remove blue
secret_desc=${secret_desc//'\033[0m'}		# remove no color
# getdescriptorinfo returns the secret descriptor in canonical form without private keys, trim, save as secret descriptor
./bitcoin-cli getdescriptorinfo "$secret_desc" | sed '2q;d' | cut -d '"' -f4 > secret_descriptor

echo -e "This is your Extended Public Masterkey Secret Descriptor:  $(< secret_descriptor)\n"

# create and backup the Watch-only wallet

# create blank descriptor wallet secretpubwallet.dat, disable prv keys for Watch-Only, no passphrase, avoid address reuse true, load on start-up true
./bitcoin-cli createwallet "secretpubwallet" true true "" true true true
# import descriptor, scan from current block, set as active descriptor
./bitcoin-cli -rpcwallet="secretpubwallet" importdescriptors '[{"desc": "'$(< secret_descriptor)'", "timestamp": "now", "active": true}]'		
echo -e "\n**Test Secret Wallet**\n\nRecommended: Make a ~0.001 BTC Test Deposit and practice spending from the Secret Wallet before Geographically Distributing your key packets and storing significant funds.\n\nHere is your secret wallet's first Deposit Address:\n\n$(./bitcoin-cli -rpcwallet="secretpubwallet" getnewaddress)\n\nWhen the test deposit confirms, attempt recovery on a blank Live OS using SecretRestore.sh and Bitcoin Core to spend it.\n\nTo continue meanwhile, Press Enter."
read -n1

# TODO in PrivateWallet.sh, encrypt this secretpubwallet file for all combos of 2 in n, here it would wreck plausible deniability about encryption use.

space_left=$(( 16 - k ))		# multisig scripts can have maximum 16 keys, stores remaining space after k cipher keys
if (( spaceleft < n )); then	# stores lessor of space_left or n, the max privacy keys that can be added to the cipher
	max_decoy_keys=$space_left
else
	max_decoy_keys=$n
fi	
if (( max_decoy_keys > 1 )); then
	echo -e "\nChoose Decoy Wallet Spend Threshold and Added Privacy Keys\n\nThis script Creates a Decoy Multisig wallet with an o of h+$k form, where o stands for number of keys required to spend decoy funds, h stands for number of Privacy Keys added to the decoy and $k Cipher Keys corresponding to the Secret Wallet.\n\n1 OR $n Privacy Keys are added for plausible deniability.\nWith h=1 an attacker with 1 backup can Not know the wallet is encrypted until you spend from a decoy.\nWith h=$n+ an attacker with all backups might Not know the wallet is encrypted even if you spend from the decoy. The maximum value you can use is $max_decoy_keys.\n\nHow many Privacy Keys do you wish to add to the $k Cipher Keys? (Recommended value is $n, when possible.)\n"
	read -p "h=" h		# assign input to variable h
else
	echo -e "\nChoose Decoy Wallet Spend Threshold\n\nThis script Creates a Decoy Multisig wallet with an o of $k+1 form, where o stands for number of keys required to spend decoy funds, $k the Cipher Keys corresponding to the Secret Wallet and 1 Privacy Key added for plausible deniability.\nIf an attacker has 1 backup, he can Not know the wallet has been encrypted."
	h=1
fi
p=$(( k + h ))		# total keys in cipher descriptor including privacy keys and cipher keys
echo -e "\nHow many keys do you wish to be required to spend funds from the $p key decoy?\nValue for o must be less than or equal to $p.\nThe decoy can be spent without Secret Keys for o=$h or less. (Recommended value is around $(( p * 3 / 7)) to $(( p * 2 / 3 )), 2 or 3 are also plausibly deniable values.)\n"
read -p "o=" o		# assign input to variable o
echo -e "\n\n"
cipher_desc+="))"		# add closing parentheses

# Add the backup's privacy key's xprv (in plaintext) to the cipher descriptor so it appears to belong.  Then Display Descriptor and a test Deposit Address

##echo -e "This is your Extended Private Masterkey Cipher Descriptor without Privacy Keys' Extended Private Masterkeys added: $cipher_desc\n\n"
# probably no use showing the cipher descriptor before privacy key xprvs have been added now that it's color coded.

desc="wsh(multi($o"		# witness script hash, multi threshold o
len=${#desc}			# length of desc in case o > 9 and shifts the digits.
cipher_desc=$desc$cipher_desc	# prepends wsh(multi($o to cipher_desc
for (( i = 1 ; i <= n ; i++ )); do
	key_pos=$(( $RANDOM % (( k + 1 )) * 131 + len ))		# chooses a random position in the cipher descriptor to add the privacy key's xprv.
	echo -e -n "This is your ${cyan}Cipher${nc} Extended Private Masterkey Descriptor with Privacy ${yellow}Key $i${nc}'s Extended Public Masterkey added: "
	desc="${cipher_desc:0:$key_pos},${yellow}${xprv[$i]}${nc}/*${cipher_desc:$key_pos}"		# adds ,xprv[]/* to the random position in descriptor, color yellow
	echo -e $desc
	if (( h == 1 )); then
		desc=${desc//'\033[1;36m'}	# remove cyan
		desc=${desc//'\033[1;33m'}	# remove yellow
		desc=${desc//'\033[0m'}		# remove no color
		./bitcoin-cli getdescriptorinfo "$desc" | sed '2q;d' | cut -d '"' -f4 > ~/Documents/Descriptor	# save Descriptor.txt in home/Documents/ folder
		echo -e "\nThis is your Cipher Extended Public Masterkey Descriptor with Privacy Key $i's Extended Public Masterkey added: $(< ~/Documents/Descriptor)\n"
		# create blank descriptor wallet pubwallet.dat, disable prv keys for Watch-Only, no passphrase, avoid address reuse true, load on start-up true
		./bitcoin-cli createwallet "pubwallet$i" true true "" true true true
		# import descriptor, scan from current block, set as active descriptor
		./bitcoin-cli -rpcwallet="pubwallet$i" importdescriptors '[{"desc": "'$(< ~/Documents/Descriptor)'", "timestamp": "now", "active": true}]'		
		./bitcoin-cli -rpcwallet="pubwallet$i" backupwallet pubwallet$i		# backup watch-only wallet as pubwallet.dat
		echo -e "\nThis is Cipher Descriptor $i of $n:\n$(< ~/Documents/Descriptor)\n\nYou will need it to spend or watch the balance of this decoy wallet as well as to decrypt your secret descriptor.\n\nBurn a CD-R and Print a legible copy of Descriptor.txt located in your home/Documents/ folder. Label the Descriptor.txt disc \"Watch Only\".\nAlso from that folder Burn a CD-R with both Descriptor.txt and seed1.txt (Do Not Print!) on it, label that disc \"SEED $i\" and keep these 3 items in an envelope.\n\nWhen you have burned both CD-Rs, labled them, verified the printed copy is legible and placed all in envelope, Press Any Key to continue."
		read -n1	# waits for any key press while user prints
		test_deposit "pubwallet$i"
	else
		(( k++ ))
		cipher_desc=$desc
		echo -e "${yellow}$i${nc} of $n Privacy ${yellow}Key${nc}s' Extended Public Masterkeys have been added.\n"
	fi
done
if (( h >= n )); then	# TODO support all values h. they should reuse as many of the keys as possible so the max number of cipher descriptors are identical for better plausible deniability. and make new keys if h>n+1 (as we can reuse seed 0's xprv) new keys can be xor combos of seed 0 and a higher seed to maximize chance we can sign with them if we know encryption is used.
	echo -e "This is your Extended Private Masterkey ${cyan}Cipher${nc} Descriptor with all Privacy ${yellow}Keys${nc}' Extended Public Masterkeys added: $desc\n\n"
		desc=${desc//'\033[1;36m'}		# remove cyan
		desc=${desc//'\033[1;33m'}		# remove yellow
		desc=${desc//'\033[0m'}		# remove no color
	./bitcoin-cli getdescriptorinfo "$desc" | sed '2q;d' | cut -d '"' -f4 > ~/Documents/Descriptor
	echo -e "This is your Extended Public Masterkey Cipher Descriptor with all Privacy Keys' Extended Public Masterkeys added:  $(< ~/Documents/Descriptor)\n\n"
	# create blank descriptor wallet pubwallet.dat, disable private keys for Watch-Only, no passphrase, avoid address reuse true, load on start-up true
	./bitcoin-cli createwallet "pubwallet" true true "" true true true
	# import descriptor, scan from current block, set as active descriptor
	./bitcoin-cli -rpcwallet="pubwallet" importdescriptors '[{"desc": "'$(< ~/Documents/Descriptor)'", "timestamp": "now", "active": true}]'		
	./bitcoin-cli -rpcwallet="pubwallet" backupwallet pubwallet		# backup watch-only wallet as pubwallet.dat
	clear -x
	echo -e "\n\nThis is your Steganographic Cipher Descriptor:\n$(< ~/Documents/Descriptor)\n\nYou will need it to spend or watch the balance of this decoy wallet as well as to decrypt your secret descriptor.\n\nBurn $n CD-Rs of Descriptor.txt, label them \"Watch Only\" and Print $n legible copies of Descriptor.txt located in your home/Documents/ folder. You will store both with each handwritten WIF NATO Privacy Key.\n\nWhen you have burned all $n CD-Rs, labled them \"Watch Only\" and verified all printed copies are legible, Press Any Key to continue."
	read -n1	# waits for any key press while user prints
	for (( i = 1 ; i <= n ; i++ )); do
		echo -e "\nBurn seed$i.txt and Descriptor.txt to CD-R\n\nAlso in home/Documents/ folder find seed$i.txt and Descriptor.txt and Burn a CD-R with both files on it, label that disc \"SEED $i\" and store with a \"Watch Only\"  disc and your printed Descriptor.txt in an envelope.\n\nWhen you have burned the CD-R and placed all three in an envelope, Press Any Key to continue."
		read -n1 # waits for any key press while user burns
	done
	echo ''
	test_deposit "pubwallet"
fi

for (( i = 1 ; i <= n ; i++ )); do
	paper_backup $(< ~/Documents/seed$i)
done # confirm the seed words.
# It would be better for usage to do this first, as can confirm before a backup file is made or funds could be lost
# but worse for testing as you can't see the all xprvs from earlier keys when the screen clears.
# There is no way to "unclear" the screen. Short of launching a new terminal window in which to confirm your words in a different script.


##test_deposit $i  # TODO: prompt at end how many privacy keys and/or pairs of 2 they'd like to load and randomly draw from secret seed and key addresses until that number is reached, then shuffle and tell them to fund all addresses displayed without labeling them. the pairs of two should include 1 privacy key that was loaded ie key1,key2,key3... pair 12, pair 13, pair 23... etc  SecretRestore.sh spends seeds for an m=2
