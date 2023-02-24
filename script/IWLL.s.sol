// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "src/IW_LOST_LEVELS.sol";
import "src/Distributor.sol";

contract IWLLScript is Script {

    IW_LOST_LEVELS public nft;
    Distributor public distributor;

    address cgph = 0x12f73617D48b7aab8FE9f2B3b76C55F1055fAa01;
    address iw = 0x24757E4b5AD64e6b48d78Dc800D45b4061698757;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

            nft = new IW_LOST_LEVELS("https://nftstorage.link/ipfs/bafybeignf5eeht2qf334bk7swgn6lq7hlmp36hsywfo2ckdgtm7zyp5nke/");
            distributor = new Distributor(address(nft), cgph, iw);
            nft.setDistributor(address(distributor));

        vm.stopBroadcast();
    }
}


// forge script script/IWLL.s.sol:IWLLScript --rpc-url $RPC_URL --slow -vvvv
// forge verify-contract 0x2E6F562E8EbC9af794592ddd2333469D2CBedF28 src/IW_LOST_LEVELS.sol:IW_LOST_LEVELS --constructor-args $(cast abi-encode "constructor(string memory)" "ipfs://bafybeidrm4vuu2qjnswxseypkglzcj3pycue62zpujue7jyxc4gzbl7o5y/") --chain-id 7700 --verifier-url https://tuber.build/api --verifier blockscout --watch

//forge verify-contract 0xEe2e0b8613b7abf926D059dBef392df3dB839fe3 src/Distributor.sol:Distributor --constructor-args $(cast abi-encode "constructor(address, address, address)" 0x2E6F562E8EbC9af794592ddd2333469D2CBedF28 0x12f73617D48b7aab8FE9f2B3b76C55F1055fAa01 0x24757E4b5AD64e6b48d78Dc800D45b4061698757) --chain-id 7700 --verifier-url https://tuber.build/api --verifier blockscout --watch

//bafybeigwbkomquihro3m2xea4obkieomtyyxqiwi5djhyvsfnyc6rddqey