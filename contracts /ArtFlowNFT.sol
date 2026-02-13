// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ArtFlowNFT is ERC721, ERC2981, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    
    mapping(uint256 => address) public factorContract;
    
    event FactorSet(uint256 indexed tokenId, address indexed escrow);
    
    constructor() ERC721("ArtFlowGenesis", "ARTF") {
        _setDefaultRoyalty(msg.sender, 1000); // 10% default royalty
    }
    
    function safeMint(address to) public onlyOwner returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenRoyalty(tokenId, to, 1000);
        return tokenId;
    }
    
    function setFactorContract(uint256 tokenId, address escrowAddress) external onlyOwner {
        require(factorContract[tokenId] == address(0), "Factor already set");
        factorContract[tokenId] = escrowAddress;
        emit FactorSet(tokenId, escrowAddress);
    }
    
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        public
        view
        virtual
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        (, uint256 amount) = super.royaltyInfo(tokenId, salePrice);
        
        if (factorContract[tokenId] != address(0)) {
            return (factorContract[tokenId], amount);
        }
        
        return super.royaltyInfo(tokenId, salePrice);
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
