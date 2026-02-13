 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./ArtFlowNFT.sol";

contract RoyaltyAdvanceEscrow is Ownable {
    using Address for address payable;
    
    uint256 public immutable tokenId;
    ArtFlowNFT public immutable nftContract;
    address payable public immutable artist;
    address payable public immutable factor;
    uint256 public immutable upfrontAmount;
    uint256 public immutable capAmount;
    
    uint256 public totalRoyaltiesCollected;
    bool public capReached;
    bool public advancePaid;
    
    event AdvancePaid(address factor, uint256 amount);
    event RoyaltyCollected(uint256 amount, uint256 totalSoFar);
    event CapReached(uint256 totalCollected);
    
    constructor(
        address _nftContract,
        uint256 _tokenId,
        address payable _artist,
        address payable _factor,
        uint256 _upfrontAmount,
        uint256 _capAmount
    ) Ownable(msg.sender) {
        require(_upfrontAmount > 0, "Advance must be >0");
        require(_capAmount > _upfrontAmount, "Cap must exceed advance");
        
        nftContract = ArtFlowNFT(_nftContract);
        tokenId = _tokenId;
        artist = _artist;
        factor = _factor;
        upfrontAmount = _upfrontAmount;
        capAmount = _capAmount;
        
        nftContract.setFactorContract(tokenId, address(this));
    }
    
    function payAdvance() external payable {
        require(msg.sender == factor, "Only factor");
        require(msg.value == upfrontAmount, "Incorrect amount");
        require(!advancePaid, "Already paid");
        
        advancePaid = true;
        artist.sendValue(upfrontAmount);
        emit AdvancePaid(factor, upfrontAmount);
    }
    
    receive() external payable {
        require(address(nftContract) == msg.sender, "Only NFT contract");
        require(advancePaid, "Advance not paid");
        require(!capReached, "Cap already reached");
        
        totalRoyaltiesCollected += msg.value;
        emit RoyaltyCollected(msg.value, totalRoyaltiesCollected);
        
        if (totalRoyaltiesCollected >= capAmount) {
            capReached = true;
            emit CapReached(totalRoyaltiesCollected);
            
            uint256 excess = totalRoyaltiesCollected - capAmount;
            if (excess > 0) {
                artist.sendValue(excess);
            }
        }
    }
    
    function withdrawRoyalties() external {
        require(msg.sender == factor, "Only factor");
        require(totalRoyaltiesCollected > 0, "No royalties");
        
        uint256 withdrawable = capReached ? capAmount : totalRoyaltiesCollected;
        uint256 balance = address(this).balance;
        uint256 toWithdraw = balance < withdrawable ? balance : withdrawable;
        
        require(toWithdraw > 0, "Zero balance");
        factor.sendValue(toWithdraw);
    }
    
    fallback() external payable {
        receive();
    }
}
