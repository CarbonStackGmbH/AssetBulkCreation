
from pyteal import * 

# This pyTEAL is only meant for educational purposes, do not use this pyteal on a production level!           #
# The displayed contract calls another contract that creates 16 asset with one call.                          #
# The contract calls the creation contract of the ASA 15 times. THis means if left unconfigured it will create#
# a total of 240 ASA per call. If another amount is needed please feel free to change the loops in this caller#
# or inside the ASA creation contract. There is a work around as in the script associated to there contracts  #
# there is a distinct order in which the contracts are created. The script saves the application id to a txt  #
# file called appid.txt that in the beginning is opened, read and put into the variable id thus making it     #
# possible to automatically compile this contract as well without knowing the app id when setting everything  #
# up. Please change the path to the associated path needed (probably where the script is executed).           #
# To trigger the ASA creation the app call must include the argument "create_asa".                            #
# For the parameters the regular ASA constraints found under:                                                 #
# https://developer.algorand.org/docs/get-details/parameter_tables/                                           #
# apply.                                                                                                      #    
# Maintainer:                                                                                                 #
# Tobias Thiel |CarbonStack GmbH                                                                              #
# tobias.thiel@carbonstack.de                                                                                 #








#required for not hard defining the app id of the ASA-Creation Loop reads the appID from the saved output from the script
f = open('PATH/TO/FILE/appid.txt', 'r')
app = int(f.readline())
f.close()
id = Int(app)
def stateful():
#defines a scratch variable required for looping in a contract
    i = ScratchVar()
    on_call_asa_creator= Seq([ 
#loops calls for assetcreation smart contract change this to adjust the contract calls, anything higher than 15 needs an alteration of the creation contract
#else the call will fail due to an op-code limitations
                For(i.store(Int(0)), i.load() < Int(15), i.store(i.load() + Int(1)))  
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
#calls the creator contract a single time creating on default option another 16 ASAs  
    on_call_asa_rerun= Seq([ 
                InnerTxnBuilder.Begin(),
                InnerTxnBuilder.SetFields({
                TxnField.type_enum: TxnType.ApplicationCall,
                TxnField.application_id: id,
                TxnField.on_completion: OnComplete.NoOp,
                TxnField.application_args: [Bytes("create_asa")]
                 }),
                    #Submit the transaction
                    InnerTxnBuilder.Submit(), 

                    Int(1),
    ]
            )
        
        
    
#Conditions for the modes for the asa creation
    program = Cond(
        [Txn.application_id() == Int(0), Int(1)],
        [Txn.application_args[0] == Bytes("create_asa"), on_call_asa_creator]
        [Txn.application_args[0] == Bytes("rerun_asa"), on_call_asa_rerun]

    )

    return And(Txn.group_index() == Int(0), program)


if __name__ == "__main__":
#requires pyTeal/Teal Version 7 might need to start sandbox with the future_template.json
    print(compileTeal(stateful(), Mode.Application, version=7))