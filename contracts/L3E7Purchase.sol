// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./common/AdminBaseUUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";


/**
 * @dev L3E7 purchase contract.
 * @author bingo
 */
contract L3E7Purchase is AdminBaseUUPSUpgradeable {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    ///////////////////////////////// constant /////////////////////////////////

    ///////////////////////////////// storage /////////////////////////////////
    address public signerAddress;

    mapping (bytes32 => bool) existedSignature;

    ///////////////////////////////// upgrade /////////////////////////////////

    ///////////////////////////////// event /////////////////////////////////
    /**
     * @dev Emitted when purchase by `token` with amount `amount` and order id `oid`.
     */
    event Purchase(address indexed token, uint indexed oid, uint amount);

    ///////////////////////////////// error /////////////////////////////////
    /**
     * @dev Error empty input or zero value.
     */
    error ZeroValue();

    /**
     * @dev Error invalid signature.
     */
    error InvalidSignature();

    /**
     * @dev Error existed signature.
     */
    error ExistedSignature();


    /**
     * @dev initialize
     */
    function initialize() public initializer {
        BaseUUPSUpgradeable.__Base_init();

    }

    /**
     * @dev set signer address
     * only invoked by admin account
     */
    function setSignerAddress(address _value) external onlyAdmin {
        signerAddress = _value;
    }

    /**
     * @dev purchase
     * @param _token        token address.
     * @param _amount       token amount.
     * @param _oid          order id.
     * @param _signature    signature of this purchase tx.
     */
    function purchase(address _token, uint _amount, uint _oid, bytes calldata _signature) external notPaused onlyExternal {
        if (address(0) == _token || 0 == _amount || 0 == _oid) {
            revert ZeroValue();
        }

        // check signature
        bytes32 digest = keccak256(abi.encodePacked(_token, _amount, _oid, msg.sender));
        if (existedSignature[digest]) {
            revert ExistedSignature();
        }
        bytes32 ethSignedMsgHash = MessageHashUtils.toEthSignedMessageHash(digest);
        if (ethSignedMsgHash.recover(_signature) != signerAddress) {
            revert InvalidSignature();
        }
        existedSignature[digest] = true;

        // transfer token
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        emit Purchase(_token, _oid, _amount);
    }

}
