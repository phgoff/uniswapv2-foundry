// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/test/TestERC20.sol";
import "../src/test/WETH9.sol";
import "../src/UniswapV2Factory.sol";
import "../src/UniswapV2Router02.sol";
import '../src/libraries/Math.sol';

contract UniswapV2Test is Test {
    WETH9 public weth;
    TestERC20 public dai;
    TestERC20 public usdc;

    UniswapV2Factory public factory;
    UniswapV2Router02 public router;

    address public owner = address(0x1);
    address public feeTo = address(0x2);
    address public firstLP = address(0x3);
    address public secLP = address(0x4);

    function setUp() public {
        vm.startPrank(owner);
        weth = new WETH9();

        dai = new TestERC20("DAI", "DAI");
        usdc = new TestERC20("USDC", "USDC");

        factory = new UniswapV2Factory(owner);
        factory.setFeeTo(feeTo);
        router = new UniswapV2Router02(address(factory), address(weth));

        dai.mint(firstLP, 100 ether);
        usdc.mint(firstLP, 100 ether);

        dai.mint(secLP, 100 ether);
        usdc.mint(secLP, 100 ether);

        dai.approve(address(router), 100 ether);
        usdc.approve(address(router), 100 ether);

        vm.stopPrank();

    }

    function testLog() public {
        emit log_named_bytes32("factory code hash", factory.INIT_CODE_PAIR_HASH());
        // emit log_named_address("factory address", address(factory));
        //     // emit log_named_address("router address", address(router));
    }

    function logTokenBalance() internal {
        emit log("-----/Token/-----");
        uint256 balanceOfDai = dai.balanceOf(firstLP);
        uint256 balanceOfUsdc = usdc.balanceOf(firstLP);
        emit log_named_decimal_uint("DAI - FirstLP", balanceOfDai, 18);
        emit log_named_decimal_uint("USDC - FirstLP", balanceOfUsdc, 18);

        // secLP
        uint256 balanceOfDaiSec = dai.balanceOf(secLP);
        uint256 balanceOfUsdcSec = usdc.balanceOf(secLP);
        emit log_named_decimal_uint("DAI - SecLP", balanceOfDaiSec, 18);
        emit log_named_decimal_uint("USDC - SecLP", balanceOfUsdcSec, 18);

        uint256 balanceOfDaiFeeto = dai.balanceOf(feeTo);
        uint256 balanceOfUsdcFeeto = usdc.balanceOf(feeTo);
        emit log_named_decimal_uint("DAI - feeTo", balanceOfDaiFeeto, 18);
        emit log_named_decimal_uint("USDC - feeTo", balanceOfUsdcFeeto, 18);
        emit log("-----/Token/-----");
    }

    function logLPBalance() internal {
        emit log("-----/LP/-----");
         address pair = factory.getPair(address(dai), address(usdc));
        (uint256 r0, uint256 r1, ) = UniswapV2Pair(pair).getReserves();
        emit log_named_decimal_uint("DAI IN POOL", r0, 18);
        emit log_named_decimal_uint("USDC IN POOL", r1, 18);
        uint256 balanceLpOfFeeTo = UniswapV2Pair(pair).balanceOf(feeTo);
        uint256 balanceLpOfFirstLp = UniswapV2Pair(pair).balanceOf(firstLP);
        uint256 balanceLpOfSecLp = UniswapV2Pair(pair).balanceOf(secLP);
        uint256 totalSupply = UniswapV2Pair(pair).totalSupply();
        emit log_named_decimal_uint("LP Total supply", totalSupply, 18);
        emit log_named_decimal_uint("LP - FeeTo ", balanceLpOfFeeTo, 18);
        emit log_named_decimal_uint("LP - FirstLP ", balanceLpOfFirstLp, 18);
        emit log_named_decimal_uint("LP - SecondLP", balanceLpOfSecLp, 18);
        emit log("-----/LP/-----");
    }

    function logReserves() public {
        // get pair
        address pair = factory.getPair(address(dai), address(usdc));
        UniswapV2Pair pairContract = UniswapV2Pair(pair);
        // get reserves
        (uint256 reserve0, uint256 reserve1, ) = pairContract.getReserves();

        uint256 rootK = Math.sqrt(reserve0 * reserve1);
        uint256 rootKLast = Math.sqrt(pairContract.kLast());
        uint256 totalSupply = pairContract.totalSupply();
        uint256 balanceOfLp = UniswapV2Pair(pair).balanceOf(feeTo);
        uint256 balanceOfLpOwner = UniswapV2Pair(pair).balanceOf(owner);

        emit log_named_uint("reserve0", reserve0);
        emit log_named_uint("reserve1", reserve1);
        emit log_named_uint("root k", rootK);
        emit log_named_uint("root k last", rootKLast);
        emit log_named_uint("total supply", totalSupply);
        emit log_named_uint("balance of lp feeTo", balanceOfLp);
        emit log_named_uint("balance of lp owner", balanceOfLpOwner);

        emit log("----------------------------------");
    }

    function addLP(address from) internal {
        vm.startPrank(from);
        dai.approve(address(router), 100 ether);
        usdc.approve(address(router), 100 ether);
        router.addLiquidity(
            address(dai),
            address(usdc),
            10 ether,
            10 ether,
            0,
            0,
            from,
            block.timestamp + 1000
        );
        logLPBalance();
        logTokenBalance();
        vm.stopPrank();
    }

    function removeLP(address from) internal {
        vm.startPrank(from);
        address pair = factory.getPair(address(dai), address(usdc));
        UniswapV2Pair(pair).approve(address(router), 100 ether);
        uint256 lps = UniswapV2Pair(pair).balanceOf(from);
        router.removeLiquidity(
            address(dai),
            address(usdc),
            lps,
            0,
            0,
            from,
            block.timestamp + 1000
        );
        logLPBalance();
        logTokenBalance();
        vm.stopPrank();
    }

    function testFullProcess() public {
        // Step 1: FirstLP Add LP
        emit log("**** Added LP ****");
        addLP(firstLP);
        assertEq(dai.balanceOf(firstLP), 100 ether - 10 ether);

        // address pair = factory.getPair(address(dai), address(usdc));
        address[] memory path = new address[](2);
        path[0] = address(dai);
        path[1] = address(usdc);
        address[] memory path2 = new address[](2);
        path2[0] = address(usdc);
        path2[1] = address(dai);

        // Step 2: Owner Swap 2 times
        vm.startPrank(owner);
        router.swapExactTokensForTokens(1 ether, 0, path, owner, block.timestamp + 1000);
        router.swapExactTokensForTokens(1 ether, 0, path2, owner, block.timestamp + 1000);
        vm.stopPrank();
        emit log("**** Swapped ****");

        logLPBalance();

        // Step 3: To trigger mint fee, we need to add another LP
        // Step 3.1: SecondLP add LP
        emit log("**** Addded 2nd LP ****");
        addLP(secLP);

        vm.startPrank(owner);
        router.swapExactTokensForTokens(1 ether, 0, path, owner, block.timestamp + 1000);
        router.swapExactTokensForTokens(1 ether, 0, path2, owner, block.timestamp + 1000);
        vm.stopPrank();
        emit log("**** Swapped ****");

        // Step 4: FirstLP remove LP
        emit log("**** Removed 1st LP ****");
        removeLP(firstLP);

        emit log("**** Removed 2nd LP ****");
        removeLP(secLP);

        emit log("**** Removed FeeTo LP ****");
        removeLP(feeTo);
       
    }



}
