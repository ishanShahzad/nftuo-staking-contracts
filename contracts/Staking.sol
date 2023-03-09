/**
                                                                                                             
NNNNNNNN        NNNNNNNNFFFFFFFFFFFFFFFFFFFFFFTTTTTTTTTTTTTTTTTTTTTTTUUUUUUUU     UUUUUUUU     OOOOOOOOO     
N:::::::N       N::::::NF::::::::::::::::::::FT:::::::::::::::::::::TU::::::U     U::::::U   OO:::::::::OO   
N::::::::N      N::::::NF::::::::::::::::::::FT:::::::::::::::::::::TU::::::U     U::::::U OO:::::::::::::OO 
N:::::::::N     N::::::NFF::::::FFFFFFFFF::::FT:::::TT:::::::TT:::::TUU:::::U     U:::::UUO:::::::OOO:::::::O
N::::::::::N    N::::::N  F:::::F       FFFFFFTTTTTT  T:::::T  TTTTTT U:::::U     U:::::U O::::::O   O::::::O
N:::::::::::N   N::::::N  F:::::F                     T:::::T         U:::::D     D:::::U O:::::O     O:::::O
N:::::::N::::N  N::::::N  F::::::FFFFFFFFFF           T:::::T         U:::::D     D:::::U O:::::O     O:::::O
N::::::N N::::N N::::::N  F:::::::::::::::F           T:::::T         U:::::D     D:::::U O:::::O     O:::::O
N::::::N  N::::N:::::::N  F:::::::::::::::F           T:::::T         U:::::D     D:::::U O:::::O     O:::::O
N::::::N   N:::::::::::N  F::::::FFFFFFFFFF           T:::::T         U:::::D     D:::::U O:::::O     O:::::O
N::::::N    N::::::::::N  F:::::F                     T:::::T         U:::::D     D:::::U O:::::O     O:::::O
N::::::N     N:::::::::N  F:::::F                     T:::::T         U::::::U   U::::::U O::::::O   O::::::O
N::::::N      N::::::::NFF:::::::FF                 TT:::::::TT       U:::::::UUU:::::::U O:::::::OOO:::::::O
N::::::N       N:::::::NF::::::::FF                 T:::::::::T        UU:::::::::::::UU   OO:::::::::::::OO 
N::::::N        N::::::NF::::::::FF                 T:::::::::T          UU:::::::::UU       OO:::::::::OO   
NNNNNNNN         NNNNNNNFFFFFFFFFFF                 TTTTTTTTTTT            UUUUUUUUU           OOOOOOOOO     
                                                                                                             

*/

