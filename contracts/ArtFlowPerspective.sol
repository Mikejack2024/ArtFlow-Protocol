// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import "./ArtFlowNFT.sol";
import "./RoyaltyAdvanceEscrow.sol";

/**
 * @title ArtFlowPerspective
 * @notice Attestation oracle for ArtFlow-compliant factoring contracts
 * @dev Proprietary verification layer. Held by Governing Body.
 */
contract ArtFlowPerspective {
    mapping(address => bool) public verified;
    mapping(address => uint256) public verificationTimestamp;
    
    event ContractVerified(address indexed contractAddress, uint256 timestamp);
    
    function verify(address escrowAddress) external returns (bool) {
        RoyaltyAdvanceEscrow escrow = RoyaltyAdvanceEscrow(escrowAddress);
        
        require(escrow.upfrontAmount() > 0, "Invalid advance");
        require(escrow.capAmount() > escrow.upfrontAmount(), "Invalid cap");
        
        ArtFlowNFT nft = escrow.nftContract();
        require(nft.supportsInterface(0x2a55205a), "Not ERC2981");
        require(nft.factorContract(escrow.tokenId()) == escrowAddress, "Not registered");
        
        verified[escrowAddress] = true;
        verificationTimestamp[escrowAddress] = block.timestamp;
        emit ContractVerified(escrowAddress, block.timestamp);
        return true;
    }
    
    function isVerified(address escrowAddress) external view returns (bool) {
        return verified[escrowAddress];
    }
    
    function getVerificationTimestamp(address escrowAddress) external view returns (uint256) {
        return verificationTimestamp[escrowAddress];
    }
}
