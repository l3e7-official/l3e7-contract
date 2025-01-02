// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./common/BaseUUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
//import "hardhat/console.sol";


/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
contract L3E7Guardians is ERC2981Upgradeable, ERC721Upgradeable, BaseUUPSUpgradeable {
    using Address for address;
    using Strings for uint256;

    struct TokenInfo {
        uint tokenId;
        uint status;            // status - 0: default, 1: staked
    }

    ///////////////////////////////// constant /////////////////////////////////
    uint public constant MAX_SUPPLY = 5000;

    ///////////////////////////////// storage /////////////////////////////////
    uint internal _currentTokenId;

    string public baseURI;
    string public baseExtension;
    
    bool private _isActive;
    mapping(address => bool) private _authTransfer;

    ///////////////////////////////// upgrade /////////////////////////////////
    mapping(uint => TokenInfo) public _tokenInfoOf;

    ///////////////////////////////// event /////////////////////////////////
    event Update(address indexed oprator, uint indexed tokenId, TokenInfo oldTokenInfo, TokenInfo newTokenInfo);

    ///////////////////////////////// error /////////////////////////////////
    /**
     * @dev Error totalSupply exceed MAX_SUPPLY.
     */
    error MaxSupplyExceeded();
    /**
     * @dev Error project not active yet.
     */
    error ProjectNotActive();
    /**
     * @dev Error transfer status disable.
     * @param tokenId   tokenId
     * @param status    status
     */
    error TransferStatusDisable(uint tokenId, uint status);



    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function initialize(string memory name_, string memory symbol_) public initializer {
        BaseUUPSUpgradeable.__Base_init();
        ERC721Upgradeable.__ERC721_init(name_, symbol_);

        _setDefaultRoyalty(msg.sender, 500);
    }

    modifier isActive() {
        if (!_isActive && !_authTransfer[msg.sender]) {
            revert ProjectNotActive();
        }
        _;
    }

    /**
     * @dev set baseURI for nft tokenURI.
     * only invoked by admin account
     */
    function setBaseURI(string memory _value) external onlyAdmin {
        baseURI = _value;
    }

    /**
     * @dev set baseExtension for nft tokenURI.
     * only invoked by admin account
     */
    function setBaseExtension(string memory _value) external onlyAdmin {
        baseExtension = _value;
    }

    /**
     * @dev set defaultRoyalty for nft.
     * only invoked by admin account
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyAdmin {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev set tokenRoyalty for specify tokenId.
     * only invoked by admin account
     */
    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external onlyAdmin {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev set active status for nft `approve` & `transfer` limit.
     * only invoked by admin account
     */
    function setIsActive(bool _value) external onlyAdmin {
        _isActive = _value;
    }

    /**
     * @dev set exception for nft `approve` & `transfer` limit.
     * only invoked by admin account
     */
    function setAuthTransfer(address _index, bool _value) external onlyAdmin {
        _authTransfer[_index] = _value;
    }

    ///////////////////////////////// override /////////////////////////////////

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC2981Upgradeable, ERC721Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _currentTokenId;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension)) : "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override isActive {
        super.approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public override isActive {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override isActive {
        uint mask = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        TokenInfo memory tokenInfo = getTokenInfo(tokenId);
        if (tokenInfo.status ^ mask != type(uint).max) {
            revert TransferStatusDisable(tokenId, tokenInfo.status);
        }

        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev get currentTokenId of nft.
     */
    function currentTokenId() public view returns (uint) {
        return _currentTokenId;
    }

    function getTokenInfo(uint _tokenId) public view returns (TokenInfo memory tokenInfo) {
        _requireOwned(_tokenId);
        tokenInfo = _tokenInfoOf[_tokenId];
        tokenInfo.tokenId = _tokenId;
    }

    function getTokenInfos(uint[] memory _tokenIds) public view returns (TokenInfo[] memory) {
        TokenInfo[] memory tokenInfos = new TokenInfo[](_tokenIds.length);
        for (uint i = 0; i < _tokenIds.length; i++) {
            tokenInfos[i] = getTokenInfo(_tokenIds[i]);
        }

        return tokenInfos;
    }

    /**
     * @dev mint one nft
     */
    function mint(address _to) external onlyAuth returns (uint) {

        uint tokenId = _mintOne(_to);

        return tokenId;
    }

    /**
     * @dev batch mint
     */
    function batchMint(address _to, uint _amount) external onlyAuth returns (bool) {

        for (uint i = 0; i < _amount; i++) {
            _mintOne(_to);
        }

        return true;
    }

    /**
     * @dev update tokenInfo by _tokenId
     */
    function update(uint _tokenId, TokenInfo memory _tokenInfo) external onlyAuth returns (bool) {
        _checkAuthorized(ownerOf(_tokenId), msg.sender, _tokenId);
        TokenInfo memory tokenInfo = _tokenInfoOf[_tokenId];
        _tokenInfoOf[_tokenId] = _tokenInfo;

        emit Update(msg.sender, _tokenId, tokenInfo, _tokenInfo);

        return true;
    }

    /**
     * @dev mint ont nft
     */
    function _mintOne(address _to) internal returns (uint) {
        // gen tokenId and increase `_currentTokenId`
        uint tokenId = ++_currentTokenId;
        _mint(_to, tokenId);

        // check `MAX_SUPPLY` limit
        if (MAX_SUPPLY < totalSupply()) { revert MaxSupplyExceeded(); }

        return tokenId;
    }

}
