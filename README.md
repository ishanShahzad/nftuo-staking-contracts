# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.js
```
# Smart Contracts Overview:

## 1. Token Swap Smart Contract

A smart contract to swap between ERC20 tokens and USDC. The contract can be paused and resumed by the contract owner, and supports updating the token price, the minimum swap amount, and the USDC token address. The swap function takes a token name and an amount, then it sells the token for USDC or buys the token with USDC depending on the given token name.

### Requirements
The following packages are required to use the contract:
- OpenZeppelin 4.4.1
- Chainlink 0.8.0
### Usage
To use the contract, an instance of the TokenSwap contract needs to be deployed on the Ethereum network. During deployment, the following parameters should be provided:

- `_tokenAddress`: the address of the ERC20 token to swap.
- `_tokenPriceInUsd`: the current price of the token in USD.
- `_minSwapAmount`: the minimum swap amount that is allowed.
- `_usdcToken`: the address of the USDC token.

### After deployment, the contract owner can perform the following operations:

#### Pause and Unpause: 
The contract owner can pause and resume the contract by calling the `pause()` and `unpause()` functions, respectively.

#### Update Token Address
The contract owner can update the token address by calling the `updateToken()` function and passing the new token address.

#### Update Token Price
The contract owner can update the token price by calling the `updateTokenPrice()` function and passing the new token price in USD.

#### Update Minimum Swap Amount
The contract owner can update the minimum swap amount by calling the `updateMinimumSwapAmount()` function and passing the new minimum swap amount.

#### Update USDC Token Address
The contract owner can update the USDC token address by calling the `updateUsdcToken()` function and passing the new USDC token address.

#### Withdraw Tokens
The contract owner can withdraw tokens from the contract by calling the `withdrawTokens()` function and passing the amount of tokens to withdraw.

#### Swap Tokens
The `swap()` function is the main function of the contract. It takes two parameters: the name of the token to swap (**NUO** or **USDC**) and the amount of tokens to swap. If the token name is **NUO**, the function sells the tokens for **USDC**. If the token name is USDC, the function buys the tokens with **USDC**.

### Events
The contract emits the following events:

`Sold(address indexed seller, uint256 amount)`: emitted when a seller sells tokens.
`Purchased(address indexed buyer, uint256 amount)`: emitted when a buyer purchases tokens.

### License
The contract is licensed under the [MIT License](https://opensource.org/license/mit-0/).

### Gas Report (USD)
```shell
·---------------------------------------------|---------------------------|-------------|-----------------------------·
|             Solc version: 0.8.9             ·  Optimizer enabled: true  ·  Runs: 200  ·  Block limit: 30000000 gas  │
··············································|···························|·············|······························
|  Methods                                    ·               23 gwei/gas               ·       1551.71 usd/eth       │
··················|···························|·············|·············|·············|···············|··············
|  Contract       ·  Method                   ·  Min        ·  Max        ·  Avg        ·  # calls      ·  usd (avg)  │
··················|···························|·············|·············|·············|···············|··············
|  MockUsdcToken  ·  approve                  ·          -  ·          -  ·      46650  ·            4  ·       1.66  │
··················|···························|·············|·············|·············|···············|··············
|  MockUsdcToken  ·  transfer                 ·          -  ·          -  ·      51854  ·            5  ·       1.85  │
··················|···························|·············|·············|·············|···············|··············
|  NuoToken       ·  approve                  ·          -  ·          -  ·      46673  ·            4  ·       1.67  │
··················|···························|·············|·············|·············|···············|··············
|  NuoToken       ·  pause                    ·          -  ·          -  ·      27884  ·            1  ·       1.00  │
··················|···························|·············|·············|·············|···············|··············
|  NuoToken       ·  transfer                 ·          -  ·          -  ·      54038  ·            5  ·       1.93  │
··················|···························|·············|·············|·············|···············|··············
|  NuoToken       ·  unpause                  ·          -  ·          -  ·      27855  ·            1  ·       0.99  │
··················|···························|·············|·············|·············|···············|··············
|  TokenSwap      ·  swap                     ·     102930  ·     104540  ·     103735  ·            2  ·       3.70  │
··················|···························|·············|·············|·············|···············|··············
|  TokenSwap      ·  updateMinimumSwapAmount  ·      28798  ·      28822  ·      28810  ·            2  ·       1.03  │
··················|···························|·············|·············|·············|···············|··············
|  TokenSwap      ·  updateToken              ·          -  ·          -  ·      29211  ·            2  ·       1.04  │
··················|···························|·············|·············|·············|···············|··············
|  TokenSwap      ·  updateTokenPrice         ·      28829  ·      28865  ·      28847  ·            2  ·       1.03  │
··················|···························|·············|·············|·············|···············|··············
|  Deployments                                ·                                         ·  % of limit   ·             │
··············································|·············|·············|·············|···············|··············
|  MockUsdcToken                              ·          -  ·          -  ·     692885  ·        2.3 %  ·      24.73  │
··············································|·············|·············|·············|···············|··············
|  NuoToken                                   ·          -  ·          -  ·    1031394  ·        3.4 %  ·      36.81  │
··············································|·············|·············|·············|···············|··············
|  TokenSwap                                  ·          -  ·          -  ·    1602619  ·        5.3 %  ·      57.20  │
·---------------------------------------------|-------------|-------------|-------------|---------------|-------------·
```


*** 

## 2. Airdrop Contract
This contract is an implementation of an Airdrop campaign for a specific ERC20 token. The campaign is divided into tranches, where a portion of the tokens is released at specified time intervals.

### Prerequisites
The following OpenZeppelin contracts are imported and used in this contract:

- `Ownable`: Implements a modifier for restricting access to certain functions only to the contract owner.
- `Pausable`: Implements functions for pausing and resuming the contract's functionality.
- `IERC20`: Implements the ERC20 interface.
- `ReentrancyGuard`: Implements a modifier that prevents reentrancy attacks.
- `Additionally`: the contract also uses an external interface IStaking for staking functionality.

### Overview
This Airdrop contract is designed to distribute a specific ERC20 token to whitelisted addresses over a period of time. Each address can claim a percentage of their total vested amount in each tranche, and the contract also provides an option to stake the claimed tokens. The campaign is divided into tranches, and a certain percentage of tokens is released at each tranche.

### Contract Functions
#### Constructor
The constructor takes the following parameters:

- `_nuoToken`: The ERC20 token to be distributed in the airdrop.
- `_stakingContract`: The interface of the staking contract.
- `_startTime`: The timestamp when the airdrop campaign starts.
- `_trancheTimeInDays`: The duration of each tranche, in days.
- `_claimPercentage`: The percentage of the total vested amount that can be claimed at each tranche.
- `_numOfClaims`: The maximum number of claims allowed per address.
- `getTotalTokenReleased`: This function returns the total amount of tokens that have been released to all addresses.

### Functions
- `pause`: This function is used to pause the contract's functionality and can only be called by the owner.
- `unpause`: This function is used to resume the contract's functionality and can only be called by the owner.
- `getStakingContract`: This function returns the interface of the staking contract.
- `setStakingContract`: This function is used to set the address of the staking contract and can only be called by the owner.
- `whitelistAddresses`: This function is used to whitelist addresses and their corresponding vested amounts. The function takes two arrays as input: the array of addresses to be whitelisted and the array of corresponding vested amounts.
- `getWhitelistedAddresses`: This function returns an array of all whitelisted addresses.
- `isWhitelisted`: This function checks whether an address is whitelisted.
- `claim`: This function is used to claim the vested amount by an address. The address can claim a certain percentage of the total vested amount at each tranche. The function also emits a Claimed event.
- `stake`: This function is used to stake the claimed amount by an address. The function also emits a Staked event.

### Data Structures
- `VestInfo`: This is a struct that contains the following fields:
- `totalVestedAmount`: The total amount of tokens that are vested for a specific address.
- `lastClaimedAt`: The timestamp when the last tranche was claimed.
- `totalClaimed`: The total amount of tokens claimed by an address so far.
- `claimsCount`: The number of claims made by an address so far.
- `Vaults`: This is an enum that defines the vaults in the staking contract. The vaults are represented by their index in the enum.

### Events
- `Claimed`: This event is emitted when an address claims their vested amount. The event contains the following parameters:
- `Staked`: This event is emitted when an address stake their vested amount into the `Staking contract`

### License
The contract is licensed under the [MIT License](https://opensource.org/license/mit-0/).

### Gas Report (USD)
```shell
·-----------------------------------|---------------------------|-------------|-----------------------------·
|        Solc version: 0.8.9        ·  Optimizer enabled: true  ·  Runs: 200  ·  Block limit: 30000000 gas  │
····································|···························|·············|······························
|  Methods                          ·               21 gwei/gas               ·       1549.76 usd/eth       │
·············|······················|·············|·············|·············|···············|··············
|  Contract  ·  Method              ·  Min        ·  Max        ·  Avg        ·  # calls      ·  usd (avg)  │
·············|······················|·············|·············|·············|···············|··············
|  Airdrop   ·  claim               ·      67855  ·     136305  ·      74922  ·          104  ·       2.44  │
·············|······················|·············|·············|·············|···············|··············
|  Airdrop   ·  pause               ·          -  ·          -  ·      27828  ·            1  ·       0.91  │
·············|······················|·············|·············|·············|···············|··············
|  Airdrop   ·  unpause             ·          -  ·          -  ·      27822  ·            1  ·       0.91  │
·············|······················|·············|·············|·············|···············|··············
|  Airdrop   ·  whitelistAddresses  ·          -  ·          -  ·    1092155  ·            1  ·      35.54  │
·············|······················|·············|·············|·············|···············|··············
|  NuoToken  ·  transfer            ·          -  ·          -  ·      54062  ·            1  ·       1.76  │
·············|······················|·············|·············|·············|···············|··············
|  Deployments                      ·                                         ·  % of limit   ·             │
····································|·············|·············|·············|···············|··············
|  Airdrop                          ·          -  ·          -  ·    1497113  ·          5 %  ·      48.72  │
····································|·············|·············|·············|···············|··············
|  NuoToken                         ·          -  ·          -  ·    1031418  ·        3.4 %  ·      33.57  │
·-----------------------------------|-------------|-------------|-------------|---------------|-------------·
```

***

## 3. Staking Contract
The Staking Smart Contract allows users to stake tokens in the defined vaults, earn rewards on them, and also harvest those rewards. The contract also has some advanced functionalities like vault configurations and user's historical data. Below is the detailed documentation of this smart contract.

### Prerequisites
The following OpenZeppelin contracts are imported and used in this contract:

- `Ownable`: Implements a modifier for restricting access to certain functions only to the contract owner.
- `Pausable`: Implements functions for pausing and resuming the contract's functionality.
- `IERC20`: Implements the ERC20 interface.
- `ReentrancyGuard`: Implements a modifier that prevents reentrancy attacks.

### Modifiers
`onlyAirdropContract` This modifier is used to only allow the airdrop contract to call a function.
`checkSendersStakeLimit` This modifier is used to check if the sender has reached the maximum number of stakes in a vault

### Contract overview
### Vault
The abstract Vault contract defines the core functionality of the vaults in which users can stake their tokens. It defines the variables, struct types, and events that are being used in the staking contract.

### Variables
`NUMERATOR (uint256 constant)`: The constant value used for the APR (Annual Percentage Rate) calculation
`ONE_YEAR (uint256 constant)`: The constant value used to calculate the time for APR calculation, i.e., 1 year in seconds
`harvestingBonusPercentage (uint256)`: The percentage of bonus rewards to be given to users on harvest

### Struct types
`StakeInfo`: This struct type is used to define the stake information of each user, including their wallet address, stake ID, staked amount, last claimed time, total claimed rewards, staked at time, vault type, and an `unstaked` flag.
`VaultConfig`: This struct type is used to define the configuration of the vaults, including the APR, maximum cap, and cliff duration.

### Events
`Staked`: This event is emitted whenever a user stakes their tokens in the vaults.
`Harvest`: This event is emitted whenever a user harvests their rewards from the vaults.
`Unstaked`: This event is emitted whenever a user unstakes their tokens from the vaults.
`Claimed`: This event is emitted whenever a user claims their rewards from the vaults.
`HarvestAll` This event is emitted whenever a user harvests all their rewards from the vaults
`ClaimedAll` This event is emitted whenever a user claims their rewards from the vaults

### Functions
`_stakeInVault`: This internal function is used to add a new stake in the specified vault by updating the stakeIdsInVault, stakeInfoById, and totalStakedInVault mappings.
`_calculateRewards`: This internal function is used to calculate the rewards that a user can claim on a specific stake ID.

## Staking
The Staking contract extends the Vault contract and provides additional functionality to users to stake, unstake, harvest and claim rewards. It also provides pausing, resuming, and migration functionality to the contract owner.

### Variables
`Token (IERC20Upgradeable)`: The address of the ERC20 token contract.
`wallet (address)`: The address to which the staked tokens will be transferred.
`airdropContractAddress (address)`: The address of the airdrop contract.
`stakeId (CountersUpgradeable.Counter)`: A counter to keep track of the number of stakes created.
`VAULTS (VaultConfig[3])`: An array of vault configurations.
`harvestingBonusPercentage (uint256)`: The percentage of bonus rewards to be given to users on harvest.

### Functions
`initialise`: This function is used to initialise the staking contract with the ERC20 token contract address, the wallet address, the airdrop contract address, and the harvesting bonus percentage.
`pause`: This function is used to pause the staking contract by the contract owner.
`unpause`: This function is used to unpause the staking contract by the contract owner.
`getNuoToken` This function is used to get the address of the Nuo token contract.
`setNuoToken` This function is used to set the address of the Nuo token contract. Only callable by the owner of the contract
`getWalletAddress` This function is used to get the address of the wallet associated with the contract.
`getAirdropContractAddress` This function is used to return the address of the airdrop contract.
`setAirdropContractAddress` This functio is used to set the address of the airdrop contract.
`getVaults` This function is used to return all the available vaults as an enum.
`getVaultConfiguration` This function is used to return the configuration for the specified vault
`getHarvestingBonusPercentage` This function is used to return the percentage of harvesting bonus
`setHarvestingBonusPercentage` This function is used to sets the percentage of harvesting bonus
`setWalletAddress` This function is used to set the address of the wallet associated with the contract. Only callable by the owner of the contract.
`stake`: This function is used by users to stake tokens in the specified vault by transferring the tokens from their wallet to the staking contract.
`stakeByContract` This function is used to stake amount of token in a specific vault by sender through Airdrop contract.
`unstake` This function is used to allows the staker to unstake their tokens and claim their rewards.
`harvestRewardTokens` This function is used to harvest rewards earned from a specific stake and restake them in the specified vault with a bonus.
`harvestAllRewardTokens` This function is used to harvest all reward tokens from a particular vault and restake them in the specified vault with a bonus
`claimReward` This function is used to allows the staker to claim their rewards from a specific stake
`claimAllReward` This function is used to allows the staker to claim all their rewards from a psrticular vault.
`getStakingReward` This function is used to return the amount of rewards that a staker would receive if they were to claim rewards for a specific stake.
`getStakeInfo` This function is used to return an array of StakeInfo structs representing all stakes made by a specific wallet address in a specific vault
`getStakeInfoById` This function is used to return the StakeInfo struct for a specific stake ID
`totalStakes` This function is used to return the total number of stakes that have been made
`tokensStakedInVault` This function is used to returns the total amount of tokens staked in a specific vault

### License
The contract is licensed under the [MIT License](https://opensource.org/license/mit-0/).

### Gas Report (USD)
```shell
·-------------------------|---------------------------|-------------|-----------------------------·
|   Solc version: 0.8.9   ·  Optimizer enabled: true  ·  Runs: 200  ·  Block limit: 30000000 gas  │
··························|···························|·············|······························
|  Methods                ·               26 gwei/gas               ·       1680.04 usd/eth       │
·············|············|·············|·············|·············|···············|··············
|  Contract  ·  Method    ·  Min        ·  Max        ·  Avg        ·  # calls      ·  usd (avg)  │
·············|············|·············|·············|·············|···············|··············
|  NuoToken  ·  approve   ·      26809  ·      46709  ·      44133  ·           21  ·       1.93  │
·············|············|·············|·············|·············|···············|··············
|  NuoToken  ·  transfer  ·      54062  ·      54074  ·      54073  ·           18  ·       2.36  │
·············|············|·············|·············|·············|···············|··············
|  Staking   ·  pause     ·          -  ·          -  ·      27906  ·            2  ·       1.22  │
·············|············|·············|·············|·············|···············|··············
|  Staking   ·  stake     ·     232225  ·     283525  ·     251310  ·           17  ·      10.98  │
·············|············|·············|·············|·············|···············|··············
|  Staking   ·  unpause   ·          -  ·          -  ·      27900  ·            2  ·       1.22  │
·············|············|·············|·············|·············|···············|··············
|  Staking   ·  unstake   ·     114776  ·     136676  ·     124323  ·           17  ·       5.43  │
·············|············|·············|·············|·············|···············|··············
|  Deployments            ·                                         ·  % of limit   ·             │
··························|·············|·············|·············|···············|··············
|  NuoToken               ·          -  ·          -  ·    1031418  ·        3.4 %  ·      45.05  │
··························|·············|·············|·············|···············|··············
|  Staking                ·          -  ·          -  ·    2320488  ·        7.7 %  ·     101.36  │
·-------------------------|-------------|-------------|-------------|---------------|-------------·
```

***
