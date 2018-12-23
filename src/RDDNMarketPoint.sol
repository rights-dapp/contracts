pragma solidity ^0.4.24;

import "./DigitalPointManager.sol";
import "./RDDNMarket.sol";

import "./utils/RDDNControl.sol";
import "./modules/MultiTokenModule.sol";

/// @title RDDNMarketMoney
/// @dev Point controller for markets.
contract RDDNMarketPoint is RDDNControl, MultiTokenModule {

    /*** STORAGE ***/

    RDDNMarket private rddnMarket;
    DigitalPointManager private pointManager;
    

    /*** CONSTRUCTOR ***/

    constructor (
        address _marketAddr,
        address _pointManagerAddr
    ) public {
        require(_marketAddr != address(0x0));
        require(_pointManagerAddr != address(0x0));

        rddnMarket = RDDNMarket(_marketAddr);
        pointManager = DigitalPointManager(_pointManagerAddr);
    }

    
    /*** External Functions ***/

    /// @dev Aadd a point id to the list of a given live room id
    /// @param _marketId id of the live room
    /// @param _pointId point id
    /// @param _rate rate
    function addPayablePoint(
        uint256 _marketId,
        uint256 _pointId,
        uint256 _rate
    ) external whenNotPaused returns (bool) {
        require(rddnMarket.ownerOf(_marketId) == msg.sender);
        require(pointManager.ownerOf(_pointId) != address(0));

        _addRelatedToken(_marketId, _pointId, _rate);
        return true;
    }

    /// @dev Update point info of a given live room id
    /// @param _marketId id of the live room
    /// @param _pointId point id
    /// @param _rate rate
    /// @param _isBase whether the token is base
    function updatePayablePoint(
        uint256 _marketId,
        uint256 _pointId,
        uint256 _rate,
        bool _isBase
    ) external whenNotPaused returns (bool) {
        require(rddnMarket.ownerOf(_marketId) == msg.sender);
        require(pointManager.ownerOf(_pointId) != address(0));

        _updateRelatedToken(_marketId, _pointId, _rate, _isBase);
        return true;
    }

    /// @dev Remove a point ID from the list of a live room id
    /// @param _marketId id of the live room
    /// @param _pointId point id
    function removePayablePoint(
        uint256 _marketId,
        uint256 _pointId
    ) external whenNotPaused returns (bool) {
        require(rddnMarket.ownerOf(_marketId) == msg.sender);
        require(pointManager.ownerOf(_pointId) != address(0));

        _removeRelatedToken(_marketId, _pointId);
        return true;
    }

    /// @dev Returns point rate of the specified live room id
    /// @param _marketId id of the live room
    /// @param _pointId point id
    /// @return point rate
    function pointRateOf(uint256 _marketId, uint256 _pointId) public view returns (uint256) {
        require(rddnMarket.ownerOf(_marketId) != address(0));
        require(pointManager.ownerOf(_pointId) != address(0));

        return _rateOf(_marketId, _pointId);
    }

    /// @dev Returns whether the specified point id is payable
    /// @param _marketId id of the live room
    /// @param _pointId point id
    /// @return whether the token is available
    function isPayablePoint(uint256 _marketId, uint256 _pointId) public view returns (bool) {
        require(rddnMarket.ownerOf(_marketId) != address(0));
        require(pointManager.ownerOf(_pointId) != address(0));

        return _isRegisteredToken(_marketId, _pointId);
    }

    /// @dev Returns base point id list of the specified live room id
    /// @param _marketId id of the live room
    /// @return point id list
    function basePointOf(uint256 _marketId) public view returns (uint256) {
        require(rddnMarket.ownerOf(_marketId) != address(0));
        return _baseTokenOf(_marketId);
    }

    /// @dev Returns point id list of the specified live room id
    /// @param _marketId id of the live room
    /// @return point id list
    function payablePointsOf(uint256 _marketId) public view returns (uint256[]) {
        require(rddnMarket.ownerOf(_marketId) != address(0));
        return _tokensOfKey(_marketId);
    }

    /// @dev Calculate amount by exchange rate
    /// @param _marketId id of the live room
    /// @param _pointId id of the point
    /// @param _amout amount
    function exchangedAmountOf(
        uint256 _marketId,
        uint256 _pointId,
        uint256 _amout
    ) public view returns (uint256) {
        require(rddnMarket.ownerOf(_marketId) != address(0));
        require(pointManager.ownerOf(_pointId) != address(0));

         // calculate amount
        uint256 relativeAmount = pointManager.relativeAmountOf(_pointId, basePointOf(_marketId), _amout);
        return _exchangedAmountOf(_marketId, _pointId, relativeAmount);
    }
}