/**
 * @title Staking contract for a token
 * @author Muhammad Usman
 * @dev Contract to manage staking of Nuo tokens.
 * Contract that allows users to stake a token in any of the three available vaults (Vaults.vault_1, Vaults.vault_2, Vaults.vault_3). The contract is Ownable and Pausable, ensuring only the owner can perform certain operations while the contract can be paused to stop certain functionality.
 * Users can deposit tokens, stake in any of the three vaults and withdraw their funds along with any accrued rewards. The contract has an airdropContractAddress that can deposit tokens on behalf of its users. The contract also has a configurable harvesting bonus percentage that will be given to users on withdrawal of their stakes.
 * Allows users to stake Nuo tokens into a specific Vault for a set period of time.
 * Also allows users to withdraw their staked tokens before the end of the lockup period.
 * The contract is pausable by the owner in case of emergency or upgrade requirements.
 * The owner can also set the Nuo token address and the wallet address for the contract.
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./Vault.sol";

contract Staking is
    Initializable,
    Vault,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private stakeId;

    IERC20Upgradeable private Token;
    address private wallet;

    address private airdropContractAddress;

    /**
     * Initializer function that initializes the Staking contract.
     * @param _tokenAddress The address of the ERC20 token that will be staked.
     * @param _wallet The address of the wallet where the stake rewards will be transferred.
     * @param _airdropAddress The address of the airdrop contract that can deposit tokens on behalf of its users.
     * @param _harvestingBonusPercentage The percentage of reward bonus that will be given to users on withdrawal of their stakes.
     */

    function initialise(
        IERC20Upgradeable _tokenAddress,
        address _wallet,
        address _airdropAddress,
        uint256 _harvestingBonusPercentage
    ) public initializer {
        require(_wallet != address(0), "Stake: Invalid address");
        require(_airdropAddress != address(0), "Stake: Invalid address");

        Token = _tokenAddress;
        wallet = _wallet;
        airdropContractAddress = _airdropAddress;

        VAULTS[uint256(Vaults.vault_1)] = VaultConfig(
            60,
            1_000_000_000_000 ether,
            365 days
        );
        VAULTS[uint256(Vaults.vault_2)] = VaultConfig(
            90,
            500_000_000_000 ether,
            2 * 365 days
        );
        VAULTS[uint256(Vaults.vault_3)] = VaultConfig(
            120,
            500_000_000_000 ether,
            3 * 365 days
        );
        harvestingBonusPercentage = _harvestingBonusPercentage;

        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
    }

    /**
     * @dev Modifier to only allow the airdrop contract to call a function.
     * @notice This modifier checks if the sender is the airdrop contract.
     */

    modifier onlyAirdropContract() {
        require(msg.sender == airdropContractAddress, "Stake: Invalid sender");
        _;
    }

    /**
     * @dev Modifier to check if the sender has reached the maximum number of stakes in a vault.
     * @param _sender The address of the sender.
     * @param _vault The Vaults enum.
     * @notice This modifier checks if the sender has already staked 5 times in the given vault.
     */
    modifier checkSendersStakeLimit(address _sender, Vaults _vault) {
        require(
            stakesInVaultByAddress[_sender][_vault] < 5,
            "Stake: A wallet can Stake upto 5 times in a Vault"
        );
        _;
    }

    /**
     * @dev Pauses the contract. Only callable by the owner of the contract.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     *@dev Unpauses the contract. Only callable by the owner of the contract.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     *@dev Gets the address of the Nuo token contract.
     *@return Address of the Nuo token contract.
     */
    function getNuoToken() public view returns (address) {
        return address(Token);
    }

    /**
     *@dev Sets the address of the Nuo token contract. Only callable by the owner of the contract.
     *@param _tokenAddr Address of the Nuo token contract.
     */
    function setNuoToken(IERC20Upgradeable _tokenAddr) public onlyOwner {
        require(address(_tokenAddr) != address(0), "Stake: Invalid address");
        Token = _tokenAddr;
    }

    /**
     *@dev Gets the address of the wallet associated with the contract.
     *@return Address of the wallet associated with the contract.
     */
    function getWalletAddress() public view returns (address) {
        return wallet;
    }

    /**
     *@dev Sets the address of the wallet associated with the contract. Only callable by the owner of the contract.
     *@param _wallet Address of the wallet associated with the contract.
     */
    function setWalletAddress(address _wallet) public onlyOwner {
        require(_wallet != address(0), "Stake: Invalid address");
        wallet = _wallet;
    }

    /**
     *@dev Returns the address of the airdrop contract.
     *@return The address of the airdrop contract.
     */
    function getAirdropContractAddress() public view returns (address) {
        return airdropContractAddress;
    }

    /**
     *@dev Sets the address of the airdrop contract.
     *@param _airdropContractAddress The new address of the airdrop contract.
     */
    function setAirdropContractAddress(address _airdropContractAddress)
        public
        onlyOwner
    {
        require(
            address(_airdropContractAddress) != address(0),
            "Stake: Invalid address"
        );

        airdropContractAddress = _airdropContractAddress;
    }

    /**
     *@dev Returns all the available vaults as an enum.
     *@return The vaults enum.
     */
    function getVaults()
        public
        pure
        returns (
            Vaults,
            Vaults,
            Vaults
        )
    {
        return (Vaults.vault_1, Vaults.vault_2, Vaults.vault_3);
    }

    /**
     *@dev Returns the configuration for the specified vault.
     *@param _vault The vault to get the configuration for.
     *@return The configuration of the specified vault.
     */
    function getVaultConfiguration(Vaults _vault)
        public
        view
        returns (VaultConfig memory)
    {
        return VAULTS[uint256(_vault)];
    }

    /**
     *@dev Returns the percentage of harvesting bonus.
     *@return The percentage of harvesting bonus.
     */
    function getHarvestingBonusPercentage() public view returns (uint256) {
        return harvestingBonusPercentage;
    }

    /**
     *@dev Sets the percentage of harvesting bonus.
     *@param _harvestingBonusPercentage The new percentage of harvesting bonus.
     */
    function setHarvestingBonusPercentage(uint256 _harvestingBonusPercentage)
        public
        onlyOwner
    {
        harvestingBonusPercentage = _harvestingBonusPercentage;
    }

    /**
     *@dev Allows a user to stake a certain amount of tokens in a specified vault
     *@param _amount The amount of tokens to be staked
     *@param _vault The vault in which the tokens are to be staked
     *Requirements:
     *The contract must not be paused
     *The user must not have staked more than 5 times in the same vault
     *The user must have sufficient balance to stake the amount of tokens
     *The user must have approved the contract to spend at least _amount of tokens
     *The total amount of tokens staked in the specified vault must not exceed the max cap of that vault
     *Effects:
     *Increments the stakeId to keep track of stakes made
     *Updates the number of stakes made by the user in the specified vault
     *Calls the internal _stakeInVault function to handle the staking logic
     *Transfers the staked tokens from the user to the contract
     *Emits a Staked event with the user's address, stake ID, amount staked, vault, and timestamp
     */
    function stake(uint256 _amount, Vaults _vault)
        public
        whenNotPaused
        checkSendersStakeLimit(msg.sender, _vault)
    {
        require(
            Token.balanceOf(msg.sender) >= _amount,
            "Stake: Insufficient balance"
        );

        require(
            Token.allowance(msg.sender, address(this)) >= _amount,
            "Stake: Insufficient allowance"
        );

        require(
            (totalStakedInVault[_vault] + _amount) <=
                VAULTS[uint256(_vault)].maxCap,
            "Stake: Max stake cap reached"
        );

        stakeId.increment();

        stakesInVaultByAddress[msg.sender][_vault]++;
        _stakeInVault(msg.sender, _amount, _vault, stakeId.current());

        Token.transferFrom(msg.sender, address(this), _amount);

        emit Staked(
            msg.sender,
            stakeId.current(),
            _amount,
            _vault,
            block.timestamp
        );
    }

    /**
     *@dev Stake _amount of Token in a specific _vault by _sender through Airdrop contract.
     *@param _sender address The address of the sender.
     *@param _amount uint256 The amount of Token to stake.
     *@param _vault Vaults The enum of the vault where the stake will be made.
     *Requirements:
     *Only the Airdrop contract can call this function.
     *_sender must not have staked more than 5 times in the given _vault.
     *The total staked amount in the given _vault plus _amount must not exceed the maximum capacity of the vault.
     *Emits a {Staked} event indicating the amount of tokens staked, the sender, the vault, and the current timestamp.
     */
    function stakeByContract(
        address _sender,
        uint256 _amount,
        Vaults _vault
    ) external onlyAirdropContract checkSendersStakeLimit(_sender, _vault) {
        require(
            (totalStakedInVault[_vault] + _amount) <=
                VAULTS[uint256(_vault)].maxCap,
            "Stake: Max stake cap reached"
        );

        stakeId.increment();
        stakesInVaultByAddress[_sender][_vault]++;
        _stakeInVault(_sender, _amount, _vault, stakeId.current());

        emit Staked(
            _sender,
            stakeId.current(),
            _amount,
            _vault,
            block.timestamp
        );
    }

    /**
     *@dev Harvest rewards earned from a specific stake and restake them in the specified vault with a bonus.
     *@param _stakeId The ID of the stake to harvest rewards from.
     *@param _vault The vault where the rewards will be restaked with a bonus.
     *Requirements:
     *The function can only be called when the contract is not paused.
     *The function can only be called by the staker of the specified stake.
     *The stake must not have been unstaked.
     *There must be rewards to harvest.
     *The restaked amount plus bonus must not exceed the maximum capacity of the specified vault.
     *Effects:
     *Calculates the rewards earned from the specified stake.
     *Adds a bonus to the calculated rewards.
     *Restakes the calculated rewards plus bonus in the specified vault.
     *Transfers the bonus to the contract from the wallet.
     *Updates the stake information.
     *Emits a Harvest event with the staker address, the new stake ID, the harvested amount, the vault, the timestamp, and the bonus amount.
     */
    function harvestRewardTokens(uint256 _stakeId, Vaults _vault)
        public
        whenNotPaused
        nonReentrant
        checkSendersStakeLimit(msg.sender, _vault)
    {
        StakeInfo storage _stakeInfo = stakeInfoById[_stakeId];
        require(
            _stakeInfo.walletAddress == msg.sender,
            "Stake: Not the previous staker"
        );
        require(!_stakeInfo.unstaked, "Stake: No staked Tokens in the vault");
        uint256 _amountToRestake = _calculateRewards(_stakeId);

        require(_amountToRestake > 0, "Stake: Insufficient rewards to stake");

        uint256 _bonusAmount = ((_amountToRestake * harvestingBonusPercentage) /
            NUMERATOR);
        uint256 _amountWithBonus = _amountToRestake + _bonusAmount;

        require(
            (totalStakedInVault[_stakeInfo.vault] + _amountWithBonus) <=
                VAULTS[uint256(_stakeInfo.vault)].maxCap,
            "Stake: Max stake cap reached"
        );

        _stakeInfo.lastClaimedAt = block.timestamp;
        _stakeInfo.totalClaimed += _amountToRestake;

        stakeId.increment();

        stakesInVaultByAddress[msg.sender][_vault]++;
        _stakeInVault(msg.sender, _amountWithBonus, _vault, stakeId.current());
        Token.transferFrom(wallet, address(this), _bonusAmount);

        emit Harvest(
            msg.sender,
            stakeId.current(),
            _stakeId,
            _amountToRestake,
            _vault,
            block.timestamp,
            (_amountWithBonus - _amountToRestake)
        );
    }

    /**
     *
     *@dev Harvest all reward tokens from a particular vault and stake them again
     *@param _rewardVault Address of the vault from which reward will be harvested
     *@param _stakeVault Address of the vault from which rewards will be staked
     *Requirements:
     *Function can only be called when contract is not paused
     *Function must not be reentrant
     *The sender must not exceed their stake limit
     *The total restake amount must be greater than zero
     *The total amount to be staked, including bonuses, must not exceed the maximum cap for the vault
     *The harvesting bonus percentage must be valid
     *Effects:
     *Increases the amount staked in the vault by the sender
     *Transfers the bonus amount from the wallet to the contract
     *Emits:
     *HarvestAll event when all rewards are harvested and restaked successfully
     */
    function harvestAllRewardTokens(Vaults _rewardVault, Vaults _stakeVault)
        public
        whenNotPaused
        nonReentrant
        checkSendersStakeLimit(msg.sender, _rewardVault)
    {
        uint256 _totalRestakeAmount;
        uint256[] memory stakeIds = stakeIdsInVault[_rewardVault][msg.sender];

        for (uint256 i = 0; i < stakeIds.length; i++) {
            StakeInfo storage _stakeInfo = stakeInfoById[stakeIds[i]];
            require(
                _stakeInfo.walletAddress == msg.sender,
                "Stake: Not the previous staker"
            );
            if (!_stakeInfo.unstaked) {
                uint256 restakeAmount = _calculateRewards(stakeIds[i]);
                _totalRestakeAmount += restakeAmount;

                _stakeInfo.lastClaimedAt = block.timestamp;
                _stakeInfo.totalClaimed += restakeAmount;
            }
        }

        require(
            _totalRestakeAmount > 0,
            "Stake: Insufficient rewards to stake"
        );

        uint256 _totalBonusAmount = ((_totalRestakeAmount *
            harvestingBonusPercentage) / NUMERATOR);
        uint256 _totalAmountWithBonus = _totalRestakeAmount + _totalBonusAmount;

        require(
            (totalStakedInVault[_stakeVault] + _totalAmountWithBonus) <=
                VAULTS[uint256(_stakeVault)].maxCap,
            "Stake: Max stake cap reached"
        );

        stakeId.increment();

        stakesInVaultByAddress[msg.sender][_stakeVault]++;
        _stakeInVault(
            msg.sender,
            _totalAmountWithBonus,
            _stakeVault,
            stakeId.current()
        );
        Token.transferFrom(wallet, address(this), _totalBonusAmount);

        emit HarvestAll(
            msg.sender,
            stakeId.current(),
            stakeIds,
            _totalRestakeAmount,
            _stakeVault,
            block.timestamp,
            (_totalAmountWithBonus - _totalRestakeAmount)
        );
    }

    /**
     * @notice This function allows the staker to unstake their tokens and claim their rewards.
     * @dev The function first retrieves the stake information using the `_stakeId` parameter from the `stakeInfoById` mapping and stores it in the `_stakeInfo` variable.
     * It checks if the `walletAddress` in the `_stakeInfo` matches the `msg.sender`, i.e., the address calling the function. If not, it reverts with the message "Stake: Not the staker".
     * It checks if the stake has already been unstaked by checking the `unstaked` variable in the `_stakeInfo`. If it is true, it reverts with the message "Stake: No staked Tokens in the vault".
     * It retrieves the `VaultConfig` from the `VAULTS` mapping using the `_stakeInfo.vault` and stores it in the `vaultConfig` variable.
     * It checks if the current timestamp minus the `_stakeInfo.stakedAt` timestamp is greater than or equal to the `cliffInDays` of the `vaultConfig`. If not, it reverts with the message "Stake: Cannot unstake before the cliff".
     * It calculates the reward amount by calling the `_calculateRewards` function with the `_stakeId` parameter and stores it in the `_rewardAmount` variable.
     * It updates the `lastClaimedAt`, `totalClaimed`, and `unstaked` variables in the `_stakeInfo`.
     * It transfers the staked tokens back to the staker's address using the `transfer` function of the `Token` contract with the parameters `msg.sender` (i.e., staker's address) and `_stakeInfo.stakedAmount`.
     * It transfers the reward tokens from the `wallet` address to the staker's address using the `transferFrom` function of the `Token` contract with the parameters `wallet` (i.e., owner's address), `msg.sender` (i.e., staker's address), and `_rewardAmount`.
     * It emits an `Unstaked` event with the staker's address, `_stakeId`, `_stakeInfo.stakedAmount`, `_stakeInfo.totalClaimed`, `_stakeInfo.vault`, and the current timestamp as parameters.
     * @param _stakeId The ID of the stake to be unstaked
     */
    function unstake(uint256 _stakeId) public whenNotPaused nonReentrant {
        StakeInfo storage _stakeInfo = stakeInfoById[_stakeId];
        require(
            _stakeInfo.walletAddress == msg.sender,
            "Stake: Not the staker"
        );
        require(!_stakeInfo.unstaked, "Stake: No staked Tokens in the vault");
        VaultConfig memory vaultConfig = VAULTS[uint256(_stakeInfo.vault)];
        require(
            block.timestamp - _stakeInfo.stakedAt >= vaultConfig.cliffInDays,
            "Stake: Cannot unstake before the cliff"
        );

        uint256 _rewardAmount = _calculateRewards(_stakeId);

        _stakeInfo.lastClaimedAt = block.timestamp;
        _stakeInfo.totalClaimed += _rewardAmount;
        _stakeInfo.unstaked = true;

        Token.transfer(msg.sender, _stakeInfo.stakedAmount);
        Token.transferFrom(wallet, msg.sender, _rewardAmount);

        emit Unstaked(
            msg.sender,
            _stakeId,
            _stakeInfo.stakedAmount,
            _stakeInfo.totalClaimed,
            _stakeInfo.vault,
            block.timestamp
        );
    }

    /**
     *
     *@dev Allows the staker to claim their rewards from a specific stake
     *dev called the internal function _claimReward() to claim the reward tokens.
     *@param _stakeId The ID of the stake to claim rewards from
     *Emits a Claimed event with the details of the claim including the reward amount, stake ID, and timestamp
     *Throws an error if the caller is not the staker of the stake, or if there are no rewards to claim
     */
    function claimReward(uint256 _stakeId) public whenNotPaused nonReentrant {
        StakeInfo storage _stakeInfo = stakeInfoById[_stakeId];

        require(
            _stakeInfo.walletAddress == msg.sender,
            "Stake: Not the staker"
        );

        uint256 _rewardAmount = _calculateRewards(_stakeId);

        require(_rewardAmount > 0, "Stake: No Rewards to Claim");

        _stakeInfo.lastClaimedAt = block.timestamp;
        _stakeInfo.totalClaimed += _rewardAmount;

        Token.transferFrom(wallet, msg.sender, _rewardAmount);

        emit Claimed(
            msg.sender,
            _stakeId,
            _rewardAmount,
            _stakeInfo.vault,
            block.timestamp
        );
    }

    /**
     *
     *@dev Claim all reward tokens from a particular vault for the sender
     *@param _vault Address of the vault from which rewards will be claimed
     *Requirements:
     *Function can only be called when contract is not paused
     *Function must not be reentrant
     *Effects:
     *Increases the total amount claimed by the sender for each staked amount
     *Transfers the total reward amount from the wallet to the sender
     *Emits:
     *ClaimedAll event when all rewards are claimed successfully
     */
    function claimAllReward(Vaults _vault) public whenNotPaused nonReentrant {
        uint256 _totalReward;

        uint256[] memory stakeIds = stakeIdsInVault[_vault][msg.sender];

        for (uint256 i = 0; i < stakeIds.length; i++) {
            StakeInfo storage _stakeInfo = stakeInfoById[stakeIds[i]];

            require(
                _stakeInfo.walletAddress == msg.sender,
                "Stake: Not the staker"
            );

            uint256 _rewardAmount = _calculateRewards(stakeIds[i]);

            if (_rewardAmount > 0) {
                _totalReward += _rewardAmount;
                _stakeInfo.lastClaimedAt = block.timestamp;
                _stakeInfo.totalClaimed += _rewardAmount;
            }
        }
        require(_totalReward > 0, "Stake: No Rewards to Claim");
        Token.transferFrom(wallet, msg.sender, _totalReward);

        emit ClaimedAll(
            msg.sender,
            stakeIds,
            _totalReward,
            _vault,
            block.timestamp
        );
    }

    /**
     *
     *@dev Returns the amount of rewards that a staker would receive if they were to claim rewards for a specific stake
     *@param _stakeId The ID of the stake to calculate rewards for
     *@return The amount of rewards that can be claimed for the specified stake
     */
    function getStakingReward(uint256 _stakeId) public view returns (uint256) {
        return _calculateRewards(_stakeId);
    }

    /**
     *
     *@dev Returns an array of StakeInfo structs representing all stakes made by a specific wallet address in a specific vault
     *@param _addr The address of the wallet to retrieve stake info for
     *@param _vault The enum value representing the vault to retrieve stake info for
     *@return stakeInfos An array of StakeInfo structs representing all stakes made by the specified wallet address in the specified vault
     */
    function getStakeInfo(address _addr, Vaults _vault)
        public
        view
        returns (StakeInfo[] memory stakeInfos)
    {
        uint256[] memory stakeIds = stakeIdsInVault[_vault][_addr];
        stakeInfos = new StakeInfo[](stakeIds.length);

        for (uint256 i = 0; i < stakeIds.length; i++) {
            stakeInfos[i] = stakeInfoById[uint256(stakeIds[i])];
        }
    }

    /**
     *
     *@dev Returns the StakeInfo struct for a specific stake ID
     *@param _stakeId The ID of the stake to retrieve information for
     *@return The StakeInfo struct representing the specified stake
     */
    function getStakeInfoById(uint256 _stakeId)
        public
        view
        returns (StakeInfo memory)
    {
        return stakeInfoById[_stakeId];
    }

    /**
     *
     *@dev Returns the total number of stakes that have been made
     *@return The total number of stakes
     */
    function totalStakes() public view returns (uint256) {
        return stakeId.current();
    }

    /**
     *
     *@dev Returns the total amount of tokens staked in a specific vault
     *@param _vault The enum value representing the vault to retrieve the total staked tokens for
     *@return The total amount of tokens staked in the specified vault
     */
    function tokensStakedInVault(Vaults _vault) public view returns (uint256) {
        return totalStakedInVault[_vault];
    }
}
