from pyteal import * 

# This pyTEAL is only meant for educational purposes, do not use this pyteal on a production level!           #
# The displayed contract creates 16 asset with one call. The parameters need to be changed based              #    
# on the needs of the user. The smart contract is building a block of 16 inner transaction once called.       # 
# The default amount per ASA is set to 1. All mutable addresses are set to the creator of the smart contract  # 
# If you intent to call the Smart Contract from a different address to create the same ASA the addresses need #
# to be adjusted e. g. Txn.Sender()                                                                           #
# To trigger the ASA creation the app call must include the argument "create_asa".                            #
# For the parameters the regular ASA constraints found under:                                                 #
# https://developer.algorand.org/docs/get-details/parameter_tables/                                           #
# apply.                                                                                                      #    
# Maintainer:                                                                                                 #
# Tobias Thiel |CarbonStack GmbH                                                                              #
# tobias.thiel@carbonstack.de                                                                                 #


    
def stateful():
     #parameters needed for ASA creation that 
    unit = Bytes("UNIT")
    name = Bytes("NAME")
    url = Bytes("LINKTOWEBSITE")
    hash = Bytes("HASHOFMETADATA")
    note = Bytes("TTPD0000")
    #scratch variable needed for the loop
    #in a later version this will be made available with an open/read/save/close addition for the variables
    i = ScratchVar()
    on_create_asa= Seq([ 
    #loop creates 16 Asset creation transactions change i.load() < Int(16) 
    # to a number below 16 in order to adjust the amount of assets per call
    #anything higher should result in a opcode limitation
            For(i.store(Int(0)), i.load() < Int(16), i.store(i.load() + Int(1)))  
            .Do( 
            InnerTxnBuilder.Begin(),                 
            InnerTxnBuilder.SetFields({
    #identifies the type of transaction as an Assetconfigureration 
                    TxnField.type_enum: TxnType.AssetConfig,
    #change in order to create more of the Asset itself
                    TxnField.config_asset_total: Int(1),
    #change in order to allow a divison of the asset in smaller pieces                
                    TxnField.config_asset_decimals: Int(0),
    #parameters come from the ones above the loop
                    TxnField.config_asset_unit_name: unit,
                    TxnField.config_asset_name: name,
                    TxnField.config_asset_url: url,
                    TxnField.note: note,
                    TxnField.config_asset_metadata_hash: hash,
    #set to 1 if the asset is supposed to be default frozen on creation
                    TxnField.config_asset_default_frozen: Int(0),
    #change the values to Txn.sender() if you want to have a different account calling the contract as the 
    #the addresses. Change to Global.application_address() if the escrow should remain as the mainter.
                    TxnField.config_asset_manager: Global.creator_address(),
                    TxnField.config_asset_reserve: Global.creator_address(),
                    TxnField.config_asset_freeze: Global.creator_address(),
                    TxnField.config_asset_clawback: Global.creator_address()
                    }),
            
        
                    #Submit the transaction
                    InnerTxnBuilder.Submit(), 
                    ),
                    Int(1),
                    
                    
    ]
            )
        
        
    

    program = Cond(
        [Txn.application_id() == Int(0), Int(1)],
    #Change the call condition to create the assets if you want it to be triggered with another argument
        [Txn.application_args[0] == Bytes("create_asa"), on_create_asa]
    )

    return And(Txn.group_index() == Int(0), program)


if __name__ == "__main__":
    #requires pyTeal/Teal Version 7 might need to start sandbox with the future_template.json
    print(compileTeal(stateful(), Mode.Application, version=7))