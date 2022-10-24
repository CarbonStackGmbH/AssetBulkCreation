# AssetBulkCreation
****Source Code for creating a bulk of single (unique) and referenceable ASAs****

This git repository assumes that you are familiar with basic Algorand terminology and the concepts of Algorand Standard Assets, Smart Contracts, Atomic Transactions, and Inner-Transactions. 

If not, please visit the corresponding resources supplied by Algorand. 

### Knowledgebase: 
https://developer.algorand.org/docs/
### Tutorials: 
https://developer.algorand.org/tutorials/
### Official Algorand Git
https://github.com/algorand/


The supplied code examples are stripped-down versions representing the idea behind the Usecase of CarbonStack. These are under **NO CIRCUMSTANCE** useable in a productive environment, as they are not security audited and are exploitable. 

Due to the nature of the presented concept, it is advised to test it out in a Sandbox environment or private instance. The script's performance is also highly based on the system's archetype, taking utilization of paralyzation. 


## Adjustment in Sandbox

Before you start make sure to have a running sandbox environment configured for a private network. 

The repository for Sandbox can be found here: 

https://github.com/algorand/sandbox

As the smart contract are designed with the latest pyTeal version (as of writing pyTeal v7) the Sandboxnetwork needs to be started with an adjustment in the docker-compose.yml. If the standard setup allows the usage of pyTeal 7 this change can be ignored.
Under ***TEMPLATE*** change ****template.json**** to ****future_template.json****

```yaml
args:
        CHANNEL: "${ALGOD_CHANNEL}"
        URL: "${ALGOD_URL}"
        BRANCH: "${ALGOD_BRANCH}"
        SHA: "${ALGOD_SHA}"
        BOOTSTRAP_URL: "${NETWORK_BOOTSTRAP_URL}"
        GENESIS_FILE: "${NETWORK_GENESIS_FILE}"
        TEMPLATE: "${NETWORK_TEMPLATE:-images/algod/future_template.json}"
        NETWORK_NUM_ROUNDS: "${NETWORK_NUM_ROUNDS:-30000}"
```        

In order to have the contracts easily deployed it is also recommended to mount the folder you are currently working in to the docker container used by sandbox. In order to do that change in the docker-compose.yml the following lines under volumes: 

```yaml
 volumes:
      - type: bind 
        source: /path/to/sandbox/mounted/folders
        target: /data
```
With these changes to the docker-compose file the sandbox environment just needs to be started via: 
```
./sandbox up
```
If the sandbox environment failes to start make sure docker desktop is running and use the command: 
```
./sandbox clean
```
and also remove the images saved by docker.

# Running the script

1. Download the repository
2. Put the files into the folders associated for sandbox or your private instance.
        a. The pyTeal files should be situated where the teal files are as well.
        b. The Teal file should be there as well.
        c. The script should be were the sandbox scripts are. 
3. Change the parameters in the pyTeal to your liking within the boundaries
4. Change the variables inside the script. These include variables set for ***the respective paths***
   these are also present in the ***app creations***. ****More information on that in the script itself.**** 
5. Once finished navigate to the folder were the script is present. 
6. Execute the script via 
```shell
bash assetbulkcreationscript.sh
```
        
