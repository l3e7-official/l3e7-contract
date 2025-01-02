// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./common/BaseUUPSUpgradeable.sol";
import "./interface/INFT.sol";
//import "hardhat/console.sol";


/**
 * @dev airdrop NFT
 * @author bingo
 */
contract AirdropNFT is BaseUUPSUpgradeable {
    ///////////////////////////////// constant /////////////////////////////////

    ///////////////////////////////// storage /////////////////////////////////

    ///////////////////////////////// upgrade /////////////////////////////////

    ///////////////////////////////// event /////////////////////////////////

    ///////////////////////////////// error /////////////////////////////////

    function initialize() public initializer {
        BaseUUPSUpgradeable.__Base_init();

    }

    function batchMint(address _nft, address[] calldata _recipients, uint[] calldata _tokenAmounts) external onlyAuth {
        for (uint i = 0; i < _recipients.length; i++) {
            INFT(_nft).batchMint(_recipients[i], _tokenAmounts[i]);
        }
    }

    function batchMintAmount(address _nft, address[] calldata _recipients, uint _tokenAmount) external onlyAuth {
        for (uint i = 0; i < _recipients.length; i++) {
            INFT(_nft).batchMint(_recipients[i], _tokenAmount);
        }
    }
}
