pragma solidity ^0.4.24;

import "./DigitalMoneyManager.sol";
import "./RightsLiveRoom.sol";
import "./RightsLiveRoomMoney.sol";

import './interfaces/IRightsLive.sol';
import "./modules/MasterDataModule.sol";
import "./modules/FeeModule.sol";

import "openzeppelin-solidity/math/SafeMath.sol";

/// @title RightsLive
/// @dev ERC721 based master data of lives.
contract RightsLive is IRightsLive, MasterDataModule, FeeModule {
    
    using SafeMath for uint;

    struct Live {
        uint256 liveRoomId;
        uint256 videoType;
        string videoKey;
        uint64 startAt;
        uint64 endAt;
    }


    /*** STORAGE ***/

    Live[] private lives;
    RightsLiveRoom private liveRoom;
    RightsLiveRoomMoney private liveRoomMoney;
    DigitalMoneyManager private moneyManager;

    // Mapping from live room ID to next live ids
    mapping(uint256 => uint256[]) private nextLiveIds;
    // Mapping from live room ID to index of the next live list
    mapping (uint256 => mapping (uint256 => uint256)) private nextLiveIndex;
    // Mapping from live id to owner
    mapping (uint256 => address) private nextLiveOwner;
    // Mapping from live room ID to Live end time
    mapping (uint256 => uint256) private lastLiveEndAt;

    // Mapping from artist address to total payment amount of user
    mapping (address => mapping (address => uint256)) private userPaymentAmount;
    // Mapping from live room ID to user approval expire date
    mapping (uint256 => mapping (address => uint64)) private approvalExpireAt;


    /*** CONSTRUCTOR ***/

    constructor(
        uint8 _feeRatio,
        address _liveRoomAddr,
        address _liveRoomMoneyAddr,
        address _digitalMoneyManagerAddr
    ) public FeeModule(_feeRatio) {
        require(_liveRoomAddr != address(0));
        require(_digitalMoneyManagerAddr != address(0));

        liveRoom = RightsLiveRoom(_liveRoomAddr);
        liveRoomMoney = RightsLiveRoomMoney(_liveRoomMoneyAddr);
        moneyManager = DigitalMoneyManager(_digitalMoneyManagerAddr);
    }


    /*** EXTERNAL FUNCTIONS ***/

    /// @dev Create new live and add id to the live room
    /// @param _liveRoomId id of the live room
    /// @param _videoType video type
    /// @param _videoKey video key
    /// @param _liveStartAt live start time
    /// @param _liveEndAt live end time
    function createLive(
        uint256 _liveRoomId,
        uint256 _videoType,
        string _videoKey,
        uint64 _liveStartAt,
        uint64 _liveEndAt
    ) external whenNotPaused {
        require(liveRoom.ownerOf(_liveRoomId) == msg.sender);
        require(_liveStartAt < _liveEndAt);
        require(lastLiveEndAt[_liveRoomId] < _liveStartAt);

        Live memory live;
        live.liveRoomId = _liveRoomId;
        live.videoType = _videoType;
        live.videoKey = _videoKey;
        live.startAt = _liveStartAt;
        live.endAt = _liveEndAt;

        uint256 liveId = lives.push(live).sub(1);
        _mint(msg.sender, liveId);

        emit CreateLive(msg.sender, liveId);

        nextLiveIndex[_liveRoomId][liveId] = nextLiveIds[_liveRoomId].push(liveId).sub(1);
        nextLiveOwner[liveId] = msg.sender;
        lastLiveEndAt[_liveRoomId] = _liveEndAt;

        emit AddLiveId(msg.sender, _liveRoomId, liveId);
    }

    /// @dev Update live
    /// @param _liveId id of the live
    /// @param _videoType video type
    /// @param _videoKey video key
    /// @param _liveStartAt live start time
    /// @param _liveEndAt live end time
    function updateLive(
        uint256 _liveId,
        uint256 _videoType,
        string _videoKey,
        uint64 _liveStartAt,
        uint64 _liveEndAt
    ) external whenNotPaused {
        require(ownerOf(_liveId) == msg.sender);
        require(_liveStartAt < _liveEndAt);

        Live storage live = lives[_liveId];
        live.videoType = _videoType;
        live.videoKey = _videoKey;
        live.startAt = _liveStartAt;
        live.endAt = _liveEndAt;

        emit UpdateLive(msg.sender, _liveId);
    }

    /// @dev Remove live from the live room
    /// @param _liveRoomId id of the live room
    /// @param _liveId id of the live
    function removeLiveId(uint256 _liveRoomId, uint256 _liveId) public whenNotPaused {
        require(ownerOf(_liveId) == msg.sender);
        require(liveRoom.ownerOf(_liveRoomId) == msg.sender);

        _removeLiveId(_liveRoomId, _liveId);
        emit RemoveLiveId(msg.sender, _liveRoomId, _liveId);
    }

    /// @dev Start the live
    /// @param _liveRoomId id of the live room
    function startLive(uint256 _liveRoomId) external whenNotPaused {
        require(
            liveRoom.ownerOf(_liveRoomId) == msg.sender
            || liveRoom.isHost(_liveRoomId, msg.sender)
        );
        require(nextLiveIds[_liveRoomId].length > 0);

        // check if current live is finished or will be finished within 15 minutes
        uint256 targetLiveId = nextLiveIds[_liveRoomId][0];

        if (lives[targetLiveId].endAt - 900 <= now) {
            // remove old live from nextLives
            _removeLiveId(_liveRoomId, targetLiveId);
            emit RemoveLiveId(msg.sender, _liveRoomId, targetLiveId);
        }

        emit StartLive(msg.sender, _liveRoomId);
    }

    /// @dev Pay entrance fee for the live
    /// @param _liveRoomId id of the live room
    /// @param _moneyId id of the money
    function payEntranceFee(uint256 _liveRoomId, uint256 _moneyId) external whenNotPaused {
        require(moneyManager.ownerOf(_moneyId) != address(0));
        require(liveRoomMoney.isPayableMoney(_liveRoomId, _moneyId));
        require(liveRoom.isValid(_liveRoomId));
        require(isOnAirLive(_liveRoomId));

        uint256 liveId =  nextLiveIds[_liveRoomId][0];
        Live memory live = lives[liveId];
        uint64 liveEndAt = live.endAt;

        uint256 entranceFee = liveRoom.entranceFeeOf(_liveRoomId);

        // check if entrance fee is not payed
        require(approvalExpireAt[_liveRoomId][msg.sender] < liveEndAt);

        if (entranceFee > 0) {
            // calculate entranceFee by exchange rate
            entranceFee = liveRoomMoney.exchangedAmountOf(_liveRoomId, _moneyId, entranceFee);

            // transfer money from user to contract owner 
            moneyManager.forceTransferFrom(msg.sender, owner(), feeAmount(entranceFee), _moneyId);

            // transfer money from user to live room owner
            moneyManager.forceTransferFrom(msg.sender, liveRoom.ownerOf(_liveRoomId), afterFeeAmount(entranceFee), _moneyId);
        }

        // set approval expire time to join live
        approvalExpireAt[_liveRoomId][msg.sender] = liveEndAt;

        // add total payment amont by user
        userPaymentAmount[liveRoom.ownerOf(_liveRoomId)][msg.sender] += entranceFee;

        emit PayEntranceFee(msg.sender, _liveRoomId, _moneyId, entranceFee);
        emit EnterLiveRoom(msg.sender, _liveRoomId, liveEndAt);
    }

    /// @dev Tip the money for the live
    /// @param _liveRoomId id of the live room
    /// @param _moneyId id of the money
    /// @param _tipType Tig type
    /// @param _amount Tipping amount
    function tipOnLive(
        uint256 _liveRoomId,
        uint256 _moneyId,
        uint256 _tipType,
        uint256 _amount
    ) external whenNotPaused {
        require(liveRoomMoney.isPayableMoney(_liveRoomId, _moneyId));
        require(liveRoom.isValid(_liveRoomId));
        require(isOnAirLive(_liveRoomId));

        // check if entrance fee is payed
        require(approvalExpireAt[_liveRoomId][msg.sender] >= now);

        if (_amount > 0) {
            // transfer money from user to contract owner 
            moneyManager.forceTransferFrom(msg.sender, owner(), feeAmount(_amount), _moneyId);

            // transfer money from user to live room owner
            moneyManager.forceTransferFrom(msg.sender, liveRoom.ownerOf(_liveRoomId), afterFeeAmount(_amount), _moneyId);

            // add total payment amont by user
            userPaymentAmount[liveRoom.ownerOf(_liveRoomId)][msg.sender] += _amount;
        }

        emit TipOnLive(msg.sender, _liveRoomId, _moneyId, _tipType, _amount);
    }

    /// @dev Gets the live room info related live time
    /// @param _liveRoomId id of the live room
    /// @return whether the live is on air
    function isOnAirLive(
        uint256 _liveRoomId
    ) public view returns (bool) {
        require(liveRoom.ownerOf(_liveRoomId) != address(0));
        require(nextLiveIds[_liveRoomId].length > 0);

        if (nextLiveIds[_liveRoomId].length > 0) {
            uint256 liveId =  nextLiveIds[_liveRoomId][0];
            Live memory live = lives[liveId];

            return (
                live.startAt <= now &&
                live.endAt >= now
            );
        } else {
            return false;
        }
    }

    /// @dev Gets the next live of live room
    /// @param _liveId id of live.
    /// @return _liveId live id.
    /// @return liveRoomId live room id of live.
    /// @return videoType video type of live.
    /// @return videoKey video key of live.
    /// @return startAt start time of live.
    /// @return endAt start time of live.
    function getLive(
        uint256 _liveId
    ) external view returns (
        uint256 liveId,
        uint256 liveRoomId,
        uint256 videoType,
        string videoKey,
        uint64 startAt,
        uint64 endAt
    ) {
        require(_exists(_liveId));

        Live memory live = lives[_liveId];
        return (
            _liveId,
            live.liveRoomId,
            live.videoType,
            live.videoKey,
            live.startAt,
            live.endAt
        );
    }

    /// @dev Gets the next live ids
    /// @param _liveRoomId id of the live room
    /// @return live ids.
    function getNextLives(uint256 _liveRoomId) external view returns (uint256[]) {
        require(liveRoom.ownerOf(_liveRoomId) != address(0));

        return nextLiveIds[_liveRoomId];
    }

    /// @dev Gets the payment amount by the user
    /// @param _owner artist address
    /// @param _user user address
    /// @return total payment amount of user
    function getUserPaymentAmount(address _owner, address _user) public view returns (uint256) {
        return userPaymentAmount[_owner][_user];
    }

    /// @dev Gets the approval expire date
    /// @param _liveRoomId id of the live room
    /// @param _user user address
    /// @return live count.
    function getApprovalExpireAt(uint256 _liveRoomId, address _user) external view returns (uint256) {
        return approvalExpireAt[_liveRoomId][_user];
    }

    /// @dev Returns live room id of the specified video id
    /// @param _liveId id of the live
    /// @return live room id of the specified video id
    function liveRoomIdOf(uint256 _liveId) public view returns (uint256) {
        require(_exists(_liveId));
        return lives[_liveId].liveRoomId;
    }

    /// @dev Returns video type of the specified video id
    /// @param _liveId id of the live
    /// @return video type of the specified video id
    function videoTypeOf(uint256 _liveId) public view returns (uint256) {
        require(_exists(_liveId));
        return lives[_liveId].videoType;
    }

    /// @dev Returns video key of the specified video id
    /// @param _liveId id of the live
    /// @return video key of the specified video id
    function videoKeyOf(uint256 _liveId) public view returns (string) {
        require(_exists(_liveId));
        return lives[_liveId].videoKey;
    }

    /// @dev Returns start at of the specified video id
    /// @param _liveId id of the live
    /// @return start at of the specified video id
    function startAtOf(uint256 _liveId) public view returns (uint64) {
        require(_exists(_liveId));
        return lives[_liveId].startAt;
    }

    /// @dev Returns end at of the specified video id
    /// @param _liveId id of the live
    /// @return end at of the specified video id
    function endAtOf(uint256 _liveId) public view returns (uint64) {
        require(_exists(_liveId));
        return lives[_liveId].endAt;
    }


    /*** INTERNAL FUNCTIONS ***/

    /// @dev Remove live from the live room
    /// @param _liveRoomId id of the live room
    /// @param _liveId id of the live
    function _removeLiveId(uint256 _liveRoomId, uint256 _liveId) internal {
        uint256 liveIndex = nextLiveIndex[_liveRoomId][_liveId];

        for (uint num = liveIndex; num < nextLiveIds[_liveRoomId].length - 1; num++) {
            nextLiveIds[_liveRoomId][num] = nextLiveIds[_liveRoomId][num + 1];
            nextLiveIndex[_liveRoomId][nextLiveIds[_liveRoomId][num]] = num;
        }

        nextLiveIds[_liveRoomId].length--;
        nextLiveIndex[_liveRoomId][_liveId] = 0;
    }
}