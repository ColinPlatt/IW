// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.15;

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

import "src/ITurnstile.sol";

contract IW is ERC721, Ownable {

    uint256 public nextId;

    string public constant BASE_URI ="ipfs://bafkreicudvmb6uloym3tpku7kxvxsm7g4odj5khrant46ko6fq666f2agm";

    constructor() ERC721("IW", "IW") {
        if(block.chainid == 7700) ITurnstile(0xEcf044C5B4b867CFda001101c617eCd347095B44).assign(60);
    }

    function bulkMint(address[] calldata tos) external onlyOwner {
        uint256 len = tos.length;
        unchecked{
            for(uint256 i = 0; i<len; ++i) {
                _mint(tos[i], nextId);
                nextId++;
            }
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        return BASE_URI;
    }

}