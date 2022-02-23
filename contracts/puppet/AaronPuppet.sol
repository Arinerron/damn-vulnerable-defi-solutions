pragma solidity ^0.8.0;

import "./PuppetPool.sol";
import "hardhat/console.sol";

contract AaronPuppet {
    PuppetPool pool;
    uint256 amount;

    constructor(address _pool, uint256 _amount) public {
        pool = PuppetPool(_pool);
        amount = _amount;
    }

    receive() payable external {}

    function pwn() external {
        console.log("aaronpuppet balance :: %s", address(this).balance);
        console.log("aaronpuppet sending amount :: %s", amount);
        //pool.borrow{value: 1}(0);
        /*msg.sender.functionCallWithValue(
            abi.encodeWithSignature(
                "borrow(uint256)",
                0
            ),
            123
        );*/
        console.log("aaronpuppet balance :: %s", address(this).balance);
    }
}
