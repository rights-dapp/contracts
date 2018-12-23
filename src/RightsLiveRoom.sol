pragma solidity ^0.4.24;

import "./DigitalMoneyManager.sol";

import './interfaces/IRightsLiveRoom.sol';
import "./modules/MasterDataModule.sol";
import "./modules/MultiTokenModule.sol";

import "openzeppelin-solidity/math/SafeMath.sol";

/// @title RightsLiveRoom
/// @dev ERC721 based master data of live rooms.
contract RightsLiveRoom is IRightsLiveRoom, MasterDataModule, MultiTokenModule {

    using SafeMath for uint;

    struct LiveRoom {
        string name;
        uint256 liveRoomType;
        string mediaId;
        string description;
        uint256 entranceFee;
        bool isSecret;
        bool isValid;
    }


    /*** STORAGE ***/

    LiveRoom[] public liveRooms;

    // Mapping address to approvals of the live room
    mapping (uint256 => mapping (address => bool)) private liveRoomHostApprovals;
    // Mapping from live room ID to approved addresses
    mapping (uint256 => address[]) private liveRoomHosts;
    // Mapping from live room ID to index of the hosts list
    mapping (uint256 => mapping (address => uint256)) private liveRoomHostsIndex;

    DigitalMoneyManager moneyManager;

    /*** CONSTRUCTOR ***/

    constructor(address _digitalMoneyManagerAddr) public {
        require(_digitalMoneyManagerAddr != address(0));
        moneyManager = DigitalMoneyManager(_digitalMoneyManagerAddr);
    }


    /*** EXTERNAL FUNCTIONS ***/

    /// @dev Crete the live room
    /// @param _name  Live room name
    /// @param _liveRoomType Live room type
    /// @param _mediaId media file id
    /// @param _description Live room description
    /// @param _entranceFee Live room entrance fee
    /// @param _isSecret Whether the live room is a secret
    /// @param _isValid Whether the live room is valid
    function createLiveRoom(
        string _name,
        uint256 _liveRoomType,
        string _mediaId,
        string _description,
        uint256 _entranceFee,
        bool _isSecret,
        bool _isValid
    ) external whenNotPaused {
        // add to liveRooms
        LiveRoom memory liveRoom;
        liveRoom.name = _name;
        liveRoom.liveRoomType = _liveRoomType;
        liveRoom.mediaId = _mediaId;
        liveRoom.description = _description;
        liveRoom.isValid = true;
        liveRoom.isSecret = _isSecret;
        liveRoom.entranceFee = _entranceFee;

        // set ids
        uint256 liveRoomId = liveRooms.push(liveRoom).sub(1);
        _mint(msg.sender, liveRoomId);

        emit CreateLiveRoom(
            msg.sender,
            liveRoomId,
            _name,
            _liveRoomType,
            _mediaId,
            _description,
            _entranceFee,
            _isSecret,
            _isValid
        );
    }

    /// @dev Updates the live room of the specified live room ID
    /// @param _liveRoomId id of the live room
    /// @param _name The naf the live vroom
    /// @param _liveRoomType Live room type
    /// @param _mediaId Thscription of the live room
    /// @param _description The description of the live room
    /// @param _entranceFee The entrance fee of the live room
    /// @param _isSecret Whether the live room is a secret
    /// @param _isValid Whether the live room is valid
    function updateLiveRoom(
        uint256 _liveRoomId,
        string _name,
        uint256 _liveRoomType,
        string _mediaId,
        string _description,
        uint256 _entranceFee,
        bool _isSecret,
        bool _isValid
    ) external whenNotPaused {
        require(ownerOf(_liveRoomId) == msg.sender);

        LiveRoom storage liveRoom = liveRooms[_liveRoomId];
        liveRoom.name = _name;
        liveRoom.liveRoomType = _liveRoomType;
        liveRoom.mediaId = _mediaId;
        liveRoom.description = _description;
        liveRoom.isSecret = _isSecret;
        liveRoom.entranceFee = _entranceFee;
        liveRoom.isValid = _isValid;

        emit UpdateLiveRoom(
            msg.sender,
            _liveRoomId,
            _name,
            _liveRoomType,
            _mediaId,
            _description,
            _entranceFee,
            _isSecret,
            _isValid
        );
    }

    /// @dev Approves another address to be host of the live room
    /// @param _to address to be approved for the given live room ID
    /// @param _liveRoomId id of the live room
    function addHost(
        address _to,
        uint256 _liveRoomId
    ) public whenNotPaused {
        require(ownerOf(_liveRoomId) == msg.sender);

        liveRoomHostApprovals[_liveRoomId][_to] = true;
        liveRoomHostsIndex[_liveRoomId][_to] = liveRoomHosts[_liveRoomId].push(_to).sub(1);
        emit AddHost(msg.sender, _to, _liveRoomId);
    }

    /// @dev Remove current approval to be host of the given live room ID
    /// @param _to address to be approved for the given live room ID
    /// @param _liveRoomId id of the live room
    function removeHost(
        address _to,
        uint256 _liveRoomId
    ) external whenNotPaused {
        require(ownerOf(_liveRoomId) == msg.sender);

        liveRoomHostApprovals[_liveRoomId][_to] = false;

        uint256 hostIndex = liveRoomHostsIndex[_liveRoomId][_to];
        uint256 lastHostIndex = liveRoomHosts[_liveRoomId].length.sub(1);
        address lastHost = liveRoomHosts[_liveRoomId][lastHostIndex];

        liveRoomHosts[_liveRoomId][hostIndex] = lastHost;
        liveRoomHosts[_liveRoomId].length--;

        emit RemoveHost(msg.sender, _to, _liveRoomId);
    }

    /// @dev Aadd a money id to the list of a given live room id
    /// @param _liveRoomId id of the live room
    /// @param _moneyId money id
    /// @param _rate rate
    function addPayableMoney(
        uint256 _liveRoomId,
        uint256 _moneyId,
        uint256 _rate
    ) external whenNotPaused {
        require(ownerOf(_liveRoomId) == msg.sender);
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
        require(ownerOf(_liveRoomId) == msg.sender);
        require(moneyManager.ownerOf(_moneyId) != address(0));

        _updateRelatedToken(_liveRoomId, _moneyId, _rate, _isBase);
    }

    /// @dev Remove a money ID from the list of a live room id
    /// @param _liveRoomId id of the live room
    /// @param _moneyId money id
    function removePayableMoney(uint256 _liveRoomId, uint256 _moneyId) external whenNotPaused {
        require(ownerOf(_liveRoomId) == msg.sender);
        require(moneyManager.ownerOf(_moneyId) != address(0));

        _removeRelatedToken(_liveRoomId, _moneyId);
    }

    /// @dev Gets the live room info of the specified live room ID
    /// @param _liveRoomId id of the live room
    /// @return live room info
    function getLiveRoom(uint256 _liveRoomId) public view returns (
        uint256 liveRoomId,
        string name,
        uint256 liveRoomType,
        string mediaId,
        string description,
        bool isValid,
        bool isSecret,
        uint256 entranceFee,
        address owner
    ) {
        require(_exists(_liveRoomId));

        address liveRoomOwner = ownerOf(_liveRoomId);

        LiveRoom memory liveRoom = liveRooms[_liveRoomId];
        return (
            _liveRoomId,
            liveRoom.name,
            liveRoom.liveRoomType,
            liveRoom.mediaId,
            liveRoom.description,
            liveRoom.isValid,
            liveRoom.isSecret,
            liveRoom.entranceFee,
            liveRoomOwner
        );
    }

    /// @dev Gets the live room info of the specified live room ID
    /// @param _owner address owning the tokens list to be accessed
    /// @param _index uint256 representing the index to be accessed of the requested tokens list
    /// @return live room info
    function getLiveRoom(address _owner, uint256 _index) public view returns (
        uint256 liveRoomId,
        string name,
        uint256 liveRoomType,
        string mediaId,
        string description,
        bool isValid,
        bool isSecret,
        uint256 entranceFee,
        address owner
    ) {
        uint256 targetId = tokenOfOwnerByIndex(_owner, _index);
        return getLiveRoom(targetId);
    }

    /// @dev Gets the host address for a live room ID
    /// @param _liveRoomId id of the live room
    /// @param _host host address
    /// @return currently oved address for the given live ID
    function isHost(uint256 _liveRoomId, address _host) public view returns (bool) {
        require(_exists(_liveRoomId));
        return liveRoomHostApprovals[_liveRoomId][_host];
    }

    /// @dev Gets the host list of live room
    /// @param _liveRoomId id of the live room
    /// @return host address list
    function getHosts(uint256 _liveRoomId) public view returns (address[]) {
        require(_exists(_liveRoomId));
        return liveRoomHosts[_liveRoomId];
    }

    /// @dev Returns money rate of the specified live room id
    /// @param _liveRoomId id of the live room
    /// @param _moneyId money id
    /// @return whether the token is available
    function moneyRateOf(uint256 _liveRoomId, uint256 _moneyId) public view returns (uint256) {
        require(_exists(_liveRoomId));
        require(moneyManager.ownerOf(_moneyId) != address(0));

        return _rateOf(_liveRoomId, _moneyId);
    }

    /// @dev Returns whether the specified money id is payable
    /// @param _liveRoomId id of the live room
    /// @param _moneyId money id
    /// @return whether the token is available
    function isPayableMoney(uint256 _liveRoomId, uint256 _moneyId) public view returns (bool) {
        require(_exists(_liveRoomId));
        require(moneyManager.ownerOf(_moneyId) != address(0));

        return _isRegisteredToken(_liveRoomId, _moneyId);
    }

    /// @dev Returns base money id list of the specified live room id
    /// @param _liveRoomId id of the live room
    /// @return money id list
    function baseMoneyOf(uint256 _liveRoomId) public view returns (uint256) {
        require(_exists(_liveRoomId));
        return _baseTokenOf(_liveRoomId);
    }

    /// @dev Returns money id list of the specified live room id
    /// @param _liveRoomId id of the live room
    /// @return money id list
    function payableMoneysOf(uint256 _liveRoomId) public view returns (uint256[]) {
        require(_exists(_liveRoomId));
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
        require(_exists(_liveRoomId));
        require(moneyManager.ownerOf(_moneyId) != address(0));

         // calculate amount
        uint256 relativeAmount = moneyManager.relativeAmountOf(_moneyId, baseMoneyOf(_liveRoomId), _amout);
        return _exchangedAmountOf(_liveRoomId, _moneyId, relativeAmount);
    }

    /// @dev Returns live room type of the specified live room id
    /// @param _liveRoomId id of the live room
    /// @return live room type of the specified live room id
    function liveRoomTypeOf(uint256 _liveRoomId) public view returns (uint256) {
        require(_exists(_liveRoomId));
        return liveRooms[_liveRoomId].liveRoomType;
    }

    /// @dev Returns whether the live room is valid
    /// @param _liveRoomId id of the live room
    /// @return whether the live room is valid
    function isValid(uint256 _liveRoomId) public view returns (bool) {
        require(_exists(_liveRoomId));
        return liveRooms[_liveRoomId].isValid;
    }

    /// @dev Returns whether the live room is secret
    /// @param _liveRoomId id of the live room
    /// @return whether the live room is secret
    function isSecret(uint256 _liveRoomId) public view returns (bool) {
        require(_exists(_liveRoomId));
        return liveRooms[_liveRoomId].isSecret;
    }

    /// @dev Returns entranceFee of the specified live room id
    /// @param _liveRoomId id of the live room
    function entranceFeeOf(uint256 _liveRoomId) public view returns (uint256) {
        require(_exists(_liveRoomId));
        return liveRooms[_liveRoomId].entranceFee;
    }
}
