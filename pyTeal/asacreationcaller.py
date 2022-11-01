from pyteal import * 
#######################################################################################
#         THIS PYTEAL HAS NOT YET BEEN SERUCITY AUDITTED. DO NOT USE IT               #
#         IN A PRODUCTION ENVIRONMENT.                                                #
#                                                                                     #
#         THIS PYTEAL IS PART OF A ASSETBULKCREATION SCRIPT FROM CARBONSTACK GmbH.    #
#         THIS SCRIPT WILL BE UPDATED ON A REGULAR BASIS.                             #
#                                                                                     #
# Current Version: 2.0                                                                #
# Last updated: 28.10.2022                                                            #
# Maintainer: tobias.thiel@carbonstack.de                                             #
#                                                                                     #
#######################################################################################

#This part of the program reads external input to the ASA-Caller contract. 
#First of it stores the app id of the ASA-Creation contract. Erasing the
#need to knowing the app id before hand. In addition, the variables x1 and x2 
#originating from a calculation script handed over from the bulkcreation script.
#These make it possible in combination with the ASA-Creation Contract and Script. 
#To efficiently create thousands of assets in a small timeframe.
#TODO: Make x1 and x2 be read form a single Document.


f = open('/path/to/sandbox/appid.txt', 'r')
app = int(f.readline())
f.close()
id = Int(app)
f = open('path/to/sandbox/x1.txt', 'r')
x1 = int(f.readline())
f.close()
f = open('path/to/sandbox/x2.txt', 'r')
x2 = int(f.readline())
f.close()


#todo do it for the Variables for the loops! 

def stateful():
   #defines a scratch variable required for looping in a contract 
    i = ScratchVar()
    #loops calls for assetcreation smart contract 
    on_call_asa_creator= Seq([ 
                For(i.store(Int(0)), i.load() < Int(x1), i.store(i.load() + Int(1)))  
                .Do( 
                InnerTxnBuilder.Begin(),
                InnerTxnBuilder.SetFields({
                TxnField.type_enum: TxnType.ApplicationCall,
                #calls the app id read to the program before the stateful
                TxnField.application_id: id,
                TxnField.on_completion: OnComplete.NoOp,
                TxnField.application_args: [Bytes("create_asa")]
                 }),
                    #Submit the transaction
                    InnerTxnBuilder.Submit(), 
                ),

                    Int(1),
    ]
            )
    #loop call for assetcreation used for the remainder after the main creation took place
    on_call_asa_rerun= Seq([ 
                For(i.store(Int(0)), i.load() < Int(x2), i.store(i.load() + Int(1)))  
                .Do( 
                InnerTxnBuilder.Begin(),
                InnerTxnBuilder.SetFields({
                TxnField.type_enum: TxnType.ApplicationCall,
                 #calls the app id read to the program before the stateful
                TxnField.application_id: id,
                TxnField.on_completion: OnComplete.NoOp,
                TxnField.application_args: [Bytes("rerun_asa")]
                 }),
                    #Submit the transaction
                    InnerTxnBuilder.Submit(), 
                ),
                    Int(1),
    ]
            )
    #singular call for just calling one asa creation‚
    on_call_asa_final= Seq([ 
                InnerTxnBuilder.Begin(),
                InnerTxnBuilder.SetFields({
                TxnField.type_enum: TxnType.ApplicationCall,
                TxnField.application_id: id,
                TxnField.on_completion: OnComplete.NoOp,
                TxnField.application_args: [Bytes("final_asa")]
                 }),
                    #Submit the transaction
                    InnerTxnBuilder.Submit(), 
                
                    Int(1),
    ]
            )
        
    

    program = Cond(
        [Txn.application_id() == Int(0), Int(1)],
        [Txn.application_args[0] == Bytes("create_asa"), on_call_asa_creator],
        [Txn.application_args[0] == Bytes("rerun_asa"), on_call_asa_rerun],
        [Txn.application_args[0] == Bytes("final_asa"), on_call_asa_final]

    )

    return And(Txn.group_index() == Int(0), program)


if __name__ == "__main__":
    print(compileTeal(stateful(), Mode.Application, version=7))
