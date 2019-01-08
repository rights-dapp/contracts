pragma solidity ^0.4.24;

/// @title RightsLive interface
/// @dev Interface for RightsLive
contract IRightsLive {

    event CreateLive(
        address owner,
        uint256 liveId
    );

    event UpdateLive(
        address owner,
        uint256 liveId
    );

    event AddLiveId(
        address owner,
        uint256 liveRoomId,
        uint256 liveId
    );

    event RemoveLiveId(
        address owner,
        uint256 liveRoomId,
        uint256 liveId
    );

    event StartLive(
        address owner,
        uint256 liveRoomId
    );

    event PayEntranceFee(
        address from,
        uint256 liveRoomId,
        uint256 moneyId,
        uint256 entranceFee
    );

    event EnterLiveRoom(
        address from,
        uint256 liveRoomId,
        uint64 liveEndAt
    );

    event TipOnLive(
        address from,
        uint256 liveRoomId,
        uint256 moneyId,
        uint256 tipType,
        uint256 amount
    );


    function createLive(
        uint256 _liveRoomId,
        uint256 _videoType,
        string _videoKey,
        uint64 _liveStartAt,
        uint64 _liveEndAt
    ) external;

    function updateLive(
        uint256 _liveId,
        uint256 _videoType,
        string _videoKey,
        uint64 _liveStartAt,
        uint64 _liveEndAt
    ) external;

    function removeLiveId(uint256 _liveRoomId, uint256 _liveId) public;

    function startLive(uint256 _liveRoomId) external;

    function getLive(
        uint256 _liveId
    ) external view returns (
        uint256 liveId,
        uint256 liveRoomId,
        uint256 videoType,
        string videoKey,
        uint64 startAt,
        uint64 endAt
    );

    function getNextLives(uint256 _liveRoomId) external view returns (uint256[]);

    function liveRoomIdOf(uint256 _liveId) public view returns (uint256);
    function videoKeyOf(uint256 _liveId) public view returns (string);
    function startAtOf(uint256 _liveId) public view returns (uint64);
    function endAtOf(uint256 _liveId) public view returns (uint64);
}