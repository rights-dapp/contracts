pragma solidity ^0.4.24;

import "./DigitalMoneyManager.sol";
import "./RDDNMarket.sol";

import "./utils/RDDNControl.sol";
import "./modules/MultiTokenModule.sol";

/// @title RDDNMarketMoney
/// @dev Money controller for markets.
contract RDDNMarketMoney is RDDNControl, MultiTokenModule {

    /*** STORAGE ***/

    RDDNMarket private rddnMarket;
    DigitalMoneyManager private moneyManager;


    /*** CONSTRUCTOR ***/

    constructor (
        address _marketAddr,
        address _moneyManagerAddr
    ) public {
        require(_marketAddr != address(0x0));
        require(_moneyManagerAddr != address(0x0));

        rddnMarket = RDDNMarket(_marketAddr);
        moneyManager = DigitalMoneyManager(_moneyManagerAddr);
    }

    
    /*** External Functions ***/

    /// @dev Aadd a money id to the list of a given live room id
    /// @param _marketId id of the live room
    /// @param _moneyId money id
    /// @param _rate rate
    function addPayableMoney(
        uint256 _marketId,
        uint256 _moneyId,
        uint256 _rate
    ) external whenNotPaused returns (bool) {
        require(rddnMarket.ownerOf(_marketId) == msg.sender);
        require(moneyManager.ownerOf(_moneyId) != address(0));

        _addRelatedToken(_marketId, _moneyId, _rate);
        return true;
    }

    /// @dev Update money info of a given live room id
    /// @param _marketId id of the live room
    /// @param _moneyId money id
    /// @param _rate rate
    /// @param _isBase whether the token is base
    function updatePayableMoney(
        uint256 _marketId,
        uint256 _moneyId,
        uint256 _rate,
        bool _isBase
    ) external whenNotPaused returns (bool){
        require(rddnMarket.ownerOf(_marketId) == msg.sender);
        require(moneyManager.ownerOf(_moneyId) != address(0));

        _updateRelatedToken(_marketId, _moneyId, _rate, _isBase);
        return true;
    }

    /// @dev Remove a money ID from the list of a live room id
    /// @param _marketId id of the live room
    /// @param _moneyId money id
    function removePayableMoney(
        uint256 _marketId,
        uint256 _moneyId
    ) external whenNotPaused returns (bool) {
        require(rddnMarket.ownerOf(_marketId) == msg.sender);
        require(moneyManager.ownerOf(_moneyId) != address(0));

        _removeRelatedToken(_marketId, _moneyId);
        return true;
    }

    /// @dev Returns money rate of the specified live room id
    /// @param _marketId id of the live room
    /// @param _moneyId money id
    /// @return whether the token is available
    function moneyRateOf(uint256 _marketId, uint256 _moneyId) public view returns (uint256) {
        require(rddnMarket.ownerOf(_marketId) != address(0));
        require(moneyManager.ownerOf(_moneyId) != address(0));

        return _rateOf(_marketId, _moneyId);
    }

    /// @dev Returns whether the specified money id is payable
    /// @param _marketId id of the live room
    /// @param _moneyId money id
    /// @return whether the token is available
    function isPayableMoney(uint256 _marketId, uint256 _moneyId) public view returns (bool) {
        require(rddnMarket.ownerOf(_marketId) != address(0));
        require(moneyManager.ownerOf(_moneyId) != address(0));

        return _isRegisteredToken(_marketId, _moneyId);
    }

    /// @dev Returns base money id list of the specified live room id
    /// @param _marketId id of the live room
    /// @return money id list
    function baseMoneyOf(uint256 _marketId) public view returns (uint256) {
        require(rddnMarket.ownerOf(_marketId) != address(0));
        return _baseTokenOf(_marketId);
    }

    /// @dev Returns money id list of the specified live room id
    /// @param _marketId id of the live room
    /// @return money id list
    function payableMoneysOf(uint256 _marketId) public view returns (uint256[]) {
        require(rddnMarket.ownerOf(_marketId) != address(0));
        return _tokensOfKey(_marketId);
    }

    /// @dev Calculate amount by exchange rate
    /// @param _marketId id of the live room
    /// @param _moneyId id of the money
    /// @param _amout amount
    function exchangedAmountOf(
        uint256 _marketId,
        uint256 _moneyId,
        uint256 _amout
    ) public view returns (uint256) {
        require(rddnMarket.ownerOf(_marketId) != address(0));
        require(moneyManager.ownerOf(_moneyId) != address(0));

         // calculate amount
        uint256 relativeAmount = moneyManager.relativeAmountOf(_moneyId, baseMoneyOf(_marketId), _amout);
        return _exchangedAmountOf(_marketId, _moneyId, relativeAmount);
    }
}