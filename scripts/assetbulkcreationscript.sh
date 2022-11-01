#!/bin/bash
echo "
#--------------------------------------------------------------------------------
#                                                                                  
#  Application for creating asset in bulk in the fastest way possible   
#  with the combination of goal scripts and atomic transfers and inner TXN.
#  Assets are created by an application account (Escrow) and then opted in by the 
#  Creator. The assets are then transfered to the Creator of the app.      
# 
#  This script needs alteration in order to function 
#  
#  
#
#
#  THE VALUES IN THE SMARTCONTRACT NEED TO BE CHANGED OR THE AMOUNT OF ASSETS 
#  CREATED WILL BE DEFAULTED TO A PRODUCT OF 240. 
#  
#  DISCLAIMER, THIS SCRIPT IS FOR EDUCATIONAL PURPOSES ONLY AND MADE 
#  FOR A PRIVATE NETWORK OR SANDBOX INSTANCE. THIS SCRIPT HAS NOT YET BEEN AUDITED
#  IT IS NOT AVICED TO USE IT IN A PRODUCTION ENVIRONMENT!
#  This script will be Updated on a regular basis and is part of the development of 
#  CarbonStack.
#  Version:      2.0
#  Last Updated: 28.10.2022
#  MAINTAINER:   tobias.thiel@carbonstack.de                                                                             
#_________________________________________________________________________________"


#The current iteration requires input from the user in order to function. 
#TODO: Create a Trigger, in JS/Frontend. At the current stage the URL to the 
#project has to be set in a later iteration this will be supplied by an external source.
#This iteration also includes a hash calculcator, that calculates the checksum of the 
#selected ARC (ATM USER INPUT SHOULD BE FILETRIGGER). This hash is then cut and exported.
#TODO: Clean up the usability of the ARC. 
#The script also reads the content of the ARC and sets the parameters later needed for the asset creation. 
#CAUTION AS THIS IS A SCRIPT MADE FOR AND BY CARBONSTACK; SOME PARAMETERS ARE DIRECTLY SET IN THE SCRIPT!
#This iteration can create any amount of Assets was tested up to 55555. This script calls
#a Javascript program used to calculate the optimal (based on 2 loops of innerTxns and direct 
#creation calls)to minimize the time needed to create the defined amount of assets. The javascript
#programm then passes the Variables K1,K2,K3 for the loop calls and X1 X2 and Y1 Y2 for the Caller
#and Creation Smartcontract.

#This part of the script removes all the old txt files associated to previous asset creations. 
#If not deleted the script should overwrite the data inside the files aswell. 
#TODO: Construct one single text/Json File readable by the pyteals
#TODO: Make version with combined OPT-IN/TRANSFER WORK (easy outside of sandbox). 

rm -f x1.txt
rm -f x2.txt
rm -f y1.txt
rm -f y2.txt       
rm name.txt
rm unit.txt 
rm url.txt 
rm pid.txt 
rm hash.txt

#TODO: Implement FRONTEND to URL 
echo "Enter the URL of the TOKEN Metadata"
read url
#Menue for selecting the ARC needed for the project. 
#Should be in the FRONT END LATER. 
PS3="Use number to select a file or 'stop' to cancel: "

        # allow the user to choose a file
        select filename in *.json
            do
                # leave the loop if the user says 'stop'
                if [[ "$REPLY" == stop ]]; then break; fi

                # complain if no file was selected, and loop to ask again
                if [[ "$filename" == "" ]]
                then
                echo "'$REPLY' is not a valid number"
                continue
                fi
                
                # now we can use the selected file
                # Builds the SHA HASH and cute the last 32 Bytes and saves them externally. 
                #TODO SHOULD BE INTERNALLY but does not really matter. 
                echo $(shasum -a 256 $filename) | cut -c 34-64    > hash.txt
                # it'll ask for another unless we leave the loop
                break
            done
            

#HARD CODED UNITS
unit="CO2e"
#READ TOKEN TYPE FROM THE ARC
name=($(jq -r '.name' $filename))
#READS THE PROJECT ID FROM THE ARC.
pid=($(jq -r '.title' $filename))
echo "$pid"
echo "$name" 

echo "$unit" > unit.txt
echo "$name" > name.txt
echo "$url" > url.txt
echo "$pid" > pid.txt



