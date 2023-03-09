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
 * @title TokenSwap
 * @author Muhammad Usman
 * @dev This smart contract allows users to swap between USDC and NUO tokens.
 *      It retrieves the price of USDC in USD from a Chainlink price feed and uses it to calculate
 *      the equivalent NUO token value and vice versa for the swap.
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract TokenSwap is Initializable, OwnableUpgradeable, PausableUpgradeable {
    address usdcPricingContract;
    IERC20Upgradeable public UsdcToken;
    IERC20Upgradeable public NuoToken;
    uint256 public tokenPriceInUsd;
    uint256 public minSwapAmount;

    event Sold(address indexed seller, uint256 amount);
    event Purchased(address indexed buyer, uint256 amount);

    /**
     * @dev Initializes the contract with the initial token swap parameters.
     * @param _tokenAddress The address of the NUO token contract.
     * @param _tokenPriceInUsd The initial price of NUO token in USD.
     * @param _minSwapAmount The minimum amount of tokens required for a swap.
     * @param _usdcToken The address of the USDC token contract.
     * @param _usdcPricingContract The address of the Chainlink price feed contract for USDC/USD.
     */
    function initialise(
        IERC20Upgradeable _tokenAddress,
        uint256 _tokenPriceInUsd,
        uint256 _minSwapAmount,
        IERC20Upgradeable _usdcToken,
        address _usdcPricingContract
    ) public initializer {
        require(_minSwapAmount > 0, "Swap: Minimum swap amount cannot be zero");
        require(
            (address(_tokenAddress) != address(0)) &&
                (address(_usdcToken) != address(0)),
            "Swap: Address cannot be 0x0"
        );
        NuoToken = _tokenAddress;
        tokenPriceInUsd = _tokenPriceInUsd;
        minSwapAmount = _minSwapAmount;
        UsdcToken = _usdcToken;
        usdcPricingContract = _usdcPricingContract;

        __Ownable_init();
        __Pausable_init();
    }

    /**
     * @dev Pauses the contract. Only the owner can call this function.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Only the owner can call this function.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Updates the NUO token contract address. Only the owner can call this function.
     * @param _tokenAddress The new address of the NUO token contract.
     */
    function updateToken(IERC20Upgradeable _tokenAddress) public onlyOwner {
        require(
            address(_tokenAddress) != address(0),
            "Swap: Token cannot be 0x0"
        );
        NuoToken = _tokenAddress;
    }

    /**
     * @dev Updates the current price of 1 NUO token in USD to the specified value. This function can be called only by the owner.
     * @param _tokenPriceInUsd The new price of 1 NUO token in USD.
     */
    function updateTokenPrice(uint256 _tokenPriceInUsd) public onlyOwner {
        tokenPriceInUsd = _tokenPriceInUsd;
    }

    /**
     * @dev Updates the minimum amount of NUO or USDC tokens that can be swapped to the specified value. This function can be called only by the owner.
     * @param _minSwapAmount The new minimum swap amount.
     */
    function updateMinimumSwapAmount(uint256 _minSwapAmount) public onlyOwner {
        require(_minSwapAmount > 0, "Swap: Minimum swap amount cannot be zero");
        minSwapAmount = _minSwapAmount;
    }

    /**
     *
     *@dev Updates the address of the USDC token used in the Swap contract.
     *Only the contract owner is allowed to call this function.
     *@param _usdcTokenAddress The new address of the USDC token.
     *Requirements:
     *_usdcTokenAddress cannot be the zero address.
     *Emits a UsdcTokenUpdated event indicating the updated USDC token address.
     */
    function updateUsdcToken(
        IERC20Upgradeable _usdcTokenAddress
    ) public onlyOwner {
        require(
            address(_usdcTokenAddress) != address(0),
            "Swap: Token cannot be 0x0"
        );
        UsdcToken = _usdcTokenAddress;
    }

    /**
     *
     *@dev The swap function allows users to swap NUO tokens for USDC or USDC tokens for NUO.
     *@param _tokenName The name of the token to swap ("NUO" or "USDC").
     *@param _tokenAmount The amount of tokens to swap.
     *Requirements:
     *The contract must not be paused.
     *The token name must be either "NUO" or "USDC".
     *If the token name is "NUO", the user must have sufficient balance of NUO tokens to swap.
     *If the token name is "USDC", the user must have sufficient balance of USDC tokens to swap.
     *The swap amount must be greater than or equal to the minimum swap amount set by the contract.
     *Effects:
     *If the token name is "NUO", the function sells the specified amount of NUO tokens and transfers the corresponding amount of USDC tokens to the user.
     *If the token name is "USDC", the function buys the specified amount of NUO tokens and transfers them to the user.
     *Emits:
     *Sold event when the user swaps NUO tokens for USDC tokens.
     *Purchased event when the user swaps USDC tokens for NUO tokens.
     */
    function swap(
        string memory _tokenName,
        uint256 _tokenAmount
    ) public whenNotPaused {
        require(
            keccak256(abi.encodePacked(_tokenName)) ==
                keccak256(abi.encodePacked("NUO")) ||
                keccak256(abi.encodePacked(_tokenName)) ==
                keccak256(abi.encodePacked("USDC")),
            "Swap: Invalid token name"
        );
        keccak256(abi.encodePacked(_tokenName)) ==
            keccak256(abi.encodePacked("NUO"))
            ? _sell(_tokenAmount)
            : _buy(_tokenAmount);
    }

    /**
     *
     *@dev The _sell function is an internal function used to sell NUO tokens for USDC tokens.
     *@param _tokenAmount The amount of NUO tokens to sell.
     *Requirements:
     *The contract must have sufficient balance of NUO tokens to swap.
     *The swap amount must be greater than or equal to the minimum swap amount set by the contract.
     *Effects:
     *Transfers the specified amount of NUO tokens from the user to the contract.
     *Transfers the corresponding amount of USDC tokens from the contract to the user.
     *Emits:
     *Sold event when the user swaps NUO tokens for USDC tokens.
     */
    function _sell(uint256 _tokenAmount) internal {
        require(_tokenAmount >= minSwapAmount, "Swap: Too low value for Swap");
        require(
            NuoToken.balanceOf(msg.sender) >= _tokenAmount,
            "Swap: Insufficient token balance"
        );

        NuoToken.transferFrom(msg.sender, address(this), _tokenAmount);
        uint256 _usdcAmount = tokensIntoUsdc(_tokenAmount);
        UsdcToken.transfer(msg.sender, _usdcAmount);

        emit Sold(msg.sender, _tokenAmount);
    }

    /**
     *
     *@dev The _buy function is an internal function used to buy NUO tokens with USDC tokens.
     *@param _usdcAmount The amount of USDC tokens to use for buying NUO tokens.
     *Requirements:
     *The contract must have sufficient balance of USDC tokens to swap.
     *Effects:
     *Transfers the specified amount of USDC tokens from the user to the contract.
     *Transfers the corresponding amount of NUO tokens from the contract to the user.
     *Emits:
     *Purchased event when the user swaps USDC tokens for NUO tokens.
     */
    function _buy(uint256 _usdcAmount) internal {
        require(
            UsdcToken.balanceOf(msg.sender) >= (_usdcAmount),
            "Swap: Insufficient token balance"
        );
        UsdcToken.transferFrom(msg.sender, address(this), _usdcAmount);
        uint256 _tokenAmount = usdcIntoTokens((_usdcAmount * 10 ** 12));
        NuoToken.transfer(msg.sender, _tokenAmount);

        emit Purchased(msg.sender, _usdcAmount);
    }

    /**
     * @notice Convert an amount of NUO tokens into USDC tokens based on the current token price in USD
     * @dev Uses the stored tokenPriceInUsd and _getUsdcToUsdPrice functions to calculate the conversion
     * @param _tokenAmount The amount of NUO tokens to convert to USDC tokens
     * @return The amount of USDC tokens equivalent to the given amount of NUO tokens
     */
    function tokensIntoUsdc(
        uint256 _tokenAmount
    ) public view returns (uint256) {
        uint256 priceInUsdc = ((_tokenAmount * tokenPriceInUsd) /
            _getUsdcToUsdPrice());
        return priceInUsdc / 10 ** 12;
    }

    /**
     * @notice Convert an amount of USDC tokens into NUO tokens based on the current token price in USD
     * @dev Uses the stored tokenPriceInUsd and _getUsdcToUsdPrice functions to calculate the conversion
     * @param _usdcAmount The amount of USDC tokens to convert to NUO tokens
     * @return The amount of NUO tokens equivalent to the given amount of USDC tokens
     */
    function usdcIntoTokens(uint256 _usdcAmount) public view returns (uint256) {
        uint256 priceInNuo = ((_usdcAmount * _getUsdcToUsdPrice()) /
            tokenPriceInUsd);
        return priceInNuo;
    }

    /**
     * @notice Retrieve the current USDC/USD price from the price feed contract
     * @dev Uses the stored usdcPricingContract address to fetch the current price from the aggregator interface
     * @return The current price of USDC in USD with 18 decimal places of precision
     */
    function _getUsdcToUsdPrice() internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            address(usdcPricingContract)
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return (uint256(price) * 10 ** (18 - priceFeed.decimals()));
    }

    /**
     * @notice Transfer a specified amount of NUO tokens from the contract to the contract owner
     * @dev Only the contract owner can call this function
     * @param _amount The amount of NUO tokens to transfer
     */
    function withdrawTokens(uint256 _amount) public onlyOwner {
        uint256 balance = NuoToken.balanceOf(address(this));
        require(balance >= _amount, "Swap: Not enough balance");
        NuoToken.transfer(msg.sender, balance);
    }

    /**
     * @notice Transfer a specified amount of USDC tokens from the contract to the contract owner
     * @dev Only the contract owner can call this function
     * @param _amount The amount of USDC tokens to transfer
     */
    function withdrawUsdc(uint256 _amount) public onlyOwner {
        uint256 balance = UsdcToken.balanceOf(address(this));
        require(balance >= _amount, "Swap: Not enough balance");
        UsdcToken.transfer(msg.sender, balance);
    }

    /**
     * @notice Transfer all NUO and USDC tokens held in the contract to a specified address in an emergency
     * @dev Only the contract owner can call this function
     * @param _address The address to transfer the NUO and USDC tokens to
     */
    function emergencyWithdraw(address _address) public onlyOwner {
        uint256 balanceNuo = NuoToken.balanceOf(address(this));
        NuoToken.transfer(_address, balanceNuo);

        uint256 balanceUsdc = UsdcToken.balanceOf(address(this));
        UsdcToken.transfer(_address, balanceUsdc);
    }
}
