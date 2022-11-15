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


#This part reads the required variables for the asset creation.
#y1 and y2 are always set based on the optimal time for the bundeled
#creation. For simplicity reason they are read to the Program at from two 
#different text files. TODO: make it read line by line

f = open('/path/to/sandbox/y1.txt', 'r')
y1 = int(f.readline())
f.close()
f = open('/path/to/sandbox/y2.txt', 'r')
y2 = int(f.readline())
f.close()


#This part reads the variables defined in the ARC-Standard. Each read from 
#text files that lines are directly taken from the ARC. For simplicity 
#each is read individual. TODO: make it read line by line.

f = open('/path/to/sandbox/unit.txt', 'r')
unit_from_file= f.readline()
f.close()
f = open('/path/to/sandbox/name.txt', 'r')
name_from_file=f.readline()
f.close()
f = open('/path/to/sandbox/pid.txt', 'r')
pid_from_file= f.readline()
f.close()
f = open('/path/to/sandbox/hash.txt', 'r')
hash_from_file=f.readline()
f.close()
f = open('/path/to/sandbox/url.txt', 'r')
url_from_file= f.readline()
f.close()

#As some type errors occured the read variables are transformed in the required
#type for the pyTeal program. The has has to be read as a string before being 
#transformed to bytes. TODO: fix hash reading!

unit = Bytes(unit_from_file)
name = Bytes(name_from_file)
url = Bytes(url_from_file)
hash = Bytes("{}".format(hash_from_file))
pid = Bytes(pid_from_file)

def stateful():
        #parameters needed for ASA creation that 
    #scratch variable for loop
    i = ScratchVar()
    on_create_asa= Seq([ 
                        #loop to chain 16 ASA creations together for the initial bulk of assets
            For(i.store(Int(0)), i.load() < Int(y1), i.store(i.load() + Int(1)))  
            .Do( 
            InnerTxnBuilder.Begin(),                 
            InnerTxnBuilder.SetFields({
                    TxnField.type_enum: TxnType.AssetConfig,
                    TxnField.config_asset_total: Int(1),
                    TxnField.config_asset_decimals: Int(0),
                    TxnField.config_asset_unit_name: unit,
                    TxnField.config_asset_name: name,
                    TxnField.config_asset_url: url,
                    TxnField.note: pid,
                    TxnField.config_asset_metadata_hash: hash,
                    #Asset is unforzen on default as it needs to be transfered from the escrow to the creator 
                    TxnField.config_asset_default_frozen: Int(0),
                    #the administrational addresses are set to the app creator
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
    on_rerun_asa= Seq([ 
                       #loop to have the remainder asset chained 
            For(i.store(Int(0)), i.load() < Int(y2), i.store(i.load() + Int(1)))  
            .Do( 
            InnerTxnBuilder.Begin(),                 
            InnerTxnBuilder.SetFields({
                    TxnField.type_enum: TxnType.AssetConfig,
                    TxnField.config_asset_total: Int(1),
                    TxnField.config_asset_decimals: Int(0),
                    TxnField.config_asset_unit_name: unit,
                    TxnField.config_asset_name: name,
                    TxnField.config_asset_url: url,
                    TxnField.note: pid,
                    TxnField.config_asset_metadata_hash: hash,
                    #Asset is unforzen on default as it needs to be transfered from the escrow to the creator 
                    TxnField.config_asset_default_frozen: Int(0),
                    #the administrational addresses are set to the app creator
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
    #single asset creation 
    on_final_asa= Seq([ 
            InnerTxnBuilder.Begin(),                 
            InnerTxnBuilder.SetFields({
                    TxnField.type_enum: TxnType.AssetConfig,
                    TxnField.config_asset_total: Int(1),
                    TxnField.config_asset_decimals: Int(0),
                    TxnField.config_asset_unit_name: unit,
                    TxnField.config_asset_name: name,
                    TxnField.config_asset_url: url,
                    TxnField.note: pid,
                    TxnField.config_asset_metadata_hash: hash,
                    TxnField.config_asset_default_frozen: Int(0),
                    TxnField.config_asset_manager: Global.creator_address(),
                    TxnField.config_asset_reserve: Global.creator_address(),
                    TxnField.config_asset_freeze: Global.creator_address(),
                    TxnField.config_asset_clawback: Global.creator_address()
                    }),
            
                    #Submit the transaction
                    InnerTxnBuilder.Submit(), 
                    Int(1),
                    
                    
    ]
            )
    
        
        
    
#Conditions based on the caller string passed
    program = Cond(
        [Txn.application_id() == Int(0), Int(1)],
        [Txn.on_completion() == OnComplete.DeleteApplication, Int(1)],
        [Txn.on_completion() == OnComplete.UpdateApplication, Int(1)],
        [Txn.on_completion() == OnComplete.CloseOut, Int(0)],
        [Txn.on_completion() == OnComplete.OptIn, Int(0)],
        [Txn.application_args[0] == Bytes("create_asa"), on_create_asa],
        [Txn.application_args[0] == Bytes("rerun_asa"), on_rerun_asa],
        [Txn.application_args[0] == Bytes("final_asa"), on_final_asa]
    )

    return And(Txn.group_index() == Int(0), program)


if __name__ == "__main__":
    print(compileTeal(stateful(), Mode.Application, version=7))