#Executes the calculation script. 
node index.js 

#Get iterations needed from the calculation. 
k1=($(jq -r '.K1' new.json)) 
k2=($(jq -r '.K2' new.json)) 
k3=($(jq -r '.K3' new.json)) 
#Get the caller and asa-creation loop iterations
x1=($(jq -r '.X1' new.json)) 
x2=($(jq -r '.X2' new.json))
y1=($(jq -r '.Y1' new.json)) 
y2=($(jq -r '.Y2' new.json)) 

#forward the variables to the pyTEAL readable format
#TODO: transform it into one form that is readable by the pyTEAL 
#k1-k3 are required for the script
echo "$k1"
echo "$x1" > x1.txt
echo "$y1" > y1.txt
echo "$k2"
echo "$x2" > x2.txt
echo "$y2" > y2.txt
echo "$k3"


#Sets the total assets that need to be created and all associated with it.
amount_assets=$(($k1*$x1*$y1+$k2*$x2*$y2+$k3))
echo "$amount_assets"
k=$(($k1+$k2+$k3))
        amount_algo=$(($amount_assets*100000 + 100000))
        fin=$(($amount_assets+1))
echo "total amount of assets: $amount_assets"
echo "Holding capital: $amount_algo"
echo "amount of iterations needed: $k"
echo "##########################################################################################"



#This part moves to the folder where the pyteal of the ASA-Creation 
#is present and the teal file is compiled to.
#Make sure to rename the teal file to something related to your goal. 
#The clear.teal should also be compiled here, for simplicity a basic clear.teal is present.
cd /Users/tobiasthiel/Documents/Carbonstack/sandbox/tutorial/pyteal-course/build/
rm approval.teal
python3 asacontractloopv2.py > approval.teal
cd /Users/tobiasthiel/Documents/Carbonstack/sandbox
echo "##########################################################################################"

#Now the accounts are set and displayed. The following script assumes that in the account list the top account
#is supposed to be the default account (should be the default account may need alterations for that in future).
account_name=$(./sandbox goal account list|awk '{ print $2 }'|head -1)
echo "Admin account of the app $account_name"
echo "##########################################################################################"

#These lines create the smart contract and set the variable to the deployed APPid. 
#The Appid is then saved in an external file that is later read by the caller pyteal.
#In addition the escrow account is also saved to a variable for later calls, including the intial funding of it.
asa_app_id=$(./sandbox goal app create --creator $account_name --approval-prog /data/build/approval.teal --clear-prog /data/build/clear.teal --global-byteslices 1 --global-ints 1 --local-byteslices 0 --local-ints 0 |awk '{ print $6 }'|tail -1)
echo "the app id is $asa_app_id"
echo $asa_app_id > appid.txt
escrow_account=$(./sandbox goal app info --app-id $asa_app_id |awk '{ print $3 }'|head -n $[ 2 ] | tail -n 1)
echo "the creator account will be $escrow_account"
echo "Funding the app account"
./sandbox goal clerk send -f $account_name -t $escrow_account -a $amount_algo > /dev/null &
echo "##########################################################################################"



#Per default this script is creating at most 240 assets in order to do that it is required to have a caller contract call the creation contract 15 times.
#This is enabled due to the parameters of X and Y st above. 
#For that to happen the caller contract needs to be compiled as well. The Appid was saved beforehand.
cd /Users/tobiasthiel/Documents/Carbonstack/sandbox/tutorial/pyteal-course/build/
python3 asa_callerv2.py > approval2.teal
cd /Users/tobiasthiel/Documents/Carbonstack/sandbox
echo "##########################################################################################"

