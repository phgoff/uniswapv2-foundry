// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/test/WETH9.sol";
import "../src/UniswapV2Factory.sol";
// import "../src/UniswapV2Router02.sol";

contract CounterTest is Test {
    WETH9 public weth;
    UniswapV2Factory public factory;
    // UniswapV2Router02 public router;
    address feeToSetter = address(0x1);

    function setUp() public {
        weth = new WETH9();
        factory = new UniswapV2Factory(feeToSetter);
        // router = new UniswapV2Router02(factory, weth);
       
    }

    function testIncrement() public {
         emit log_address(address(factory));
         emit log_address(address(weth));
           emit log_address(factory.feeToSetter());
        //  emit log_address(address(router));
    }

    // function testSetNumber(uint256 x) public {
    //     counter.setNumber(x);
    //     assertEq(counter.number(), x);
    // }
}
