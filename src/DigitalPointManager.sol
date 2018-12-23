pragma solidity ^0.4.24;

import "./tokens/RightsBaseToken.sol";
import "./tokens/TokenManager.sol";
import "./utils/RDDNControl.sol";
import "./utils/ManagerRole.sol";

import "openzeppelin-solidity/access/roles/MinterRole.sol";
import "openzeppelin-solidity/math/SafeMath.sol";

/// @title DigitalPointManager
/// @dev Manager of ERC20 based tokens to use point.
contract DigitalPointManager is RDDNControl, TokenManager {

    /// @dev Function to mint tokens
    /// @param _to The address that will receive the minted tokens.
    /// @param _value The amount of tokens to mint.
    /// @param _tokenId  token identifer.
    /// @return A boolean that indicates if the operation was successful.
    function mint(
        address _to,
        uint256 _value,
        uint256 _tokenId
    )
        public
        onlyMinter
        whenNotPaused
        returns (bool)
    {
        require(_exists(_tokenId));
        RightsBaseToken token = RightsBaseToken(contracts[_tokenId]);
        require(token.decimals() == 0);

        token.mint(_to, _value);
        _handleTokenHolder(address(0), _to, _tokenId, _value);

        emit Mint(msg.sender, _to, _value, _tokenId);
        return true;
    }

    /// @dev Burns a specific amount of tokens.
    /// @param _to The address that will receive the minted tokens.
    /// @param _value The amount of token to be burned.
    /// @param _tokenId  token identifer.
    /// @return A boolean that indicates if the operation was successful.
    function burnFrom(
        address _to,
        uint256 _value,
        uint256 _tokenId
    )
        public
        whenNotPaused
        returns (bool)
    {
        require(_exists(_tokenId));
        require(ownerOf(_tokenId) == msg.sender);
        RightsBaseToken token = RightsBaseToken(contracts[_tokenId]);
        token.burnFrom(_to, _value);
        _handleTokenHolder(_to, address(0), _tokenId, _value);

        emit Burn(msg.sender, _to, _value, _tokenId);
        return true;
    }
}