#Coming to the execution of the ASA creation. The caller app is created its ID is then saved for the later call-
#The loop is then formed based on the iteration neede calculated beforehand. 
#explanation of the Asa creation call: 
#The creation call is triggered by the app caller smart contract which is triggered directly in the loop. The maximum fee is sent in order to reserve the required opcode. 
#The and '&' symbol is required in order to allow your processor to perform the call as a multithread application.
#The sleeptimer in the loop is required in order to ensure that all the transaction are actually packed inside a block this is highly dependend on blocktime/processorspeed/corecount
caller_app_id=$(./sandbox goal app create --creator $account_name --approval-prog /data/build/approval2.teal --clear-prog /data/build/clear.teal --global-byteslices 1 --global-ints 1 --local-byteslices 0 --local-ints 0 |awk '{ print $6 }'|tail -1)
echo "the contract caller id $caller_app_id"
#The "large" batch is (based on k1 x1 and y1) is created
for ((i = 1 ; i<=$k1; i++))
do
./sandbox  goal app call --app-id $caller_app_id --app-arg "str:create_asa"  -f $account_name --foreign-app $asa_app_id --fee 320000  > /dev/null  & 
o=$((($i)*$x1*$y1))
#This line allows the count to move forward without printing everything in a new line. 
echo -ne "$o/$amount_assets \033[0K\r"
sleep 0.5
done
#set j so the count goes onward
j=$o
#The "medium" batch (based on k2 x2 and y2) is created here.
for ((i = 1 ; i <= $k2; i++))
do
#basic calculation to for smaller batch
o=$(($j+($i)*$x2*$y2))
./sandbox  goal app call --app-id $caller_app_id --app-arg "str:rerun_asa"  -f $account_name --foreign-app $asa_app_id --fee 320000   > /dev/null  & 
echo -ne "$o/$amount_assets \033[0K\r"
sleep 0.5
done
j=$o

#The small single creations happen here based on k3. 
for ((i = 1 ; i <= $k3; i++))
do

./sandbox  goal app call --app-id $caller_app_id --app-arg "str:final_asa"  -f $account_name --foreign-app $asa_app_id --fee 10000 > /dev/null  & 
sleep 0.5
o=$(($j+$i))
echo -ne "$o/$amount_assets \033[0K\r"
done
echo "##########################################################################################"
echo "Waiting for chain to get cought up!"
sleep 15
echo "List of ASAs in createdASA.txt"
./sandbox goal account info -a $escrow_account > createdASA.txt
sleep 5

#The opt-in and initial transaction are also handled by the script. As a work around there are two alternatives for handling the opt-in and the transaction. 
#Per default the goal commands can only display up to 50k ASAs hold. Therefore, if the amount is less than the mentioned limit the script will read the first
#and the last ASA held by the account. If more than 50k ASAs were created the script siply starts by ASA with the ID 1 (only works if no ASA were created in the network),
#uncomment the lines in the if clause and comment the line s=1 if you have already created ASAs in the network. The script assumes that there wont be any app- or asacreation 
#happening in the meantime. Else the buffer calculations should be altered. The buffer in that case is needed in order to account for the creation gaps as each call of the caller
#is seen as a transaction on the chain increasing the id by 1. The transactions cannot be grouped as there inevitable will be transactions for ASA not created. This would fail
#thus the group would fail.

if [ $amount_assets -ge 50000 ]
then
#echo "Enter the first AssetID for Opt-In and Transfer"
#read s
s=1 
buffer=$((($k1+$k2+$k3)*16))
echo "$buffer"
fin=$(($amount_assets + $buffer))
e=$fin
echo "$s"
else
echo "First asset created"
first=$(./sandbox goal account info -a $escrow_account  |awk '{ print $2 }'|head -n $[ 2 ] | tail -n 1)
s=$(echo ${first%?})
echo "$s"
echo "Last asset created"
last=$(./sandbox goal account info -a $escrow_account  |awk '{ print $2 }'|head -n $[ $fin ] | tail -n 1) 
e=$(echo ${last%?})
fi

echo "$e"
echo "Manager account opt-in"

for ((i = $s ; i<=$e; i++))
do
./sandbox goal asset optin --assetid $i -a $account_name  > /dev/null 2>&1 &
echo -ne "$i/$e \033[0K\r"
sleep 0.4
done
echo "Opted in ASAs can be found in optedin.txt"
echo "Waiting for chain to get cought up!"
sleep 15
./sandbox goal account info -a $account_name > optedin.txt
echo "##########################################################################################"
echo "Transfer assets from Escrow to Manager"
for (( i=$s; i<=$e; i++))
do
./sandbox goal asset send -a 1 --assetid $i -f $escrow_account -t $account_name --clawback $account_name --creator $escrow_account > /dev/null 2>&1 & 
echo -ne "$i/$e \033[0K\r"
sleep 0.4
done 
echo "Waiting for chain to get cought up!"
sleep 15
echo "Transfered ASA found under transfered.txt"
./sandbox goal account info -a $account_name > transfered.txt
