pragma solidity ^0.4.24;

import "./../utils/LinkedIdList.sol";
import "openzeppelin-solidity/math/SafeMath.sol";

contract MultiTokenModule {

    using SafeMath for uint;

    event AddRelatedToken(
        address owner,
        uint256 keyId,
        uint256 tokenId,
        uint256 rate
    );

    event RemoveRelatedToken(
        address owner,
        uint256 keyId,
        uint256 tokenId
    );

    event UpdateRelatedToken(
        address owner,
        uint256 keyId,
        uint256 tokenId,
        uint256 rate
    );

    event ChangeBaseToken(
        address owner,
        uint256 keyId,
        uint256 tokenId
    );


    // Mapping from key id to exchange rate of the token
    mapping(uint256 => mapping(uint256 => uint256)) private keyIdTokensRate;
    // Mapping from key id to the base token
    mapping(uint256 => uint256) private baseToken;
    // decimals of rate
    uint8 private _rateDecimals;

    // Mapping from keyId to token Ids
    LinkedIdList private tokenIdList;


    constructor() public {
        _rateDecimals = 4;
        tokenIdList = new LinkedIdList();
    }


    /// @return the number of decimals of the rate.
    function rateDecimals() public view returns(uint8) {
        return _rateDecimals;
    }

    /// @dev Aadd a token id to the list of a given key id
    /// @param _keyId key id of the tokens list
    /// @param _tokenId id of the token to be added to the tokens list of the given key id
    /// @param _rate rate
    function _addRelatedToken(
        uint256 _keyId,
        uint256 _tokenId,
        uint256 _rate
    ) internal {
        require(!_isRegisteredToken(_keyId, _tokenId));

        // set base token
        if (tokenIdList.totalOf(_keyId) == 0) {
            _changeBaseToken(_keyId, _tokenId);
        }

        // set id
        tokenIdList.add(_keyId, _tokenId);

        // set rate
        keyIdTokensRate[_keyId][_tokenId] = _rate;

        emit AddRelatedToken(msg.sender, _keyId, _tokenId, _rate);
    }

    /// @dev Remove a token ID from the list of a key id
    /// @param _keyId key id of the tokens list
    /// @param _tokenId id of the token to be added to the tokens list of the given key id
    function _removeRelatedToken(uint256 _keyId, uint256 _tokenId) internal  {
        require(_isRegisteredToken(_keyId, _tokenId));
        require(_baseTokenOf(_keyId) != _tokenId);

        tokenIdList.remove(_keyId, _tokenId);

        // clear rate
        keyIdTokensRate[_keyId][_tokenId] = 0;

        emit RemoveRelatedToken(msg.sender, _keyId, _tokenId);
    }

    /// @dev Update a token info from the list of a key id
    /// @param _keyId key id of the tokens list
    /// @param _tokenId id of the token to be updated
    /// @param _rate rate
    function _updateRelatedToken(
        uint256 _keyId,
        uint256 _tokenId,
        uint256 _rate,
        bool isBase
    ) internal {
        require(_isRegisteredToken(_keyId, _tokenId));

        if (isBase) {
            // set base token
            _changeBaseToken(_keyId, _tokenId);
        }

        // set rate
        keyIdTokensRate[_keyId][_tokenId] = _rate;

        emit UpdateRelatedToken(msg.sender, _keyId, _tokenId, _rate);
    }

    /// @dev Get ths exchange rate of the token id
    /// @param _keyId key id of the tokens list
    /// @param _tokenId id of the token to be added to the tokens list of the given key id
    function _rateOf(uint256 _keyId, uint256 _tokenId) internal view returns (uint256) {
        require(_isRegisteredToken(_keyId, _tokenId));
        return keyIdTokensRate[_keyId][_tokenId];
    }

    /// @dev Returns whether the specified token id registered
    /// @param _keyId key id of the token id list
    /// @param _tokenId id of the token to be added to the token id list of the given key id
    /// @return whether the token registered
    function _isRegisteredToken(uint256 _keyId, uint256 _tokenId) internal view returns (bool) {
        // return tokenRegistrationStatus[_keyId][_tokenId];
        return tokenIdList.exists(_keyId, _tokenId);
    }

    /// @dev Returns base token id
    /// @param _keyId key id of the token id list
    /// @return token id
    function _baseTokenOf(uint256 _keyId) internal view returns (uint256) {
        return baseToken[_keyId];
    }

    /// @dev Returns token id list of the specified key id
    /// @param _keyId key id of the token id list
    /// @return token id list
    function _tokensOfKey(uint256 _keyId) internal view returns (uint256[]) {
        return tokenIdList.valuesOf(_keyId);
    }

    /// @dev Calculate amount by exchange rate
    /// @param _keyId key id of the token id list
    /// @param _tokenId id of the token to be added to the tokens list of the given key id
    /// @param _amout amount
    function _exchangedAmountOf(
        uint256 _keyId,
        uint256 _tokenId,
        uint256 _amout
    ) internal view returns (uint256) {
         // calculate amount
        if(_baseTokenOf(_keyId) != _tokenId) {
            return _amout
                .mul(_rateOf(_keyId, _tokenId))
                .div(10 ** uint256(rateDecimals()));
        } else {
            return _amout;
        }
    }

    /// @dev Update status whether the token is base
    /// @param _keyId key id of the tokens list
    /// @param _tokenId id of the token to be added to the tokens list of the given key id
    function _changeBaseToken(uint256 _keyId, uint256 _tokenId) private {
        baseToken[_keyId] = _tokenId;
        emit ChangeBaseToken(msg.sender, _keyId, _tokenId);
    }
}
