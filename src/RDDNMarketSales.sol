pragma solidity ^0.4.24;

import "./RightsDigitalAssetSpec.sol";
import "./RightsDigitalAssetObject.sol";
import "./DigitalMoneyManager.sol";
import "./DigitalPointManager.sol";
import "./RDDNMarket.sol";
import "./RDDNMarketMoney.sol";
import "./RDDNMarketPoint.sol";

import "./interfaces/IRDDNMarketSales.sol";
import "./utils/RDDNControl.sol";
import "./utils/LinkedList.sol";
import "./utils/DoubleLinkedList.sol";
import "./modules/FeeModule.sol";

import "openzeppelin-solidity/math/SafeMath.sol";

/// @title RDDNMarketMoney
/// @dev Sales controller for markets.
contract RDDNMarketSales is IRDDNMarketSales, RDDNControl, FeeModule {
    using SafeMath for uint256;

    /*** STORAGE ***/

    // Mapping from marketId to specIdList
    LinkedList private specIdList;
    // Mapping from marketId to objectIdList per spec
    DoubleLinkedList private objectIdList;

    // Mapping from object id to status whether on sale 
    mapping(uint256 => bool) private objectMarketStatus;
    // Mapping from object id to market id 
    mapping(uint256 => uint256) private objectMarketId;

    RDDNMarket private market;
    RDDNMarketMoney private marketMoney;
    RDDNMarketPoint private marketPoint;
    RightsDigitalAssetSpec private assetSpec;
    RightsDigitalAssetObject private assetObject;
    DigitalMoneyManager private moneyManager;
    DigitalPointManager private pointManager;
    

    /*** CONSTRUCTOR ***/

    constructor (
        uint8 _feeRatio,
        address _marketAddr,
        address _marketMoneyAddr,
        address _marketPointAddr,
        address _assetSpecAddr,
        address _assetObjectAddr,
        address _moneyManagerAddr,
        address _pointManagerAddr
    ) public FeeModule(_feeRatio) {
        require(_marketAddr != address(0x0));
        require(_marketMoneyAddr != address(0x0));
        require(_marketPointAddr != address(0x0));
        require(_assetSpecAddr != address(0x0));
        require(_assetObjectAddr != address(0x0));
        require(_moneyManagerAddr != address(0x0));
        require(_pointManagerAddr != address(0x0));

        assetSpec = RightsDigitalAssetSpec(_assetSpecAddr);
        assetObject = RightsDigitalAssetObject(_assetObjectAddr);
        moneyManager = DigitalMoneyManager(_moneyManagerAddr);
        pointManager = DigitalPointManager(_pointManagerAddr);
        market = RDDNMarket(_marketAddr);
        marketMoney = RDDNMarketMoney(_marketMoneyAddr);
        marketPoint = RDDNMarketPoint(_marketPointAddr);

        specIdList = new LinkedList();
        objectIdList = new DoubleLinkedList();
    }

    
    /*** External Functions ***/

    /// @dev Add objectId to market
    /// @param _marketId marketId
    /// @param _objectId objectId 
    function addObject(
        uint256 _marketId,
        uint256 _objectId
    ) public whenNotPaused returns (bool) {
        // check market owner
        require(market.ownerOf(_marketId) == msg.sender);

        // check object status whether on sale
        require(!objectMarketStatus[_objectId]);

        // check msg.sender approvals
        require(
            msg.sender == assetObject.ownerOf(_objectId)
            || assetObject.isApprovedForAll(assetObject.ownerOf(_objectId), msg.sender)
        );

        // check contract approvals
        require(
            this == assetObject.getApproved(_objectId)
            || assetObject.isApprovedForAll(assetObject.ownerOf(_objectId), this)
        );

        // approve to contract
        if (this != assetObject.getApproved(_objectId)) {
            assetObject.approve(this, _objectId);
        }

        // add object id
        uint256 specId = assetObject.specIdOf(_objectId);
        objectIdList.add(_marketId, specId, _objectId);

        // update object status
        objectMarketStatus[_objectId] = true;
        objectMarketId[_objectId] = _marketId;

        emit AddObject(msg.sender, _marketId, specId, _objectId);

        // add spec id
        if(!specIdList.exists(_marketId, specId)) {
            specIdList.add(_marketId, specId);

            emit AddSpec(msg.sender, _marketId, specId);
        }

        return true;
    }

    /// @dev Remove objectId from market
    /// @param _marketId marketId
    /// @param _objectId objectId
    function removeObject(
        uint256 _marketId,
        uint256 _objectId
    ) public whenNotPaused returns (bool) {
        require(market.ownerOf(_marketId) == msg.sender);
        require(assetObject.ownerOf(_objectId) != address(0));

        _removeObject(_marketId, _objectId);
        return true;
    }

    /// @dev Purchase object from market
    /// @param _marketId marketId
    /// @param _specId specId
    /// @param _moneyId moneyId
    /// @param _pointId pointId
    /// @param _pointValue point value
    function purchase(
        uint256 _marketId,
        uint256 _specId,
        uint256 _moneyId,
        uint256 _pointId,
        uint256 _pointValue
    ) public whenNotPaused returns (bool) {
        require(market.isValid(_marketId));
        address marketOwner = market.ownerOf(_marketId);

        // ids check
        require(marketOwner != address(0));
        require(assetSpec.ownerOf(_specId) != address(0));
        require(marketMoney.isPayableMoney(_marketId, _moneyId));
        require(marketPoint.isPayablePoint(_marketId, _pointId));

        // check amount of point
        require(pointManager.balanceOf(_pointId, msg.sender) >= _pointValue);
        // calculate amount of point to use
        uint256 adjustedPointValue = _adjustPointValue(_pointValue, _marketId, _pointId);

        // calculate amount of money to pay
        uint256 baseMoneyValue = assetSpec.referenceValueOf(_specId);
        uint256 feeMoneyValue = marketMoney.exchangedAmountOf(
            _marketId,
            _moneyId,
            feeAmount(baseMoneyValue)
        );
        uint256 afterFeeMoneyValue = marketMoney.exchangedAmountOf(
            _marketId,
            _moneyId,
            afterFeeAmount(baseMoneyValue).sub(adjustedPointValue)
        );

        // check amount of money
        require(moneyManager.balanceOf(_moneyId, msg.sender) >= feeMoneyValue + afterFeeMoneyValue);

        // get target objet id to purchase
        uint256 targetObjectId = _getRandomObjectId(_marketId, _specId);

        // remove object from market
        _removeObject(_marketId, targetObjectId);

        // transfer point from buyer to seller
        if(adjustedPointValue > 0) {
            pointManager.forceTransferFrom(
                msg.sender,
                marketOwner,
                _pointValue,
                _pointId
            );
        }

        // transfer money from buyer to owner(fee)
        moneyManager.forceTransferFrom(
            msg.sender,
            owner(),
            feeMoneyValue,
            _moneyId
        );

        // transfer money from buyer to seller(after fee)
        moneyManager.forceTransferFrom(
            msg.sender,
            marketOwner,
            afterFeeMoneyValue,
            _moneyId
        );

        // transfer digital asset from seller to buyer
        assetObject.transferFrom(
            marketOwner,
            msg.sender,
            targetObjectId
        );

        // mint point to buyer
        uint256 basePointId = marketPoint.basePointOf(_marketId);
        pointManager.mint(
            msg.sender,
            baseMoneyValue.div(100),
            basePointId
        );

        emit Purchase(msg.sender, _marketId, _specId, _moneyId, _pointId, _pointValue);
        return true;
    }

    /// @dev Get specIdList on the market
    /// @param _marketId marketId
    /// @return specIdList
    function specIdsOf(uint256 _marketId) public view returns (uint256[]) {
        require(market.ownerOf(_marketId) != address(0));

        return specIdList.valuesOf(_marketId);
    }

    /// @dev Get objectIdList on the market
    /// @param _marketId marketId
    /// @return objectIdList
    function objectIdsOf(uint256 _marketId, uint256 _specId) public view returns (uint256[]) {
        require(market.ownerOf(_marketId) != address(0));
        require(assetSpec.ownerOf(_specId) != address(0));

        return objectIdList.valuesOf(_marketId, _specId);
    }

    /// @dev Returns whether the specified object id is on sale
    /// @param _objectId objectId
    /// @return whether the specified object id is on sale
    function isOnSale(uint256 _objectId) public view returns(bool) {
        require(assetObject.ownerOf(_objectId) != address(0));

        return objectMarketStatus[_objectId];
    }
    
    /// @dev the specified market id where the object is sold
    /// @param _objectId objectId
    /// @return the specified market id
    function marketIdOf(uint256 _objectId) public view returns (uint256) {
        require(isOnSale(_objectId));
        return objectMarketId[_objectId];
    }


    /*** INTERNAL FUNCTIONS ***/

    /// @dev Remove objectId from market
    /// @param _marketId marketId
    /// @param _objectId objectId
    function _removeObject(
        uint256 _marketId,
        uint256 _objectId
    ) internal {
        // remove objectId
        uint256 specId = assetObject.specIdOf(_objectId);
        objectIdList.remove(_marketId, specId, _objectId);

        // update object status
        objectMarketStatus[_objectId] = false;

        emit RemoveObject(msg.sender, _marketId, specId, _objectId);

        // remove spec id
        if(objectIdList.totalOf(_marketId, specId) == 0) {
            specIdList.remove(_marketId, specId);
            emit RemoveSpec(msg.sender, _marketId, specId);
        }
    }

    /// @dev Calculate amount of point to pay
    /// @param _pointValue point value
    /// @param _marketId marketId
    /// @param _pointId pointId
    function _adjustPointValue(
        uint256 _pointValue,
        uint256 _marketId,
        uint256 _pointId
    ) internal view returns (uint256){
        uint256 baseMoneyId = marketMoney.baseMoneyOf(_marketId);

        uint256 moneyDecimals = uint256(moneyManager.decimalsOf(baseMoneyId));
        uint256 pointDecimals = uint256(pointManager.decimalsOf(_pointId));

        uint256 pointValue;
        if(moneyDecimals >= pointDecimals) {
            pointValue = _pointValue.mul(10 ** (moneyDecimals - pointDecimals));
        } else {
            pointValue = _pointValue.div(10 ** (pointDecimals - moneyDecimals));
        }

        return pointValue
                .mul(marketPoint.pointRateOf(_marketId, _pointId))
                .div(10 ** uint256(marketPoint.rateDecimals()));       
    }

    /// @dev Get objectId from market randomly
    /// @param _marketId marketId
    /// @param _specId specId
    function _getRandomObjectId(
        uint256 _marketId,
        uint256 _specId
    ) internal view returns (uint256) {
        uint256 randomIndex = now.mod(objectIdList.totalOf(_marketId, _specId));
        return objectIdList.valueOf(
            _marketId,
            _specId,
            randomIndex
        );
    }
}