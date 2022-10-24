#!/bin/bash
echo"
#--------------------------------------------------------------------------------
#                                                                                  
#  Application for creating asset in bulk in the fastest way possible   
#  with the combination of goal scripts and atomic transfers and inner TXN.
#  Assets are created by an application account (Escrow) and then opted in by the 
#  Creator. The assets are then transfered to the Creator of the app.      
# 
#  This script needs alteration in order to function on lines assuming 
#  no further changes
#  40, 47, 54, 70, 73
#
#
#  THE VALUES IN THE SMARTCONTRACT NEED TO BE CHANGED OR THE AMOUNT OF ASSETS 
#  CREATED WILL BE DEFAULTED TO A PRODUCT OF 240. 
#  
#  DISCLAIMER, THIS SCRIPT IS FOR EDUCATIONAL PURPOSES ONLY AND MADE 
#  FOR A PRIVATE NETWORK OR SANDBOX INSTANCE. THIS SCRIPT HAS NOT YET BEEN AUDITED
#  IT IS NOT AVICED TO USE IT IN A PRODUCTION ENVIRONMENT!
#  
#  MAINTAINER: tobias.thiel@carbonstack.de                                                                             
#_________________________________________________________________________________"


#reading input from the User or App 
#calculation of the needed Algos needed in the app for creation and holding them.
#based on the needed assets the required iterations are calculated based on 240 ASAs per call.
#lastly variables for Opt-In and transactions are calculated and set.
echo "Enter the amount of Assets you want to create"
        read amount_assets
        amount_algo=$(($amount_assets*200000))
        k=$(($amount_assets/240))
        fin=$(($amount_assets+1))
echo "total amount of assets: $fin"
echo "Holding capital: $amount_algo"
echo "amount of iterations needed: $k"



#This part moves to the folder where the pyteal of the ASA-Creation 
#is present and the teal file is compiled to.
#Make sure to rename the teal file to something related to your goal. 
#The clear.teal should also be compiled here, for simplicity a basic clear.teal is present.
cd /PATH/TO/MOUNTED/FOLDER
rm approval.teal
python3 asacontractloop.py > approval.teal
cd /PATH/TO/THESCRIPT/SANDBOX
echo "##########################################################################################"

#Now the accounts are set and displayed. The following script assumes that in the account list the top account
#is supposed to be the default account (should be the default account may need alterations for that in future).
account_name=$(./sandbox goal account list|awk '{ print $2 }'|head -1)
echo "Admin account of the app $account_name"
echo "##########################################################################################"

#These lines create the smart contract and set the variable to the deployed APPid. 
#The Appid is then saved in an external file that is later read by the caller pyteal.
#In addition the escrow account is also saved to a variable for later calls, including the intial funding of it.
asa_app_id=$(./sandbox goal app create --creator $account_name --approval-prog /PATH/MOUNTED/FOLDER/APPROVALTEAL --clear-prog /PATH/MOUNTED/FOLDER/CLEARTEAL --global-byteslices 1 --global-ints 1 --local-byteslices 0 --local-ints 0 |awk '{ print $6 }'|tail -1)
echo "the app id is $asa_app_id"
echo $asa_app_id > appid.txt
escrow_account=$(./sandbox goal app info --app-id $asa_app_id |awk '{ print $3 }'|head -n $[ 2 ] | tail -n 1)
echo "the creator account will be $escrow_account"
echo "Funding the app account"
./sandbox goal clerk send -f $account_name -t $escrow_account -a $amount_algo > /dev/null &



#Per default this script is creating 240 assets in order to do that it is required to have a caller contract call the creation contract 15 times.
#For that to happen the caller contract needs to be compiled as well. The Appid was saved beforehand.
cd /PATH/TO/MOUNTED/FOLDER
python3 asacreationcaller.py > approval2.teal
cd /PATH/TO/THESCRIPT/SANDBOX
echo "##########################################################################################"

#Coming to the execution of the ASA creation. The caller app is created its ID is then saved for the later call-
#The loop is then formed based on the iteration neede calculated beforehand. 
#explanation of the Asa creation call: 
#The creation call is triggered by the app caller smart contract which is triggered directly in the loop. The maximum fee is sent in order to reserve the required opcode. 
#The and '&' symbol is required in order to allow your processor to perform the call as a multithread application.
#The sleeptimer in the loop is required in order to ensure that all the transaction are actually packed inside a block this is highly dependend on blocktime/processorspeed/corecount
caller_app_id=$(./sandbox goal app create --creator $account_name --approval-prog /PATH/MOUNTED/FOLDER/APPROVAL2TEAL --clear-prog /PATH/MOUNTED/FOLDER/CLEARTEAL --global-byteslices 1 --global-ints 1 --local-byteslices 0 --local-ints 0 |awk '{ print $6 }'|tail -1)
echo "the contract caller id $caller_app_id"
for ((i = 1 ; i<=$k; i++))
do
./sandbox  goal app call --app-id $caller_app_id --app-arg "str:create_asa"  -f $account_name --foreign-app $asa_app_id --fee 320000 > /dev/null  & 
sleep 0.5
o=$(($i*240))
echo -ne "$o/$amount_assets \033[0K\r"
echo "$o"
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
buffer=$(($k*16))
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
./sandbox goal asset optin --assetid $i -a $account_name > /dev/null 2>&1 & 
echo -ne "$i/$e \033[0K\r"
sleep 0.4
done
echo "##########################################################################################"
echo "Waiting for chain to get cought up!"
sleep 15
echo "Opted in ASAs can be found in optedin.txt"
./sandbox goal account info -a $account_name > optedin.txt
echo "Transfer assets from Escrow to Manager"
for (( i=$s; i<=$e; i++))
do
./sandbox goal asset send -a 1 --assetid $i -f $escrow_account -t $account_name --clawback $account_name --creator $escrow_account > /dev/null 2>&1 & 
echo -ne "$i/$e \033[0K\r"
sleep 0.4
done 
sleep 5
echo "Waiting for chain to get cought up!"
sleep 15
echo "Transfered ASA found unter transfered.txt"
./sandbox goal account info -a $account_name > transfered.txt
echo "Finished"

