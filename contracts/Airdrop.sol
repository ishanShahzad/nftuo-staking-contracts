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
 *
 *@title Airdrop Contract
 * @author Muhammad Usman
 *@dev A contract for distributing tokens over time to whitelisted addresses
 *based on a predefined vesting schedule.
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/IStaking.sol";

contract Airdrop is Initializable, OwnableUpgradeable, PausableUpgradeable {
    // Struct to hold vesting information for a single address
    struct VestInfo {
        uint256 totalVestedAmount; // Total amount of tokens to be vested
        uint256 lastClaimedAt; // Timestamp of the last claim made by the address
        uint256 totalClaimed; // Total amount of tokens claimed by the address
        uint256 claimsCount; // Number of times the address has claimed tokens
    }

    // Address of the token contract
    IERC20Upgradeable private NuoToken;
    uint256 private startTime;
    uint256 private trancheInDays;
    uint256 private claimPercentage;
    uint256 private claimsCap;
    bool private isStakingEnabled;

    IStaking private StakingContract;
    uint256 private totalTokenReleased;
    uint256 private expectedTokensAmount;

    address[] private whitelistedAddresses;

    mapping(address => VestInfo) private vestInfoByAddress;

    event Claimed(
        address indexed walletAddress,
        uint256 amount,
        uint256 claimedAt
    );

    event Staked(
        address indexed walletAddress,
        uint256 amount,
        uint256 stakedAt,
        address stakingContract
    );

    /**
     *
     *@dev Initializes the contract by setting the token and staking contract addresses,
     *start time, vesting schedule parameters and ownership and pausing mechanism.
     *@param _nuoToken The address of the token contract
     *@param _stakingContract The address of the staking contract
     *@param _startTime The timestamp of the start of the vesting period
     *@param _trancheTimeInDays The duration of each vesting tranche in days
     *@param _claimPercentage The percentage of tokens to be claimed in each tranche
     *@param _numOfClaims The maximum number of times an address can claim tokens
     */
    function initialise(
        IERC20Upgradeable _nuoToken,
        IStaking _stakingContract,
        uint256 _startTime,
        uint256 _trancheTimeInDays,
        uint256 _claimPercentage,
        uint256 _numOfClaims
    ) public initializer {
        NuoToken = _nuoToken;
        StakingContract = _stakingContract;
        startTime = _startTime;
        trancheInDays = _trancheTimeInDays * 1 days;
        claimPercentage = _claimPercentage;
        claimsCap = _numOfClaims;

        __Ownable_init();
        __Pausable_init();
    }

    function getTotalTokenReleased() public view returns (uint256) {
        return totalTokenReleased;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function toggleStakingStatus(bool _status) public onlyOwner {
        isStakingEnabled = _status;
    }

    function getStakingStatus() public view returns (bool) {
        return isStakingEnabled;
    }

    function getStakingContract() public view returns (IStaking) {
        return StakingContract;
    }

    function setStakingContract(IStaking _stakingContract) public onlyOwner {
        require(
            address(_stakingContract) != address(0),
            "Stake: Invalid address"
        );
        StakingContract = _stakingContract;
    }

    /**
     *
     *@dev Allows the owner to whitelist multiple addresses for token vesting.
     *@param _addresses Array of addresses to be whitelisted
     *@param _amounts Array of token amounts to be vested for each corresponding address
     *@notice Whitelisted addresses cannot be the zero address and must have a corresponding amount in the _amounts array
     *@notice Only the contract owner can call this function
     *@notice Emits a VestInfo event for each whitelisted address, indicating the amount, start time, and vesting progress
     *@notice Updates the whitelistedAddresses array and expectedTokensAmount
     */
    function whitelistAddresses(
        address[] memory _addresses,
        uint256[] memory _amounts
    ) public onlyOwner {
        require(
            _addresses.length == _amounts.length,
            "Airdrop: Incorrect array length"
        );

        for (uint256 i = 0; i < _addresses.length; i++) {
            require(
                _addresses[i] != address(0),
                "Airdrop: Address cannot be zero address"
            );
            vestInfoByAddress[_addresses[i]] = VestInfo(
                _amounts[i],
                startTime,
                0,
                0
            );
            whitelistedAddresses.push(_addresses[i]);
            expectedTokensAmount += _amounts[i];
        }
    }

    function getWhitelistedAddresses() public view returns (address[] memory) {
        return whitelistedAddresses;
    }

    function isWhitelisted(address _addr) public view returns (bool) {
        return (vestInfoByAddress[_addr].totalVestedAmount > 0);
    }

    /**
     *
     *@dev Allows an eligible user to claim their vested tokens.
     *@notice Users can only claim tokens after the specified start time and if they have at least one claim remaining.
     *@notice The maximum number of claims per user is 10.
     *@notice The amount of tokens available for the claim is based on the vesting schedule of the user.
     *@notice The claimed tokens are transferred to the user's address.
     *@notice Emits a Claimed event with the user's address, the claimed amount, and the block timestamp.
     *@notice Reverts if the contract is paused or if the user is not eligible to claim their tokens.
     */
    function claim() public whenNotPaused {
        require(block.timestamp >= startTime, "Airdrop: Too early!");
        VestInfo memory _vestInfo = vestInfoByAddress[msg.sender];
        require(
            _vestInfo.totalVestedAmount > 0 && _vestInfo.claimsCount < 10,
            "Airdrop: No Claim(s) Available"
        );
        (
            uint256 _totalClaimableAmount,
            uint256 _mod,
            uint256 _claimsCount
        ) = _calculateClaimableAmount(_vestInfo);

        _vestInfo.lastClaimedAt = block.timestamp - _mod;
        _vestInfo.claimsCount += _claimsCount;
        _vestInfo.totalClaimed += _totalClaimableAmount;
        vestInfoByAddress[msg.sender] = _vestInfo;
        totalTokenReleased += _totalClaimableAmount;

        NuoToken.transfer(msg.sender, _totalClaimableAmount);

        emit Claimed(msg.sender, _totalClaimableAmount, block.timestamp);
    }

    /**
     *
     *@dev This function allows users to stake their claimable tokens to the StakingContract's specified vault.
     *Users can only stake their claimable tokens if staking is enabled and the current time is after the startTime of the airdrop.
     *Users must also have available claims and vested tokens to be able to stake.
     *Once staked, the claimable tokens are transferred to the StakingContract and then staked on behalf of the user.
     *The vesting information for the user is updated to reflect the staked tokens, and the totalTokenReleased variable is incremented.
     *@param _vault The vault in the StakingContract that the user wishes to stake their tokens in.
     */
    function stake(IStaking.Vaults _vault) public whenNotPaused {
        require(
            isStakingEnabled,
            "Airdrop: Staking is disabled, please come back later"
        );
        require(block.timestamp >= startTime, "Airdrop: Too early!");
        VestInfo memory _vestInfo = vestInfoByAddress[msg.sender];
        require(
            _vestInfo.totalVestedAmount > 0 && _vestInfo.claimsCount < 10,
            "Airdrop: No Claim(s) Available"
        );
        (
            uint256 _totalClaimableAmount,
            uint256 _mod,
            uint256 _claimsCount
        ) = _calculateClaimableAmount(_vestInfo);

        NuoToken.transfer(address(StakingContract), _totalClaimableAmount);
        StakingContract.stakeByContract(
            msg.sender,
            _totalClaimableAmount,
            _vault
        );

        _vestInfo.lastClaimedAt = block.timestamp - _mod;
        _vestInfo.claimsCount += _claimsCount;
        _vestInfo.totalClaimed += _totalClaimableAmount;
        vestInfoByAddress[msg.sender] = _vestInfo;
        totalTokenReleased += _totalClaimableAmount;

        emit Staked(
            msg.sender,
            _totalClaimableAmount,
            block.timestamp,
            address(this)
        );
    }

    /**
     *
     *@dev Internal Function Calculates the amount of tokens that can be claimed by the user based on the number of days since the last claim and the total amount of tokens vested for the user.
     *@param _vestInfo The vesting information of the user.
     *@return _totalClaimableAmount The total amount of tokens that can be claimed by the user.
     *@return _mod The remainder of days between the last claim and the current time.
     *@return _claimsCount The number of claims that can be made by the user.
     */
    function _calculateClaimableAmount(
        VestInfo memory _vestInfo
    )
        internal
        view
        returns (
            uint256 _totalClaimableAmount,
            uint256 _mod,
            uint256 _claimsCount
        )
    {
        require(
            block.timestamp >= _vestInfo.lastClaimedAt + trancheInDays,
            "Airdrop: No claim(s) available"
        );

        _claimsCount =
            (block.timestamp - _vestInfo.lastClaimedAt) /
            trancheInDays;

        uint256 amountForSingleClaim = (_vestInfo.totalVestedAmount *
            claimPercentage) / 100;
        _totalClaimableAmount = amountForSingleClaim * _claimsCount;

        if (
            (_claimsCount + _vestInfo.claimsCount) >= claimsCap ||
            _totalClaimableAmount + _vestInfo.totalClaimed >=
            _vestInfo.totalVestedAmount
        ) {
            _totalClaimableAmount =
                _vestInfo.totalVestedAmount -
                _vestInfo.totalClaimed;
            _mod = 0;
            _claimsCount = claimsCap - _vestInfo.claimsCount;
        } else {
            _mod = (block.timestamp - _vestInfo.lastClaimedAt) % trancheInDays;
        }
    }

    /**
     *
     *@dev Returns the total amount of tokens available to be claimed by a given address.
     *@param _address The address of the user.
     *@return _totalClaimableAmount The total amount of tokens that can be claimed by the given address.
     */
    function availableAmountToClaim(
        address _address
    ) external view returns (uint256 _totalClaimableAmount) {
        (_totalClaimableAmount, , ) = _calculateClaimableAmount(
            vestInfoByAddress[_address]
        );
    }

    /**
     *
     *@dev Get the vesting information for a given address.
     *@param _addr The address for which to retrieve vesting information.
     *@return vestInfo The vesting information for the given address.
     */
    function getVestInfo(
        address _addr
    ) public view returns (VestInfo memory vestInfo) {
        return vestInfoByAddress[_addr];
    }

    /**
     *
     *@dev Returns the amount of funds required in the contract.
     *The amount is calculated as the difference between the expected token amount and the total token released
     *minus the token balance of the contract.
     *@return An int256 representing the amount of funds required in the contract.
     */
    function fundsRequiredInContract() public view returns (int256) {
        return
            int256(expectedTokensAmount) -
            int256(totalTokenReleased) -
            int256(NuoToken.balanceOf(address(this)));
    }

    /**
     *
     *@dev Withdraws _amount of NUO tokens from the contract to the given _address.
     *This function can only be called by the owner of the contract.
     *@param _address The address to which the NUO tokens are transferred.
     *@param _amount The amount of NUO tokens to be transferred.
     */
    function withdrawTokens(
        address _address,
        uint256 _amount
    ) public onlyOwner {
        NuoToken.transfer(_address, _amount);
    }
}
