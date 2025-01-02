// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./common/AdminBaseUUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interface/INFT.sol";
//import "hardhat/console.sol";


/**
 * @dev L3E7 stake pool contract.
 * @author bingo
 */
contract L3E7Stake is AdminBaseUUPSUpgradeable {
    struct StakeRecord {
        address account;
        uint stakeType;
        uint stakeTime;
        uint stakeTerm;
        uint[] tokenIds;
    }

    enum StakeType {Default, Pool1, Pool2, Pool3, Pool4}

    ///////////////////////////////// constant /////////////////////////////////
    function STAKE_TERM() internal pure returns (uint[3] memory) {
        return [0, uint(3 minutes), 9 minutes];
    }

    ///////////////////////////////// storage /////////////////////////////////
    uint public currentStakeId;
    address public nftWorlds;
    address public nftGuardians;

    mapping (uint => StakeRecord) public stakeRecords;

    ///////////////////////////////// upgrade /////////////////////////////////

    ///////////////////////////////// event /////////////////////////////////
    /**
     * @dev Emitted when stake `tokenIds` NFT into pool `stakeType` with term `stakeTerm` and record id `stakeId`.
     */
    event Stake(StakeType indexed stakeType, uint indexed stakeTerm, uint stakeId, uint[] tokenIds);

    /**
     * @dev Emitted when withdraw `stakeId` record from pool.
     */
    event Withdraw(uint stakeId);

    ///////////////////////////////// error /////////////////////////////////
    /**
     * @dev Error empty input or zero value.
     */
    error ZeroLength();

    /**
     * @dev Error invalid status of token.
     * @param tokenId   token id.
     * @param status    current status of token.
     */
    error InvalidStatus(uint tokenId, uint status);

    /**
     * @dev Error invalid type.
     * @param __type    type.
     * @param index     index of error data.
     */
    error InvalidType(uint __type, uint index);

    /**
     * @dev Error invalid owner.
     * @param tokenId   token id.
     */
    error InvalidOwner(uint tokenId);

    /**
     * @dev Error not exist.
     * @param id    record id.
     */
    error NotExist(uint id);

    /**
     * @dev Error not time.
     * @param time      target time.
     */
    error NotTime(uint time);


    /**
     * @dev initialize
     * @param _worlds    worlds nft address.
     * @param _guardians guardians nft address.
     */
    function initialize(address _worlds, address _guardians) public initializer {
        BaseUUPSUpgradeable.__Base_init();

        nftWorlds = _worlds;
        nftGuardians = _guardians;
    }

    /**
     * @dev stake
     * @param _termType  stake term type - 0: unlimited, 1: 30 days, 2: 90 days.
     * @param _stakeType stake type - 1: worlds*1, 2: guardians*1, 3: guardians*5, 4: w*1 + g*5.
     * @param _tokenIds  token id list.
     */
    function stake(uint _termType, StakeType _stakeType, uint[][] calldata _tokenIds) external notPaused onlyExternal {
        // check token combination
        if (_tokenIds.length == 0) {
            revert ZeroLength();
        }

        // check stake term
        uint term = STAKE_TERM()[_termType];

        // handle stake record
        for (uint i = 0; i < _tokenIds.length; i++) {
            if (_stakeType == StakeType.Pool1) {
                if (_tokenIds[i].length != 1) {
                    revert InvalidType(uint(_stakeType), i);
                }
                _stake(nftWorlds, _tokenIds[i]);
            } else if (_stakeType == StakeType.Pool2) {
                if (_tokenIds[i].length != 1) {
                    revert InvalidType(uint(_stakeType), i);
                }
                _stake(nftGuardians, _tokenIds[i]);
            } else if (_stakeType == StakeType.Pool3) {
                if (_tokenIds[i].length != 5) {
                    revert InvalidType(uint(_stakeType), i);
                }
                _stake(nftGuardians, _tokenIds[i]);
            } else if (_stakeType == StakeType.Pool4) {
                if (_tokenIds[i].length != 6) {
                    revert InvalidType(uint(_stakeType), i);
                }
                uint[] memory worldTokenIds = new uint[](1);
                uint[] memory guardianTokenIds = new uint[](5);
                worldTokenIds[0] = _tokenIds[i][0];
                guardianTokenIds[0] = _tokenIds[i][1];
                guardianTokenIds[1] = _tokenIds[i][2];
                guardianTokenIds[2] = _tokenIds[i][3];
                guardianTokenIds[3] = _tokenIds[i][4];
                guardianTokenIds[4] = _tokenIds[i][5];

                _stake(nftWorlds, worldTokenIds);
                _stake(nftGuardians, guardianTokenIds);
            } else {
                revert InvalidType(uint(_stakeType), i);
            }
            // insert stake record
            uint stakeId = ++currentStakeId;
            stakeRecords[stakeId] = StakeRecord(msg.sender, uint(_stakeType), block.timestamp, term, _tokenIds[i]);

            emit Stake(_stakeType, term, stakeId, _tokenIds[i]);
        }
    }

    /**
     * @dev withdraw
     * @param _ids  stake record id list.
     */
    function withdraw(uint[] calldata _ids) external notPaused onlyExternal {
        for (uint i = 0; i < _ids.length; i++) {
            uint id = _ids[i];
            StakeRecord memory record = stakeRecords[id];
            // check owner
            if (msg.sender != record.account) {
                revert NotExist(id);
            }
//            // check term
//            if (block.timestamp < record.stakeTime + record.stakeTerm) {
//                revert NotTime(record.stakeTime + record.stakeTerm);
//            }
            // delete record
            delete stakeRecords[id];
            // update token status
            StakeType stakeType = StakeType(record.stakeType);
            uint[] memory tokenIds = record.tokenIds;
            if (stakeType == StakeType.Pool1) {
                _withdraw(nftWorlds, tokenIds);
            } else if (stakeType == StakeType.Pool2) {
                _withdraw(nftGuardians, tokenIds);
            } else if (stakeType == StakeType.Pool3) {
                _withdraw(nftGuardians, tokenIds);
            } else if (stakeType == StakeType.Pool4) {
                uint[] memory worldTokenIds = new uint[](1);
                uint[] memory guardianTokenIds = new uint[](5);
                worldTokenIds[0] = tokenIds[0];
                guardianTokenIds[0] = tokenIds[1];
                guardianTokenIds[1] = tokenIds[2];
                guardianTokenIds[2] = tokenIds[3];
                guardianTokenIds[3] = tokenIds[4];
                guardianTokenIds[4] = tokenIds[5];

                _withdraw(nftWorlds, worldTokenIds);
                _withdraw(nftGuardians, guardianTokenIds);
            } else {
                revert InvalidType(uint(stakeType), i);
            }

            emit Withdraw(id);
        }
    }

    /**
     * @dev authWithdraw
     * @param _ids  stake record id list.
     */
    function authWithdraw(uint[] calldata _ids) external onlyAuth {
        for (uint i = 0; i < _ids.length; i++) {
            uint id = _ids[i];
            StakeRecord memory record = stakeRecords[id];
            // check status
            if (address(0) == record.account) {
                revert NotExist(id);
            }
            // delete record
            delete stakeRecords[id];
            // update token status
            StakeType stakeType = StakeType(record.stakeType);
            uint[] memory tokenIds = record.tokenIds;
            if (stakeType == StakeType.Pool1) {
                _withdraw(nftWorlds, tokenIds);
            } else if (stakeType == StakeType.Pool2) {
                _withdraw(nftGuardians, tokenIds);
            } else if (stakeType == StakeType.Pool3) {
                _withdraw(nftGuardians, tokenIds);
            } else if (stakeType == StakeType.Pool4) {
                uint[] memory worldTokenIds = new uint[](1);
                uint[] memory guardianTokenIds = new uint[](5);
                worldTokenIds[0] = tokenIds[0];
                guardianTokenIds[0] = tokenIds[1];
                guardianTokenIds[1] = tokenIds[2];
                guardianTokenIds[2] = tokenIds[3];
                guardianTokenIds[3] = tokenIds[4];
                guardianTokenIds[4] = tokenIds[5];

                _withdraw(nftWorlds, worldTokenIds);
                _withdraw(nftGuardians, guardianTokenIds);
            } else {
                revert InvalidType(uint(stakeType), i);
            }

            emit Withdraw(id);
        }
    }

    function _stake(address _nft, uint[] memory _tokenIds) internal {
        for (uint i = 0; i < _tokenIds.length; i++) {
            uint tokenId = _tokenIds[i];
            // check owner
            if (msg.sender != INFT(_nft).ownerOf(tokenId)) {
                revert InvalidOwner(tokenId);
            }
            INFT.TokenInfo memory ti = INFT(_nft).getTokenInfo(tokenId);
            // check status
            if (ti.status != 0) {
                revert InvalidStatus(tokenId, ti.status);
            }
            // update token status
            ti.status = 1;
            INFT(_nft).update(tokenId, ti);
        }
    }

    function _withdraw(address _nft, uint[] memory _tokenIds) internal {
        for (uint i = 0; i < _tokenIds.length; i++) {
            uint tokenId = _tokenIds[i];
            INFT.TokenInfo memory ti = INFT(_nft).getTokenInfo(tokenId);
            // check status
            if (ti.status != 1) {
                revert InvalidStatus(tokenId, ti.status);
            }
            // update token status
            ti.status = 0;
            INFT(_nft).update(tokenId, ti);
        }
    }

}
