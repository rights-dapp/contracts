pragma solidity ^0.4.24;

import "./DigitalMoneyManager.sol";
import "./RightsLiveRoom.sol";

import "./utils/RDDNControl.sol";
import "./modules/MultiTokenModule.sol";

/// @title RightsLiveRoomMoney
/// @dev Money controller for live rooms.
contract RightsLiveRoomMoney is RDDNControl, MultiTokenModule {

    /*** STORAGE ***/

    RightsLiveRoom public liveRoom;
    DigitalMoneyManager moneyManager;

    /*** CONSTRUCTOR ***/

    constructor(
      address _liveRoomAddr,
      address _digitalMoneyManagerAddr
    ) public {
        require(_liveRoomAddr != address(0));
        require(_digitalMoneyManagerAddr != address(0));
        liveRoom = RightsLiveRoom(_liveRoomAddr);
        moneyManager = DigitalMoneyManager(_digitalMoneyManagerAddr);
    }


    /*** EXTERNAL FUNCTIONS ***/

    /// @dev Aadd a money id to the list of a given live room id
    /// @param _liveRoomId id of the live room
    /// @param _moneyId money id
    /// @param _rate rate
    function addPayableMoney(
        uint256 _liveRoomId,
        uint256 _moneyId,
        uint256 _rate
    ) external whenNotPaused {
        require(liveRoom.ownerOf(_liveRoomId) == msg.sender);
        require(moneyManager.ownerOf(_moneyId) != address(0));

        _addRelatedToken(_liveRoomId, _moneyId, _rate);
    }

    /// @dev Update money info of a given live room id
    /// @param _liveRoomId id of the live room
    /// @param _moneyId money id
    /// @param _rate rate
    /// @param _isBase whether the token is base
    function updatePayableMoney(
        uint256 _liveRoomId,
        uint256 _moneyId,
        uint256 _rate,
        bool _isBase
    ) external whenNotPaused {
        require(liveRoom.ownerOf(_liveRoomId) == msg.sender);
        require(moneyManager.ownerOf(_moneyId) != address(0));

        _updateRelatedToken(_liveRoomId, _moneyId, _rate, _isBase);
    }

    /// @dev Remove a money ID from the list of a live room id
    /// @param _liveRoomId id of the live room
    /// @param _moneyId money id
    function removePayableMoney(uint256 _liveRoomId, uint256 _moneyId) external whenNotPaused {
        require(liveRoom.ownerOf(_liveRoomId) == msg.sender);
        require(moneyManager.ownerOf(_moneyId) != address(0));

        _removeRelatedToken(_liveRoomId, _moneyId);
    }


    /// @dev Returns money rate of the specified live room id
    /// @param _liveRoomId id of the live room
    /// @param _moneyId money id
    /// @return whether the token is available
    function moneyRateOf(uint256 _liveRoomId, uint256 _moneyId) public view returns (uint256) {
        require(liveRoom.ownerOf(_liveRoomId) != address(0));
        require(moneyManager.ownerOf(_moneyId) != address(0));

        return _rateOf(_liveRoomId, _moneyId);
    }

    /// @dev Returns whether the specified money id is payable
    /// @param _liveRoomId id of the live room
    /// @param _moneyId money id
    /// @return whether the token is available
    function isPayableMoney(uint256 _liveRoomId, uint256 _moneyId) public view returns (bool) {
        require(liveRoom.ownerOf(_liveRoomId) != address(0));
        require(moneyManager.ownerOf(_moneyId) != address(0));

        return _isRegisteredToken(_liveRoomId, _moneyId);
    }

    /// @dev Returns base money id list of the specified live room id
    /// @param _liveRoomId id of the live room
    /// @return money id list
    function baseMoneyOf(uint256 _liveRoomId) public view returns (uint256) {
        require(liveRoom.ownerOf(_liveRoomId) != address(0));
        return _baseTokenOf(_liveRoomId);
    }

    /// @dev Returns money id list of the specified live room id
    /// @param _liveRoomId id of the live room
    /// @return money id list
    function payableMoneysOf(uint256 _liveRoomId) public view returns (uint256[]) {
        require(liveRoom.ownerOf(_liveRoomId) != address(0));
        return _tokensOfKey(_liveRoomId);
    }

    /// @dev Calculate amount by exchange rate
    /// @param _liveRoomId id of the live room
    /// @param _moneyId id of the money
    /// @param _amout amount
    function exchangedAmountOf(
        uint256 _liveRoomId,
        uint256 _moneyId,
        uint256 _amout
    ) public view returns (uint256) {
        require(liveRoom.ownerOf(_liveRoomId) != address(0));
        require(moneyManager.ownerOf(_moneyId) != address(0));

         // calculate amount
        uint256 relativeAmount = moneyManager.relativeAmountOf(_moneyId, baseMoneyOf(_liveRoomId), _amout);
        return _exchangedAmountOf(_liveRoomId, _moneyId, relativeAmount);
    }
}
