pragma solidity ^0.4.24;

import "./DigitalMoneyManager.sol";

import "./interfaces/IILPController.sol";
import "./utils/RDDNControl.sol";

import "openzeppelin-solidity/math/SafeMath.sol";

/// @title ILPController
/// @dev Controller for ILP modules.
contract ILPController is RDDNControl, IILPController {

    using SafeMath for uint;


    /*** DATA TYPES ***/

    struct ILPTransfer {
        address sender;
        address receiver;
        uint256 amount;
        bytes32 condition;
        uint expiry;
        State state;
        Direction direction;
    }


    /*** STORAGE ***/

    // Mapping from uuid to ILP transfer
    mapping (bytes16 => ILPTransfer) private transfers;

    // Mapping from uuid to moneyId
    mapping (bytes16 => uint256) private moneyIds;

    // Mapping from uuid to ILP packet
    mapping (bytes16 => bytes) private ilpPackets;

    // Mapping from address to uuid
    mapping (address => bytes16[]) private requests;

    /// @dev Requested new address to change owner address.
    address public ilpOwner;

    DigitalMoneyManager digitalMoneyManager;


    /*** MODIFIER ***/

    /// @dev Access modifier for owner functionality
    modifier onlyIlpOwner {
        require(msg.sender == ilpOwner);
        _;
    }


    /*** CONSTRUCTOR ***/

    constructor(address _digitalMoneyManagerAddr) public {
        require(_digitalMoneyManagerAddr != address(0));
        digitalMoneyManager = DigitalMoneyManager(_digitalMoneyManagerAddr);
    }


    /*** EXTERNAL FUNCTIONS ***/

    /// @dev Transfers control of the ilp to a newOwner.
    /// @param _newIlpOwner The address to transfer ownership to.
    function setIlpOwner(address _newIlpOwner) external onlyOwner {
        require(_newIlpOwner != address(0));
        ilpOwner = _newIlpOwner;
    }

    /// @dev accept deposit/withdraw requests
    /// @param _moneyId moneyId
    /// @param _amount The amount of money
    /// @param _condition Cryptographic hold condition
    /// @param _uuid UUID used as an external identifier
    /// @param _expiry Expiry time of the cryptographic hold
    /// @param _data Base64-encoded ILP packet
    /// @param _direction 0:Deposit, 1:Withdraw
    /// @return Whether the transaction was successful or not (0: Successful)
    function createTransfer (
        uint256 _moneyId,
        uint _amount,
        bytes32 _condition,
        bytes16 _uuid,
        uint _expiry,
        bytes _data,
        Direction _direction
    ) external whenNotPaused returns (int8) {
        require(digitalMoneyManager.ownerOf(_moneyId) != address(0));
        require(_direction == Direction.Deposit || _direction == Direction.Withdraw);
        require(transfers[_uuid].sender == address(0) && _uuid != 0x0);

        address sender;
        address receiver;
        if (_direction == Direction.Deposit) {
            require(!_requestExists(msg.sender, State.Prepared, _direction));
            sender = ilpOwner;
            receiver = msg.sender;
        } else {
            require(_amount <= digitalMoneyManager.balanceOf(_moneyId,msg.sender));
            sender = msg.sender;
            receiver = ilpOwner;
            _withdraw(sender, _amount, _moneyId);
        }

        transfers[_uuid] = ILPTransfer(
            sender,
            receiver,
            _amount,
            _condition,
            _expiry,
            State.Prepared,
            _direction
        );

        ilpPackets[_uuid] = _data;
        moneyIds[_uuid] = _moneyId;
        requests[msg.sender].push(_uuid);
        emit Update(_uuid, State.Prepared);
        return 0;
    }

    /// @dev execute deposit/withdraw requests
    /// @param _uuid UUID used as an external identifier
    /// @param _fulfillment an arbitrary 32-byte buffer and is provided as a base64url-encoded string
    /// @return Whether the transaction was successful or not (0: Successful)
    function fulfillTransfer (
        bytes16 _uuid,
        bytes _fulfillment
    ) external onlyIlpOwner whenNotPaused returns (int8) {
        ILPTransfer storage ilpTransfer = transfers[_uuid];

        require(ilpTransfer.sender != address(0));
        require(ilpTransfer.state == State.Prepared);
        require(
            (ilpTransfer.direction == Direction.Deposit) ||
            (ilpTransfer.direction == Direction.Withdraw)
        );

        if (block.timestamp > ilpTransfer.expiry) {
            if (ilpTransfer.direction == Direction.Withdraw) {
                _deposit(ilpTransfer.sender, ilpTransfer.amount, moneyIds[_uuid]);
            }
            ilpTransfer.state = State.Aborted;
            emit Update(_uuid, ilpTransfer.state);
            return 0;
        }

        if (sha256(_fulfillment) == ilpTransfer.condition) {
            if (ilpTransfer.direction == Direction.Deposit) {
                _deposit(ilpTransfer.receiver, ilpTransfer.amount, moneyIds[_uuid]);
            }
            ilpTransfer.state = State.Executed;
            emit Fulfill(_uuid, _fulfillment);
            return 0;
        }

        return -1;
    }

    /// @dev abort deposit/withdraw requests
    /// @param _uuid UUID used as an external identifier
    /// @return Whether the transaction was successful or not (0: Successful)
    function abortTransfer (
        bytes16 _uuid
    ) external whenNotPaused returns (int8) {
        ILPTransfer storage ilpTransfer = transfers[_uuid];

        require(ilpTransfer.sender != address(0));
        require(ilpTransfer.state == State.Prepared);
        require(
            (ilpTransfer.direction == Direction.Deposit && msg.sender == ilpTransfer.receiver) ||
            (ilpTransfer.direction == Direction.Withdraw && msg.sender == ilpTransfer.sender)  ||
            (msg.sender == ilpOwner)
        );

        if (ilpTransfer.direction == Direction.Withdraw) {
            _deposit(ilpTransfer.sender, ilpTransfer.amount, moneyIds[_uuid]);
        }
        ilpTransfer.state = State.Aborted;
        emit Update(_uuid, State.Aborted);
        return 0;
    }

    /// @dev Gets the money object of the specified money ID
    /// @param _moneyId the moneyId of the money object
    /// @return moneyId the moneyId of the money object
    /// @return name the name of the money object
    /// @return symbol the symbol of the money object
    /// @return owner the owner of the money object
    /// @return totalSupply the total supply of the money object
    function getMoney(uint256 _moneyId) external view returns(
        address contractAddress,
        string name,
        string symbol,
        address owner,
        uint256 totalSupply,
        uint8 decimals
    ) {
        return digitalMoneyManager.getTokenInfo(_moneyId);
    }

    /// @dev return information of transfer
    /// @param _uuid UUID used as an external identifier
    /// @return ILPTransfer
    function getTransfer (
        bytes16 _uuid
    ) external view returns (address, address, uint256, bytes32, uint, State, Direction) {
        return (
            transfers[_uuid].sender,
            transfers[_uuid].receiver,
            transfers[_uuid].amount,
            transfers[_uuid].condition,
            transfers[_uuid].expiry,
            transfers[_uuid].state,
            transfers[_uuid].direction
        );
    }

    /// @dev return transfer's ilp packet
    /// @param _uuid UUID used as an external identifier
    /// @return ilp packet
    function getIlpPacket (
        bytes16 _uuid
    ) external view returns (bytes) {
        return ilpPackets[_uuid];
    }

    /// @dev Return moneyId
    /// @param _uuid UUID used as an external identifier
    /// @return moneyId
    function getMoneyIdByTransferId (
        bytes16 _uuid
    ) external view returns (uint256) {
        return moneyIds[_uuid];
    }

    /// @dev return array of UUID specified by parameters
    /// @param _requester RDDN Address of the requester
    /// @param _state 0:Prepared, 1:Executed, 2:Aborted
    /// @param _direction 0:Deposit, 1:Withdraw
    /// @return array of UUID
    function getRequests (
        address _requester,
        State _state,
        Direction _direction
    ) external view returns (bytes16[]) {
        uint len = requests[_requester].length;
        if (len == 0) {
            return new bytes16[](0);
        }
        uint resultLen = 0;
        for (uint i = 0; i < len; i++) {
            if (
                transfers[requests[_requester][i]].state == _state &&
                transfers[requests[_requester][i]].direction == _direction
            ) {
                resultLen++;
            }
        }
        bytes16[] memory result = new bytes16[](resultLen);
        uint k = 0;
        for (uint j = 0; j < len; j++) {
            if (
                transfers[requests[_requester][j]].state == _state &&
                transfers[requests[_requester][j]].direction == _direction
            ) {
                result[k++] = requests[_requester][j];
            }
        }

        return result;
    }


    /*** INTERNAL FUNCTIONS ***/

    /// @dev Deposit the specified amount of money to the specified address.
    /// @param _customer  Receiver address.
    /// @param _depositMoney Amount of money that will be deposited.
    /// @param _moneyId Money identifer.
    /// @return '_totalSupply' of the moneyId & '_balance' of the customer.
    function _deposit(
        address _customer,
        uint256 _depositMoney,
        uint256 _moneyId
    ) private returns (
        uint256 _totalSupply,
        uint256 _balance
    ) {
        digitalMoneyManager.mint(_customer, _depositMoney, _moneyId);

        emit Deposit(_customer, _depositMoney, digitalMoneyManager.totalSupplyOf(_moneyId), _moneyId);
        return (
            digitalMoneyManager.totalSupplyOf(_moneyId),
            digitalMoneyManager.balanceOf(_moneyId, _customer)
        );
    }

    /// @dev Withdrow the specified amount of money from the specified address.
    /// @param _customer  Customer address.
    /// @param _withdrawMoney Amount of money that will be withdrowed.
    /// @param _moneyId Money identifer.
    /// @return '_totalSupply' of the moneyId & '_balance' of the customer.
    function _withdraw(
        address _customer,
        uint256 _withdrawMoney,
        uint256 _moneyId
    ) private returns (
        uint256 _totalSupply,
        uint256 _balance
    ) {
        digitalMoneyManager.burnFrom(_customer, _withdrawMoney, _moneyId);

        emit Withdraw(_customer, _withdrawMoney, digitalMoneyManager.totalSupplyOf(_moneyId), _moneyId);
        return (
            digitalMoneyManager.totalSupplyOf(_moneyId),
            digitalMoneyManager.balanceOf(_moneyId, _customer)
        );
    }

    /// @dev Does the request specified by the parameter exist?
    /// @param _requester RDDN Address of the requester
    /// @param _state 0:Prepared, 1:Executed, 2:Aborted
    /// @param _direction 0:Deposit, 1:Withdraw
    /// @return true: exists, false: not exists
    function _requestExists (
        address _requester,
        State _state,
        Direction _direction
    ) private view returns (bool) {
        uint len = requests[_requester].length;
        if (len == 0) {
            return false;
        }
        for (uint i = 0; i < len; i++) {
            if (
                transfers[requests[_requester][i]].state == _state &&
                transfers[requests[_requester][i]].direction == _direction
            ) {
                return true;
            }
        }
        return false;
    }

}
