// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./common/AdminBaseUUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interface/INFT.sol";
//import "hardhat/console.sol";


/**
 * @dev L3E7 Mint for wl account
 * @author bingo
 */
contract L3E7Mint is AdminBaseUUPSUpgradeable {
    enum Phase {Default, Lucky, Guaranteed, Claim}

    ///////////////////////////////// constant /////////////////////////////////

    ///////////////////////////////// storage /////////////////////////////////
    address public nft;

    uint public counterLucky;
    uint public counterGuaranteed;
    uint public counterClaim;
    uint public priceLucky;
    uint public priceGuaranteed;

    bytes32 public merkleRootLucky;
    bytes32 public merkleRootGuaranteed;
    bytes32 public merkleRootGoal;

    uint[2] public periodLucky;
    uint[2] public periodGuaranteed;
    uint[2] public periodClaimNFT;

    mapping (address => uint) public settleLucky;
    mapping (address => uint) public settleGuaranteed;
    mapping (address => uint) public settleClaim;
    mapping (address => uint) public balanceOfLucky;
    mapping (address => uint) public balanceOfGuaranteed;

    ///////////////////////////////// upgrade /////////////////////////////////

    ///////////////////////////////// event /////////////////////////////////
    /**
     * @dev Emitted when `account` participate in phase LUCKY and deposit for `amount` NFT.
     */
    event LuckyDeposit(address account, uint amount);

    /**
     * @dev Emitted when `account` participate in phase GUARANTEED and mint `amount` NFT.
     */
    event GuaranteedMint(address account, uint amount);

    /**
     * @dev Emitted when `account` claim `amount` NFT.
     */
    event ClaimNFT(address account, uint amount);


    ///////////////////////////////// error /////////////////////////////////
    /**
     * @dev Error action not active.
     * @param index     custom active index.
     */
    error NotActive(uint index);

    /**
     * @dev Error caller not in whitelist of specify action.
     * @param index     custom active index.
     */
    error NotWhitelist(uint index);

    /**
     * @dev Error caller already invoke of specify action.
     * @param index     custom active index.
     */
    error ExceedInvoke(uint index);

    /**
     * @dev Error msg.value not equal the specify price .
     * @param value     msg.value caller send
     * @param price     target price
     */
    error NEQValue(uint value, uint price);

    /**
     * @dev Error exceed balance of holder.
     * @param holder    holder address.
     * @param balance   current balance amount of holder.
     * @param amount    amount to be transfer.
     */
    error ExceedBalance(address holder, uint balance, uint amount);


    function initialize() public initializer {
        BaseUUPSUpgradeable.__Base_init();

        // todo
        priceLucky = 0.0002 ether;
        priceGuaranteed = 0.0005 ether;
    }

    /**
     * @dev set nft contract address.
     * only invoked by admin account
     */
    function setNFT(address _value) external onlyAdmin {
        nft = _value;
    }

    /**
     * @dev set new price of phase LUCKY.
     * only invoked by admin account
     */
    function setPriceLucky(uint _value) external onlyAdmin {
        priceLucky = _value;
    }

    /**
     * @dev set new price of phase GUARANTEED.
     * only invoked by admin account
     */
    function setPriceGuaranteed(uint _value) external onlyAdmin {
        priceGuaranteed = _value;
    }

    /**
     * @dev set new merkleRoot for lucky whitelist.
     * only invoked by admin account
     */
    function setMerkleRootLucky(bytes32 _value) external onlyAdmin {
        merkleRootLucky = _value;
    }

    /**
     * @dev set new merkleRoot for guaranteed whitelist.
     * only invoked by admin account
     */
    function setMerkleRootGuaranteed(bytes32 _value) external onlyAdmin {
        merkleRootGuaranteed = _value;
    }

    /**
     * @dev set new merkleRoot for goal whitelist.
     * only invoked by admin account
     */
    function setMerkleRootGoal(bytes32 _value) external onlyAdmin {
        merkleRootGoal = _value;
    }

    /**
     * @dev set startTime & endTime for phase LUCKY.
     * only invoked by admin account
     */
    function setPeriodLucky(uint[2] memory _value) external onlyAdmin {
        periodLucky = _value;
    }

    /**
     * @dev set startTime & endTime for phase GUARANTEED.
     * only invoked by admin account
     */
    function setPeriodGuaranteed(uint[2] memory _value) external onlyAdmin {
        periodGuaranteed = _value;
    }

    /**
     * @dev set startTime & endTime for phase CLAIM.
     * only invoked by admin account
     */
    function setPeriodClaimNFT(uint[2] memory _value) external onlyAdmin {
        periodClaimNFT = _value;
    }

    /**
     * @dev batch return ether to the account not goal.
     * @param _addresses    array of address to sent
     * @param _amounts      array of amount to sent
     */
    function batchReturn(address[] calldata _addresses, uint[] calldata _amounts) external payable onlyAdmin {
        for (uint i = 0; i < _addresses.length; i++) {
            // check balanceOf account. (make sure either all done or all fail)
            if (_amounts[i] > balanceOfLucky[_addresses[i]]) {
                revert ExceedBalance(_addresses[i], balanceOfLucky[_addresses[i]], _amounts[i]);
            }
            // update account balanceOf
            balanceOfLucky[_addresses[i]] -= _amounts[i];

            payable(_addresses[i]).transfer(_amounts[i]);
        }
    }


    /**
     * @dev get all the period timeStamp
     */
    function getPeriod() public view returns (uint luckyStartTime, uint luckyEndTime, uint guaranteedStartTime, uint guaranteedEndTime, uint claimStartTime, uint claimEndTime) {
        luckyStartTime = periodLucky[0];
        luckyEndTime = periodLucky[1];
        guaranteedStartTime = periodGuaranteed[0];
        guaranteedEndTime = periodGuaranteed[1];
        claimStartTime = periodClaimNFT[0];
        claimEndTime = periodClaimNFT[1];
    }

    /**
     * @dev deposit by lucky whitelist account
     */
    function luckyDeposit(bytes32[] calldata _proof, uint _amount, uint _invokeTimes) external payable notPaused {
        uint activeIndex = uint(Phase.Lucky);
        // check active period
        if (block.timestamp < periodLucky[0] || block.timestamp > periodLucky[1]) {
            revert NotActive(activeIndex);
        }
        // check whitelist account
        if (!_verifyWhitelist(_proof, merkleRootLucky, msg.sender, _amount)) {
            revert NotWhitelist(activeIndex);
        }
        // check participate status
        if (0 == _invokeTimes || _amount < settleLucky[msg.sender] + _invokeTimes) {
            revert ExceedInvoke(activeIndex);
        }
        // check price
        if (msg.value != priceLucky * _invokeTimes) {
            revert NEQValue(msg.value, priceLucky * _invokeTimes);
        }

        // update participate status
        settleLucky[msg.sender] += _invokeTimes;
        // update account balanceOf
        balanceOfLucky[msg.sender] += msg.value;
        // update counter
        counterLucky += _invokeTimes;

        emit LuckyDeposit(msg.sender, _invokeTimes);
    }

    /**
     * @dev mint by guaranteed whitelist account
     # @param _amount   amount of nft caller can mint
     */
    function guaranteedMint(bytes32[] calldata _proof, uint _amount, uint _invokeTimes) external payable notPaused {
        uint activeIndex = uint(Phase.Guaranteed);
        // check active period
        if (block.timestamp < periodGuaranteed[0] || block.timestamp > periodGuaranteed[1]) {
            revert NotActive(activeIndex);
        }
        // check whitelist account
        if (!_verifyWhitelist(_proof, merkleRootGuaranteed, msg.sender, _amount)) {
            revert NotWhitelist(activeIndex);
        }
        // check participate status
        if (0 == _invokeTimes || _amount < settleGuaranteed[msg.sender] + _invokeTimes) {
            revert ExceedInvoke(activeIndex);
        }
        // check price
        if (msg.value != priceGuaranteed * _invokeTimes) {
            revert NEQValue(msg.value, priceGuaranteed * _invokeTimes);
        }

        // update participate status
        settleGuaranteed[msg.sender] += _invokeTimes;
        // update account balanceOf
        balanceOfGuaranteed[msg.sender] += msg.value;
        // update counter
        counterGuaranteed += _invokeTimes;

        // mint NFT
        INFT(nft).batchMint(msg.sender, _invokeTimes);

        emit GuaranteedMint(msg.sender, _invokeTimes);
    }

    /**
     * @dev claim NFT by goal whitelist account
     */
    function claimNFT(bytes32[] calldata _proof, uint _amount, uint _invokeTimes) external notPaused {
        uint activeIndex = uint(Phase.Claim);
        // check active period
        if (block.timestamp < periodClaimNFT[0] || block.timestamp > periodClaimNFT[1]) {
            revert NotActive(activeIndex);
        }
        // check whitelist account
        if (!_verifyWhitelist(_proof, merkleRootGoal, msg.sender, _amount)) {
            revert NotWhitelist(activeIndex);
        }
        // check participate status
        if (0 == _invokeTimes || _amount < settleClaim[msg.sender] + _invokeTimes) {
            revert ExceedInvoke(activeIndex);
        }
        if (settleLucky[msg.sender] < settleClaim[msg.sender] + _invokeTimes) {
            revert ExceedInvoke(activeIndex);
        }

        // update claim status
        settleClaim[msg.sender] += _invokeTimes;
        // update counter
        counterClaim += _invokeTimes;

        // mint NFT
        INFT(nft).batchMint(msg.sender, _invokeTimes);

        emit ClaimNFT(msg.sender, _invokeTimes);
    }


    function _verifyWhitelist(bytes32[] calldata _proof, bytes32 _merkleRoot, address _account, uint _amount) internal pure returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_account, _amount));
        return MerkleProof.verifyCalldata(_proof, _merkleRoot, leaf);
    }

    receive() external payable {}

}
