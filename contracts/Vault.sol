// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Vault
 * @author Muhammad Usman
 * @dev An abstract contract that provides functionality for staking and harvesting rewards in multiple vaults.
 */

abstract contract Vault {
    /// @dev Constants used in calculations.
    uint256 constant NUMERATOR = 1000;
    uint256 constant ONE_YEAR = 365 days;

    /// @dev The percentage of bonus rewards earned when harvesting.
    uint256 harvestingBonusPercentage;

    /// @dev Enum defining the different types of vaults available for staking.
    enum Vaults {
        vault_1,
        vault_2,
        vault_3
    }

    /// @dev Struct containing information about a specific stake.
    struct StakeInfo {
        address walletAddress;
        uint256 stakeId;
        uint256 stakedAmount;
        uint256 lastClaimedAt;
        uint256 totalClaimed;
        uint256 stakedAt;
        Vaults vault;
        bool unstaked;
    }

    /// @dev Struct containing configuration information for a specific vault.
    struct VaultConfig {
        uint256 apr;
        uint256 maxCap;
        uint256 cliffInDays;
    }

    /// @dev An array containing the configuration for each of the three vaults.
    VaultConfig[3] VAULTS;

    /// @dev A mapping of the stake IDs associated with each wallet and vault.
    mapping(Vaults => mapping(address => uint256[])) internal stakeIdsInVault;
    /// @dev A mapping of the total amount staked in each vault.
    mapping(Vaults => uint256) internal totalStakedInVault;
    /// @dev A mapping of stake information associated with each stake ID.
    mapping(uint256 => StakeInfo) stakeInfoById;
    /// @dev A mapping of the number of stakes associated with each wallet and vault.
    mapping(address => mapping(Vaults => uint8)) stakesInVaultByAddress;

    /**
     * @dev Event emitted when a new stake is made.
     * @param walletAddr The address of the wallet making the stake.
     * @param stakeId The ID of the new stake.
     * @param amount The amount being staked.
     * @param vault The type of vault the stake is being made in.
     * @param timestamp The timestamp of the stake.
     */
    event Staked(
        address indexed walletAddr,
        uint256 indexed stakeId,
        uint256 amount,
        Vaults indexed vault,
        uint256 timestamp
    );

    /**
     * @dev Event emitted when a harvest is made.
     * @param walletAddr The address of the wallet making the harvest.
     * @param stakeId The ID of the stake being harvested.
     * @param previousStakeId The ID of the previous stake.
     * @param amount The amount being harvested.
     * @param vault The type of vault the stake is being harvested from.
     * @param timestamp The timestamp of the harvest.
     * @param bonus The amount of bonus rewards earned.
     */
    event Harvest(
        address indexed walletAddr,
        uint256 indexed stakeId,
        uint256 previousStakeId,
        uint256 amount,
        Vaults indexed vault,
        uint256 timestamp,
        uint256 bonus
    );

        event HarvestAll(
        address indexed walletAddr,
        uint256 indexed stakeId,
        uint256[] previousStakeIds,
        uint256 amount,
        Vaults indexed vault,
        uint256 timestamp,
        uint256 bonus
    );

    /**
     * @dev Even emitted when unstaked
     * @param walletAddr The address of the wallet which is Unstaking
     * @param stakeId The ID of the stake being unstaked
     * @param stakedAmount Amount that was staked
     * @param totalRewardsClaimed Total reward earned
     * @param vault Vault where tokens were staked
     * @param timestamp Unix timestamp for unstake time
     */
    event Unstaked(
        address indexed walletAddr,
        uint256 indexed stakeId,
        uint256 stakedAmount,
        uint256 totalRewardsClaimed,
        Vaults indexed vault,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a user claims rewards from a staked amount.
     * @param walletAddr The address of the user who claimed the rewards.
     * @param stakeId The ID of the stake.
     * @param claimedAmount The amount of rewards claimed by the user.
     * @param vault The vault in which the stake was made.
     * @param timestamp The timestamp at which the rewards were claimed.
     */
    event Claimed(
        address indexed walletAddr,
        uint256 indexed stakeId,
        uint256 claimedAmount,
        Vaults indexed vault,
        uint256 timestamp
    );

        event ClaimedAll(
        address indexed walletAddr,
        uint256[] stakeId,
        uint256 claimedAmount,
        Vaults indexed vault,
        uint256 timestamp
    );

    /**
     *
     *@dev Internal function for staking an amount in a vault. This function creates a new StakeInfo object and stores it in stakeInfoById mapping. It also adds the stake ID to the stakeIdsInVault mapping and increments the totalStakedInVault value for the specified vault.
     *@param _address The address of the wallet that is staking.
     *@param _amount The amount to be staked.
     *@param _vault The vault to which the stake belongs.
     *@param _currentStakeId The current stake ID.
     */
    function _stakeInVault(
        address _address,
        uint256 _amount,
        Vaults _vault,
        uint256 _currentStakeId
    ) internal {
        stakeIdsInVault[_vault][_address].push(_currentStakeId);
        stakeInfoById[_currentStakeId] = StakeInfo(
            _address,
            _currentStakeId,
            _amount,
            block.timestamp,
            0,
            block.timestamp,
            _vault,
            false
        );

        totalStakedInVault[_vault] += _amount;
    }

    /**
     *
     *@dev Calculates the reward amount for a given stake ID based on the time elapsed
     *and the APR of the associated vault.
     *@param _stakeId The ID of the stake to calculate rewards for.
     *@return rewardAmount The amount of rewards to be claimed for the stake.
     */
    function _calculateRewards(
        uint256 _stakeId
    ) internal view returns (uint256 rewardAmount) {
        StakeInfo memory stakeInfo = stakeInfoById[_stakeId];
        VaultConfig memory vault = VAULTS[uint256(stakeInfo.vault)];
        uint256 endTime = block.timestamp >
            (stakeInfo.stakedAt + vault.cliffInDays)
            ? stakeInfo.stakedAt + vault.cliffInDays
            : block.timestamp;

        if (endTime < stakeInfo.lastClaimedAt) {
            return (0);
        }

        uint256 totalTime = ((endTime - stakeInfo.lastClaimedAt) * NUMERATOR) /
            ONE_YEAR;

        uint256 rewardPercentage = totalTime * vault.apr;
        rewardAmount =
            (stakeInfo.stakedAmount * rewardPercentage) /
            (100 * NUMERATOR);
    }
}
