pragma solidity ^0.4.24;


import "./../tokens/ERC20Token.sol";
import "./../interfaces/IRightsBaseToken.sol";
import "./../utils/ManagerRole.sol";

contract RightsBaseToken is ERC20Token, IRightsBaseToken, ManagerRole {

    /*** STORAGE ***/

    string private _name;
    string private _symbol;
    uint8 private _decimals;


    /*** CONSTRUCTOR ***/

    constructor(string name, string symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }


    /*** EXTERNAL FUNCTIONS ***/

    /// @return the name of the token.
    function name() public view returns(string) {
        return _name;
    }

    /// @return the symbol of the token.
    function symbol() public view returns(string) {
       return _symbol;
    }

    /// @return the number of decimals of the token.
    function decimals() public view returns(uint8) {
        return _decimals;
    }

    /// @dev Function to mint tokens
    /// @param to The address that will receive the minted tokens.
    /// @param value The amount of tokens to mint.
    /// @return A boolean that indicates if the operation was successful.
    function mint(
        address to,
        uint256 value
    )
        public
        onlyMinter
        whenNotPaused
        returns (bool)
    {
        _mint(to, value);
        return true;
    }

    /// @dev Burns a specific amount of tokens.
    /// @param to The address that will receive the minted tokens.
    /// @param value The amount of token to be burned.
    /// @return A boolean that indicates if the operation was successful.
    function burnFrom(address to, uint256 value)
        public
        onlyMinter
        whenNotPaused
        returns (bool)
    {
        _burn(to, value);
        return true;
    }


    /// @dev Function to transfer tokens by manager
    /// @param from The address that will send the tokens.
    /// @param to The address that will receive the tokens.
    /// @param value The amount of tokens to transfer.
    /// @return A boolean that indicates if the operation was successful.
    function forceTransferFrom(
        address from,
        address to,
        uint256 value
    )
        public
        whenNotPaused
        onlyManager
        returns (bool)
    {
        _transfer(from, to, value);
        return true;
    }

    /// @dev Updates the token info
    /// @param newName the name of the token.
    /// @param newSymbol the symbol of the token.
    function update(
        string newName,
        string newSymbol
    )
        public
        whenNotPaused
        onlyManager
    {
        _name = newName;
        _symbol = newSymbol;

        emit Update(msg.sender, newName, newSymbol);
    }
}