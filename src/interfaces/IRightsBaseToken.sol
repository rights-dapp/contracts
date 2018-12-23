pragma solidity ^0.4.24;

/// @title RightsBaseToken interface
/// @dev Interface for RightsBaseToken
contract IRightsBaseToken {

    event Update(
        address owner,
        string name,
        string symbol
    );

    function name() public view returns(string);
    function symbol() public view returns(string);
    function decimals() public view returns(uint8);
    function mint(address to, uint256 value) public returns (bool);
    function burnFrom(address to,uint256 value) public returns (bool);

    function forceTransferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool);

    function update(string newName, string newSymbol) public;


}