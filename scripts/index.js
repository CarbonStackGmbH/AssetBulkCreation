/************************************************************************************* 
 *                                                                                   *
 *  Application for calculating the cycles needed for the asset creation of ARC-CS.  *
 *  The result of the Application is the provision of both the amount of Cycles and  *
 *  Amount of Transactions per Cycle. Divide by 240 as long as possible.             *
 *                                                                                   *
 ************************************************************************************/
 const prompt = require('prompt-sync')({sigint: true});
 /*const hashed = prompt('Enter the hash: ');*/
 const num = prompt('Enter the asset amount: ');
 const fs = require('fs')
/**
 * The function takes an integer as an argument and returns an array of two integers. The first integer
 * is the number of assets that are transferred in one transaction. The second integer is the number of
 * smart contract calls that are made in one transaction
 * @param _assets - The total number of assets you want to transfer.
 * @returns an array with two values. The first value is the number of assets that are being used in
 * one transaction. The second value is the number of smart contract calls that are being used in one
 * transaction.
 */

function transactionCycles(_assets) {

    // Defining the two return arrays for the modulo = 0 and != 0 Solutions
    const arrayOfCleanDivisions = [];
    const arrayOfUncleanDivisions = [];
    const optimisedAssetCreationParameters = {
        K1: 0,
        Y1: 16,
        X1: 15,
        K2: 0,
        Y2: 16,
        X2: 15,
        K3: 0
    }

    // important, first to optimize the number of SmartContract Calls then the amount of assets
    for (optimisedAssetCreationParameters.Y1 = 16; optimisedAssetCreationParameters.Y1 >= 1; optimisedAssetCreationParameters.Y1--) {

        // running through the amount of assets
        for (optimisedAssetCreationParameters.X1 = 15; optimisedAssetCreationParameters.X1 >= 1; optimisedAssetCreationParameters.X1--) {

            /* check whether or not the product of optimisedAssetCreationParameters.Y1 and optimisedAssetCreationParameters.X1 can be divided without rest. 
            if that is the case return the number of assets and smart contract calls */
            let divider = optimisedAssetCreationParameters.Y1 * optimisedAssetCreationParameters.X1;
            let rest = _assets % divider;
            // create a deep copy of the current object in order to push the unique version into array without updating the objects parameters in later cycles
            let tmpObject = {}

            /* Pushing the number of cycles into the arrayOfCleanDivisions array. */
            if (_assets % divider == 0) {
                optimisedAssetCreationParameters.K1 = _assets / divider;
                tmpObject = JSON.parse(JSON.stringify(optimisedAssetCreationParameters));
                arrayOfCleanDivisions.push(tmpObject);
            }

            /* The above code is checking if the remainder of the division is not equal to 0 and if the
            remainder is less than or equal to 239. If both of these conditions are true, then the
            code will push the remainder into the arrayOfUncleanDivisions array. */
            else if (rest != 0 && _assets % rest <= 239) {
                const optimalRest = findTheMinimiumRest(rest);
                optimisedAssetCreationParameters.K2 = optimalRest.K2;
                optimisedAssetCreationParameters.K3 = optimalRest.K3;
                optimisedAssetCreationParameters.K1 = (((_assets - rest) / divider + optimalRest.K2));
                optimisedAssetCreationParameters.Y2 = optimalRest.Y2;
                optimisedAssetCreationParameters.X2 = optimalRest.X2;
                tmpObject = JSON.parse(JSON.stringify(optimisedAssetCreationParameters));
                arrayOfUncleanDivisions.push(tmpObject);
            }
        }
    }

    /* Finding the minimum value in the array. */
    const mergedArray = [...arrayOfCleanDivisions, ...arrayOfUncleanDivisions];
    const calculatedTransactionCycles = mergedArray.map((parameters) => Number(parameters.K1))
    const minTransactionsCycles = Math.min(...calculatedTransactionCycles);
    const searchObject = mergedArray.find((parameters) => parameters.K1 == minTransactionsCycles);
    searchObject.K2 = searchObject.K2 - searchObject.K3;
    searchObject.K1 = searchObject.K1 - searchObject.K2 - searchObject.K3;

    return searchObject;
};


/**
 * The function is checking whether or not the product of the number of assets and the number of smart
 * contract calls can be divided without rest. If that is the case, the function will return the number
 * of assets and smart contract calls. If the remainder of the division is not equal to 0 and if the
 * remainder is less than or equal to 239, then the function will return the number of assets and smart
 * contract calls
 * @param _rest - The amount of assets that need to be transferred.
 * @returns an object with the following parameters:
 * - K2: The number of cycles needed to complete the transaction
 * - Y2: The number of smart contract calls
 * - X2: The number of assets
 */
function findTheMinimiumRest(_rest) {
    const arrayOfModuloRest = [];
    const arrayOfNonModuloRest = [];
    const restObject = {
        K2: 0,
        Y1: 0,
        X2: 0,
        K3: 0
    }

    // important, first to optimize the number of SmartContract Calls then the amount of assets
    for (restObject.Y2 = 16; restObject.Y2 >= 1; restObject.Y2--) {

        // running through the amount of assets
        for (restObject.X2 = 15; restObject.X2 >= 1; restObject.X2--) {

            /* check whether or not the product of restObject.Y2 and restObject.X2 can be divided without rest. 
            if that is the case return the number of assets and smart contract calls */
            let divider = restObject.Y2 * restObject.X2;
            let rest = _rest % divider;
            // create a deep copy of the current object in order to push the unique version into array without updating the objects parameters in later cycles
            let tmpObject = {}

            /* Pushing the number of cycles into the arrayOfModuloRest array. */
            if (_rest % divider == 0) {
                restObject.K2 = _rest / divider;
                restObject.K3 = 0;
                tmpObject = JSON.parse(JSON.stringify(restObject));
                arrayOfModuloRest.push(tmpObject);
            }

            /* The above code is checking if the remainder of the division is not equal to 0 and if the
            remainder is less than or equal to 239. If both of these conditions are true, then the
            code will push the remainder into the arrayOfNonModuloRest array. */
            else if (rest != 0) {
                restObject.K3 = rest;
                restObject.K2 = (((_rest - rest) / divider + rest));
                tmpObject = JSON.parse(JSON.stringify(restObject));
                arrayOfNonModuloRest.push(tmpObject);
            }
        }
    }

    /* Finding the minimum value in the array. */
    const mergedRest = [...arrayOfModuloRest, ...arrayOfNonModuloRest];
    const calculatedK2 = mergedRest.map((parameters) => Number(parameters.K2));
    const minTransactionsCycles = Math.min(...calculatedK2);
    const smallestRest = mergedRest.find((parameters) => parameters.K2 == minTransactionsCycles);

    return smallestRest;
}


console.log(transactionCycles(num));

const split = JSON.stringify(transactionCycles(num), null, 2)
fs.writeFileSync('new.json', split)
