// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/test/WETH9.sol";
import "../src/test/ERC20.sol";
import "../src/UniswapV2Factory.sol";
import "../src/UniswapV2Router02.sol";

contract CounterTest is Test {
    WETH9 public weth;
    ERC20 public dai;
    ERC20 public usdc;
    UniswapV2Factory public factory;
    UniswapV2Router02 public router;
    address owner = address(0x1);
    address trader = address(0x2);

    function setUp() public {
        weth = new WETH9();
        factory = new UniswapV2Factory(owner);
        router = new UniswapV2Router02(address(factory), address(weth));
       
    }
    function testMintToken() public {
        vm.startPrank(owner);
        dai = new ERC20(100);
        uint256 balanceOfDai = dai.balanceOf(owner);
        assertEq(balanceOfDai, 100);
    }

    function testAddLP() public {
        emit log_address(address(factory));
        emit log_address(address(weth));
        emit log_address(address(router));
        emit log_address(factory.feeToSetter());

    }
}
