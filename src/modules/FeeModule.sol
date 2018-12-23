pragma solidity ^0.4.24;

import "./../utils/RDDNControl.sol";

import "openzeppelin-solidity/math/SafeMath.sol";

contract FeeModule is RDDNControl {
    using SafeMath for uint256;

    event FeeRatioUpdated(
        address indexed owner,
        uint8 indexed previousnewFeeRatio,
        uint8 indexed newFeeRatio
    );

    uint8 private _feeRatio;
    uint8 private constant _maxRatio = 100;

    constructor(uint8 newFee) internal {
        setFeeRatio(newFee);
    }

    function setFeeRatio(uint8 newFee) public onlyOwner {
        require(_maxRatio >= newFee);

        emit FeeRatioUpdated(msg.sender, _feeRatio, newFee);
        _feeRatio = newFee;
    }

    function feeRatio() public view returns(uint8) {
        return _feeRatio;
    }

    function afterFeeRatio() public view returns(uint8) {
        return _maxRatio - _feeRatio;
    }
    
    function feeAmount(uint256 amount) public view returns(uint256) {
        return amount.mul(feeRatio()).div(_maxRatio);
    }

    function afterFeeAmount(uint256 amount) public view returns(uint256) {
        return amount.mul(afterFeeRatio()).div(_maxRatio);
    }
}