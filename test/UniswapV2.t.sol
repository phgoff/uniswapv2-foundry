// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/test/WETH9.sol";
import "../src/test/TestERC20.sol";
import "../src/UniswapV2Factory.sol";
import "../src/UniswapV2Router02.sol";

contract UniswapV2Test is Test {
    WETH9 public weth;
    TestERC20 public dai;
    TestERC20 public usdc;

    UniswapV2Factory public factory;
    UniswapV2Router02 public router;

    address owner = address(0x1);
    address trader = address(0x2);

    function setUp() public {
        weth = new WETH9();
        factory = new UniswapV2Factory(owner);
        router = new UniswapV2Router02(address(factory), address(weth));

    }

    function testInitCodePairHash() public {
        bytes32 initCodeHash = factory.INIT_CODE_PAIR_HASH();
        emit log_named_bytes32("initCodeHash", initCodeHash);
    }

    function testMintToken() public {
        vm.startPrank(owner);
        dai = new TestERC20("DAI", "DAI");
        uint256 balanceOfDai = dai.balanceOf(owner);
        assertEq(balanceOfDai, 100 ether);
    }

    function testSwap() public {
        vm.startPrank(owner);
        uint256 ONE_ETH = 1 ether;
        uint256 TEN_ETH = 10 ether;
        uint256 ONE_HUNDRED_ETH = 100 ether;
        uint256 MAX_UINT256 = type(uint256).max;

        dai = new TestERC20("DAI", "DAI");
        usdc = new TestERC20("USDC", "USDC");

        // ----add liquidity----

        dai.approve(address(router), type(uint256).max);
        usdc.approve(address(router), type(uint256).max);

        uint256 daiAllowance = dai.allowance(owner, address(router));
        uint256 usdcAllowance = usdc.allowance(owner, address(router));
        assertEq(daiAllowance, MAX_UINT256);
        assertEq(usdcAllowance, MAX_UINT256);

        router.addLiquidity(address(dai), address(usdc), TEN_ETH, TEN_ETH, 0, 0, owner, block.timestamp + 1000);

        uint256 daiBalance = dai.balanceOf(owner);
        uint256 usdcBalance = usdc.balanceOf(owner);
        assertEq(daiBalance, ONE_HUNDRED_ETH - TEN_ETH);
        assertEq(usdcBalance, ONE_HUNDRED_ETH - TEN_ETH);

         // ----swap token----

        address[] memory path = new address[](2);
        path[0] = address(dai);
        path[1] = address(usdc);
        uint256[] memory amounts = router.swapExactTokensForTokens(ONE_ETH, 0, path, owner, block.timestamp + 1000);
        daiBalance = dai.balanceOf(owner);
        usdcBalance = usdc.balanceOf(owner);
        assertEq(daiBalance, ONE_HUNDRED_ETH - TEN_ETH - ONE_ETH);
        assertEq(usdcBalance, ONE_HUNDRED_ETH - TEN_ETH + amounts[1]);

        address pair = factory.getPair(address(dai), address(usdc));
        // check liquidity in pool
        (uint256 daiReserve, uint256 usdcReserve, ) = UniswapV2Pair(pair).getReserves();
        assertEq(daiReserve, TEN_ETH + ONE_ETH);
        assertEq(usdcReserve, TEN_ETH - amounts[1]);

        // ----remove liquidity----

        // get liquidity
        uint256 liquidity = UniswapV2Pair(pair).balanceOf(owner);

        // approve liquidity to router
        UniswapV2Pair(pair).approve(address(router), liquidity);

        router.removeLiquidity(address(dai), address(usdc), liquidity, 0, 0, owner, block.timestamp + 1000);
       
        // check liquidity in pool
        (daiReserve, usdcReserve, ) = UniswapV2Pair(pair).getReserves();
        // check liquidity of owner
        liquidity = UniswapV2Pair(pair).balanceOf(owner);
        assertEq(liquidity, 0);
    }
}
