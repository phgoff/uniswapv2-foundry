// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/test/TestERC20.sol";
import "../src/test/WETH9.sol";
import "../src/UniswapV2Factory.sol";
import "../src/UniswapV2Router02.sol";

contract UniswapV2Test is Test {
    WETH9 public weth;
    TestERC20 public dai;
    TestERC20 public usdc;

    UniswapV2Factory public factory;
    UniswapV2Router02 public router;

    address public owner = address(0x1);

    function setUp() public {
        weth = new WETH9();

        vm.startPrank(owner);
        dai = new TestERC20("DAI", "DAI");
        usdc = new TestERC20("USDC", "USDC");

        factory = new UniswapV2Factory(owner);
        router = new UniswapV2Router02(address(factory), address(weth));
    }

    function testLog() public {
        emit log_named_address("factory address", address(factory));
        emit log_named_address("router address", address(router));
    }

    function testAddLP() public {
        uint256 balanceOfDai = dai.balanceOf(owner);
        emit log_named_uint("balance of dai", balanceOfDai / 1 ether);

        dai.approve(address(router), 100 ether);
        usdc.approve(address(router), 100 ether);

        // Add LP
        router.addLiquidity(
            address(dai),
            address(usdc),
            10 ether,
            10 ether,
            0,
            0,
            owner,
            block.timestamp + 1000
        );

        assertEq(dai.balanceOf(owner), 100 ether - 10 ether);

        uint256 balanceOfDaiAfter = dai.balanceOf(owner);
        emit log_named_uint("balance of dai after", balanceOfDaiAfter / 1 ether);
        uint256 balanceOfUsdcAfter = usdc.balanceOf(owner);
        emit log_named_uint("balance of usdc after", balanceOfUsdcAfter / 1 ether);

        uint256 allowanceDai = dai.allowance(owner, address(router));
        emit log_named_uint("allowance dai", allowanceDai / 1 ether);

        // We can swap now
        address[] memory path = new address[](2);
        path[0] = address(dai);
        path[1] = address(usdc);
        router.swapExactTokensForTokens(1 ether, 0, path, owner, block.timestamp + 1000);

        uint256 balanceOfDaiAfterSwap = dai.balanceOf(owner);
        emit log_named_uint("balance of dai after swap", balanceOfDaiAfterSwap / 1 ether);
        uint256 balanceOfUsdcAfterSwap = usdc.balanceOf(owner);
        emit log_named_uint("balance of usdc after swap", balanceOfUsdcAfterSwap);


        // Question: wants to sell 2 usdc for dai. how much dai we need to pay?
        // Question: wants to sell 2 eth for dai. how much dai we need to pay?


        // Remove lp
        // how much lp do we have?
        address pair = factory.getPair(address(dai), address(usdc));
        uint256 balanceOfLp = UniswapV2Pair(pair).balanceOf(owner);

        // x = 10, y = 10
        // lp = sqrt(100) = 10
        emit log_named_uint("balance of lp", balanceOfLp);

        // approve lp token to router to remove
        UniswapV2Pair(pair).approve(address(router), balanceOfLp);

        // remove 1 lp
        router.removeLiquidity(address(dai), address(usdc), balanceOfLp, 0, 0, owner, block.timestamp + 1000);

        // how much lp do we have?
        uint256 balanceOfLpAfter = UniswapV2Pair(pair).balanceOf(owner);
        emit log_named_uint("balance of lp after", balanceOfLpAfter);
        assertEq(balanceOfLpAfter, 0);
    }

}
