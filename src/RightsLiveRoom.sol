pragma solidity ^0.4.24;

import './interfaces/IRightsLiveRoom.sol';
import "./modules/MasterDataModule.sol";
import "./utils/LinkedAddressList.sol";

import "openzeppelin-solidity/math/SafeMath.sol";

/// @title RightsLiveRoom
/// @dev ERC721 based master data of live rooms.
contract RightsLiveRoom is IRightsLiveRoom, MasterDataModule {

    using SafeMath for uint;

    struct LiveRoom {
        string name;
        uint256 liveRoomType;
        address holder;
        string mediaId;
        string description;
        uint256 entranceFee;
        bool isSecret;
        bool isValid;
    }


    /*** STORAGE ***/

    LiveRoom[] public liveRooms;

    // Mapping from holder to token Ids
    LinkedAddressList private hostList;


    /*** CONSTRUCTOR ***/

    constructor() public {
        hostList = new LinkedAddressList();
    }

    /*** EXTERNAL FUNCTIONS ***/

    /// @dev Crete the live room
    /// @param _name  Live room name
    /// @param _liveRoomType Live room type
    /// @param _holder live room holder address
    /// @param _mediaId media file id
    /// @param _description Live room description
    /// @param _entranceFee Live room entrance fee
    /// @param _isSecret Whether the live room is a secret
    /// @param _isValid Whether the live room is valid
    function createLiveRoom(
        string _name,
        uint256 _liveRoomType,
        address _holder,
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
        liveRoom.holder = _holder;
        liveRoom.mediaId = _mediaId;
        liveRoom.description = _description;
        liveRoom.isValid = _isValid;
        liveRoom.isSecret = _isSecret;
        liveRoom.entranceFee = _entranceFee;

        // set ids
        uint256 liveRoomId = liveRooms.push(liveRoom).sub(1);
        _mint(msg.sender, liveRoomId);

        emit CreateLiveRoom(msg.sender, liveRoomId);
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

        emit UpdateLiveRoom(msg.sender, _liveRoomId);
    }

    /// @dev Approves another address to be host of the live room
    /// @param _to address to be approved for the given live room ID
    /// @param _liveRoomId id of the live room
    function addHost(
        address _to,
        uint256 _liveRoomId
    ) public whenNotPaused {
        require(ownerOf(_liveRoomId) == msg.sender);
        hostList.add(_liveRoomId, _to);
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
        hostList.remove(_liveRoomId, _to);
        emit RemoveHost(msg.sender, _to, _liveRoomId);
    }

    /// @dev Gets the live room info of the specified live room ID
    /// @param _liveRoomId id of the live room
    /// @return live room info
    function getLiveRoom(uint256 _liveRoomId) public view returns (
        uint256 liveRoomId,
        string name,
        uint256 liveRoomType,
        address holder,
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
            liveRoom.holder,
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
        address holder,
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
        return hostList.exists(_liveRoomId, _host);
    }

    /// @dev Gets the host list of live room
    /// @param _liveRoomId id of the live room
    /// @return host address list
    function getHosts(uint256 _liveRoomId) public view returns (address[]) {
        require(_exists(_liveRoomId));
        return hostList.valuesOf(_liveRoomId);
    }

    /// @dev Returns live room type of the specified live room id
    /// @param _liveRoomId id of the live room
    /// @return live room type of the specified live room id
    function liveRoomTypeOf(uint256 _liveRoomId) public view returns (uint256) {
        require(_exists(_liveRoomId));
        return liveRooms[_liveRoomId].liveRoomType;
    }

    /// @dev Returns live room holder of the specified live room id
    /// @param _liveRoomId live room id
    /// @return live room holder address of the specified live room id
    function holderOf(uint256 _liveRoomId) public view returns (address) {
        require(_exists(_liveRoomId));
        return liveRooms[_liveRoomId].holder;
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
