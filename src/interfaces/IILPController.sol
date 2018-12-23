pragma solidity ^0.4.24;

/// @title IILPController interface
/// @dev Interface for IILPController
contract IILPController {

    enum State {
        Prepared,
        Executed,
        Aborted
    }

    enum Direction {
        Deposit,
        Withdraw
    }

    event Withdraw(
        address customer,
        uint256 amountToWithdraw,
        uint256 updatedTotalSupply,
        uint256 moneyId
    );

    event Deposit(
        address customer,
        uint256 amountToDeposit,
        uint256 updatedTotalSupply,
        uint256 moneyId
    );

    event Transfer(
        address from,
        address to,
        uint256 value,
        uint256 moneyId
    );

    event Update(
        address updator,
        uint256 moneyId,
        string name,
        string symbol,
        address owner,
        uint256 totalSupply
    );

    event Update (
        bytes16 indexed uuid,
        State state
    );

    event Fulfill (
        bytes16 indexed uuid,
        bytes fulfillment
    );

    function setIlpOwner(address _newIlpOwner) external;

    function createTransfer (
        uint256 _moneyId,
        uint _amount,
        bytes32 _condition,
        bytes16 _uuid,
        uint _expiry,
        bytes _data,
        Direction _direction
    ) external returns (
        int8 result
    );

    function fulfillTransfer (
        bytes16 _uuid,
        bytes _fulfillment
    ) external returns (
        int8 result
    );

    function abortTransfer (
        bytes16 _uuid
    ) external returns (
        int8 result
    );

    function getMoney(uint256 _moneyId) external view returns(
        address contractAddress,
        string name,
        string symbol,
        address owner,
        uint256 totalSupply,
        uint8 decimals
    );

    function getTransfer (
        bytes16 _uuid
    ) external view returns (
        address sender,
        address receiver,
        uint256 amount,
        bytes32 condition,
        uint expiry,
        State state,
        Direction direction
    );

    function getIlpPacket (
        bytes16 _uuid
    ) external view returns (
        bytes ilpPacket
    );

    function getMoneyIdByTransferId (
        bytes16 _uuid
    ) external view returns (
        uint256 moneyId
    );

    function getRequests (
        address _requester,
        State _state,
        Direction _direction
    ) external view returns (
        bytes16[] requests
    );
}
