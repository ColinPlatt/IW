// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "src/IW_LOST_LEVELS.sol";

import "src/ITurnstile.sol";

contract Distributor is Ownable {

    uint256 public constant MAX_MINT = 2000;
    uint256 public constant MINT_COST = 200 ether;

    IERC721 public immutable CGRPH;
    IERC721 public immutable IW;
    uint256 public immutable PUBLIC_SALE_OPENING;
    
    IW_LOST_LEVELS public immutable lost;  // we can only set this once, if we mess up we need to redeploy and update the NFT contract
    
    // we group the bools to determine if an NFT has minted from both collections to save storage
    struct EARLY_MINT_TRACKER {
        bool IW_MINTED;
        bool CGRPH_MINTED;
    }

    mapping(uint256 => EARLY_MINT_TRACKER) public earlyMintedByIds;
    mapping(address => uint8) public mintedByAddress;

    uint16[2000] public ids;
    uint16 private index;
    
    constructor(
        address _lost,
        address _cgrph,
        address _iw
    ) {
        PUBLIC_SALE_OPENING = block.timestamp + 1 days;
        lost = IW_LOST_LEVELS(_lost);
        CGRPH = IERC721(_cgrph);
        IW = IERC721(_iw);
        if(block.chainid == 7700) ITurnstile(0xEcf044C5B4b867CFda001101c617eCd347095B44).assign(lost.CSRID());
    }

    // Owner can withdraw CANTO sent to this contract
    function withdraw(uint256 amount) external onlyOwner{
        bool success;
        address to = owner();

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    function _pickPseudoRandomUniqueId(uint256 seed) private returns (uint256 id) {
        uint256 len = ids.length - index++;
        require(len > 0, 'Mint closed');
        uint256 randomIndex = uint256(keccak256(abi.encodePacked(seed, block.timestamp))) % len;
        id = ids[randomIndex] != 0 ? ids[randomIndex] : randomIndex;
        ids[randomIndex] = uint16(ids[len - 1] == 0 ? len - 1 : ids[len - 1]);
        ids[len - 1] = 0;
    }

    function earlyMintIW(uint256 id) public payable {
        require(msg.sender == IW.ownerOf(id), "Caller not owner of Id");
        require(!earlyMintedByIds[id].IW_MINTED, "Already claimed");
        require(msg.value >= MINT_COST, "Insufficient payment");
        mintedByAddress[msg.sender]++;

        earlyMintedByIds[id].IW_MINTED = true;

        lost.mintFromDistributor(msg.sender, _pickPseudoRandomUniqueId(uint160(msg.sender)*id)+1);

    }

    function earlyMintCGRPH(uint256 id) public payable {
        require(msg.sender == CGRPH.ownerOf(id), "Caller not owner of Id");
        require(!earlyMintedByIds[id].CGRPH_MINTED, "Already claimed");
        require(msg.value >= MINT_COST, "Insufficient payment");
        mintedByAddress[msg.sender]++;

        earlyMintedByIds[id].CGRPH_MINTED = true;

        lost.mintFromDistributor(msg.sender, _pickPseudoRandomUniqueId(uint160(msg.sender)*id)+1);

    }

    function publicMint(uint8 amt) public payable {
        // owner not subjected to maxes
        if(msg.sender != owner()){
            require(block.timestamp >= PUBLIC_SALE_OPENING, "Not yet open to public");
            require(amt <= 5 , "Max 5 mints");
            require(mintedByAddress[msg.sender]+amt <= 5, "Max 5 per address");
            require(msg.value >= amt * MINT_COST, "Insufficient payment");
            mintedByAddress[msg.sender] += amt;
        }

        for(uint256 i = 0; i<amt; ++i) {

            lost.mintFromDistributor(msg.sender, _pickPseudoRandomUniqueId(uint160(msg.sender)*i)+1);
        }

    }

}