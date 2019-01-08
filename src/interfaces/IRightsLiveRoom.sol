pragma solidity ^0.4.24;

/// @title RightsLive interface
/// @dev Interface for RightsLive
contract IRightsLiveRoom {

    event CreateLiveRoom(
        address owner,
        uint256 liveRoomId
    );

    event UpdateLiveRoom(
        address owner,
        uint256 liveRoomId
    );

    event AddHost(
        address owner,
        address approved,
        uint256 liveRoomId
    );

    event RemoveHost(
        address owner,
        address approved,
        uint256 liveRoomId
    );


    function createLiveRoom(
        string _name,
        uint256 _liveRoomType,
        address _holder,
        string _mediaId,
        string _description,
        uint256 _entranceFee,
        bool _isSecret,
        bool _isValid
    ) external;

    function updateLiveRoom(
        uint256 _liveRoomId,
        string _name,
        uint256 _liveRoomType,
        string _mediaId,
        string _description,
        uint256 _entranceFee,
        bool _isSecret,
        bool _isValid
    ) external;

    function addHost(address _to, uint256 _liveRoomId) public;
    function removeHost(address _from, uint256 _liveRoomId) external;

    function getLiveRoom(
        uint256 _liveRoomId
    ) public view returns (
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
    );

    function getLiveRoom(
        address _owner,
        uint256 _index
    ) public view returns (
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
    );

    function isHost(uint256 _liveRoomId, address _host) public view returns (bool);
    function getHosts(uint256 _liveRoomId) public view returns (address[]);

    function liveRoomTypeOf(uint256 _liveRoomId) public view returns (uint256);
    function holderOf(uint256 _liveRoomId) public view returns (address);
    function isValid(uint256 _liveRoomId) public view returns (bool);
    function isSecret(uint256 _liveRoomId) public view returns (bool);
    function entranceFeeOf(uint256 _liveRoomId) public view returns (uint256);
}