// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


/**
 * @dev TRequired interface of an ERC721 compliant contract.
 * @author bingo
 */
interface INFT is IERC721 {
    struct TokenInfo {
        uint tokenId;
        uint status;            // status - 0: default, 1: staked
    }

    function currentTokenId() external view returns (uint);
    function getTokenInfo(uint _tokenId) external view returns (TokenInfo memory);
    function getTokenInfos(uint[] memory _tokenIds) external view returns (TokenInfo[] memory);
    function mint(address _to) external returns (uint);
    function batchMint(address _to, uint _amount) external returns (bool);
    function update(uint _tokenId, TokenInfo memory _tokenInfo) external returns (bool);

}
