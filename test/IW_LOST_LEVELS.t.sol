// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/IW.sol";
import "src/IW_LOST_LEVELS.sol";
import "src/Distributor.sol";

contract CantographsTest is Test {

    IW_LOST_LEVELS public nft;
    Distributor public distributor;

    IW public iwNft;
    IW public cgrphNft;

    address public constant alice = address(0xA11ce);
    address public constant dep = address(0xad1);

    address[100] public iwHolders;
    address[100] public cgrphHolders; 
    
    function setUp() public {
        vm.startPrank(dep);

            nft = new IW_LOST_LEVELS("www.test.com/");

            iwNft = new IW();
            cgrphNft = new IW();

            address[] memory mCgrphHolders = new address[](100); 
            address[] memory mIwHolders = new address[](100); 

            for(uint256 i = 0; i<100; i++) {
                iwHolders[i] = address(uint160(100+i));
                mIwHolders[i] = address(uint160(100+i));
                cgrphHolders[i] = address(uint160(1000+i));
                mCgrphHolders[i] = address(uint160(1000+i));
            }

            iwNft.bulkMint(mIwHolders);
            cgrphNft.bulkMint(mCgrphHolders);

            distributor = new Distributor(address(nft), address(cgrphNft), address(iwNft));
            nft.setDistributor(address(distributor));

        vm.stopPrank();
    }

    function testMints() public {

        vm.deal(iwHolders[0], 10_000 ether);

        vm.startPrank(iwHolders[0]);

            distributor.earlyMintIW{value: 200 ether}(0);

        vm.stopPrank();

        assertEq(nft.balanceOf(iwHolders[0]), 1);

        vm.deal(cgrphHolders[0], 10_000 ether);

        vm.startPrank(cgrphHolders[0]);

            distributor.earlyMintCGRPH{value: 200 ether}(0);

        vm.stopPrank();

        assertEq(nft.balanceOf(cgrphHolders[0]), 1);

        vm.deal(alice, 10_000 ether);

        vm.warp(block.timestamp + 1 days);

        vm.startPrank(alice);
        
            distributor.publicMint{value: 200 ether}(1);

        vm.stopPrank();

        assertEq(nft.balanceOf(alice), 1);

    }


    
    function testMintUnderpriced() public {

        vm.deal(alice, 10_000 ether);

        vm.warp(block.timestamp + 1 days);

        vm.startPrank(alice);
        
            vm.expectRevert(bytes("Insufficient payment"));
            distributor.publicMint{value: 199 ether*5}(5);

        vm.stopPrank();

        assertEq(nft.balanceOf(alice), 0);

    }

    function testMintTooMany() public {

        vm.deal(alice, 10_000 ether);

        vm.warp(block.timestamp + 1 days);

        vm.startPrank(alice);
        
            vm.expectRevert(bytes("Max 5 mints"));
            distributor.publicMint{value: 200 ether*6}(6);

        vm.stopPrank();

        assertEq(nft.balanceOf(alice), 0);

        vm.startPrank(alice);
            
            distributor.publicMint{value: 200 ether*5}(5);
            assertEq(nft.balanceOf(alice), 5);

            vm.expectRevert(bytes("Max 5 per address"));
            distributor.publicMint{value: 200 ether*1}(1);
            assertEq(nft.balanceOf(alice), 5);

        vm.stopPrank();

    }

    function testMintOwner() public {

        vm.startPrank(dep);
        
            distributor.publicMint(11);

        vm.stopPrank();

        assertEq(nft.balanceOf(dep), 11);

    }

    function testCanMintAll() public {

        vm.warp(block.timestamp + 1 days);

        for(uint256 i = 0; i<400; ++i) {

            vm.deal(address(uint160(i+1)), 10_000 ether);

            vm.startPrank(address(uint160(i+1)));

                distributor.publicMint{value: 200 ether*5}(5);
                
            vm.stopPrank();

            assertEq(nft.balanceOf(address(uint160(i+1))), 5);

            for(uint256 j = 0; j<5; ++j) {
                assert(nft.tokenOfOwnerByIndex(address(uint160(i+1)),j)<2001);
                assert(nft.tokenOfOwnerByIndex(address(uint160(i+1)),j)>0);
            }
        }

        assertEq(nft.totalSupply(), 2000);

        vm.deal(alice, 10_000 ether);

        vm.startPrank(alice);
        
            vm.expectRevert(bytes("Mint closed"));
            distributor.publicMint{value: 200 ether*1}(1);

        vm.stopPrank();

        assertEq(nft.balanceOf(alice), 0);

        vm.startPrank(dep);
            assertEq(address(distributor).balance, 200 ether * 2000);
            
            distributor.withdraw(address(distributor).balance);
            assertEq(address(distributor).balance, 0);
            assertEq(address(dep).balance, 200 ether * 2000);

        vm.stopPrank();

    }

    function testSupportsInterface() public {

        assert(nft.supportsInterface(type(IERC721).interfaceId));
        assert(nft.supportsInterface(type(IERC721Metadata).interfaceId));
        assert(nft.supportsInterface(type(IERC721Enumerable).interfaceId));
        assert(nft.supportsInterface(0x01ffc9a7)); //165
        assert(nft.supportsInterface(type(IERC2981).interfaceId));

    }

    function testMintFromContract() public {

        vm.startPrank(dep);
        
            vm.expectRevert("IW_LOST_LEVELS: caller is not the distributor");
            nft.mintFromDistributor(dep, 1);

        vm.stopPrank();

        assertEq(nft.balanceOf(dep), 0);

        vm.startPrank(alice);
        
            vm.expectRevert("IW_LOST_LEVELS: caller is not the distributor");
            nft.mintFromDistributor(alice, 1);

        vm.stopPrank();

        assertEq(nft.balanceOf(alice), 0);


    }

    function testUri() public {

        vm.warp(block.timestamp + 1 days);

        vm.deal(alice, 10_000 ether);

        vm.startPrank(alice);

            distributor.publicMint{value: 200 ether*1}(1);

        vm.stopPrank();

        uint256 id = nft.tokenOfOwnerByIndex(alice,0);

        assertEq(nft.tokenURI(id),"www.test.com/740");

    }



}
