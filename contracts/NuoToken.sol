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
 *@title NuoToken
 * @author Muhammad Usman
 *@dev This contract implements the ERC20 token standard with support for pausing, burning and
 *ownership functions. It also includes an initializer function to set up the initial token supply
 *and the token name and symbol. The contract is upgradeable and uses OpenZeppelin contracts for
 *implementation of ERC20, Ownable and Pausable functionality.
 */
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract NuoToken is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    /**
     *
     *@dev Initializer function that sets up the initial token supply, token name and symbol.
     *@param _tokenName The name of the token.
     *@param _tokenSymbol The symbol of the token.
     *@param _totalSupply The total supply of tokens.
     */
    function initialise(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _totalSupply
    ) external initializer {
        __ERC20_init(_tokenName, _tokenSymbol);
        __Ownable_init();
        __Pausable_init();
        _mint(msg.sender, _totalSupply);
    }

    /**
     *
     *@dev Pauses all token transfers. Can only be called by the owner.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     *
     *@dev Unpauses all token transfers. Can only be called by the owner.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     *
     *@dev Overrides the ERC20 _beforeTokenTransfer hook to ensure that token transfers are
     *not allowed when the contract is paused.
     *@param from The address sending the tokens.
     *@param to The address receiving the tokens.
     *@param amount The amount of tokens being transferred.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {}

    /**
     *
     *@dev Allows a token holder to burn their own tokens.
     *@param amount The amount of tokens to burn.
     */
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}
