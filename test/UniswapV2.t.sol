// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/test/WETH9.sol";
import "../src/test/ERC20.sol";
import "../src/UniswapV2Factory.sol";
import "../src/UniswapV2Router02.sol";

contract UniswapV2Test is Test {
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

    function testInitCodePairHash() public {
        bytes32 initCodeHash = factory.INIT_CODE_PAIR_HASH();
        emit log_named_bytes32("initCodeHash", initCodeHash);
    }

    function testMintToken() public {
        vm.startPrank(owner);
        dai = new ERC20(100);
        uint256 balanceOfDai = dai.balanceOf(owner);
        assertEq(balanceOfDai, 100);
    }

    function testAddLP() public {
        vm.startPrank(owner);
        uint256 ONE_ETH = 1 ether;
        uint256 TEN_ETH = 10 ether;

        dai = new ERC20(TEN_ETH);
        usdc = new ERC20(TEN_ETH);

        dai.approve(address(router), ONE_ETH);
        usdc.approve(address(router), ONE_ETH);

        uint256 daiAllowance = dai.allowance(owner, address(router));
        uint256 usdcAllowance = usdc.allowance(owner, address(router));
        assertEq(daiAllowance, ONE_ETH);
        assertEq(usdcAllowance, ONE_ETH);

        router.addLiquidity(address(dai), address(usdc), ONE_ETH, ONE_ETH, 0, 0, owner, block.timestamp + 1000);

        uint256 daiBalance = dai.balanceOf(owner);
        uint256 usdcBalance = usdc.balanceOf(owner);
        assertEq(daiBalance, TEN_ETH - ONE_ETH);
        assertEq(usdcBalance, TEN_ETH - ONE_ETH);

    }
}
