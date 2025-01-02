// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @dev airdrop ether & token
 * @author bingo
 */
contract Airdrop {
    using SafeERC20 for IERC20;

    /**
     * batch transfer for ERC20 token.(the same amount)
     *
     * @param _contractAddress ERC20 token address
     * @param _addresses array of address to sent
     * @param _value transfer amount
     */
    function batchTransferToken(address _contractAddress, address[] memory _addresses, uint _value) public {
        // transfer circularly
        for (uint i = 0; i < _addresses.length; i++) {
            IERC20(_contractAddress).safeTransferFrom(msg.sender, _addresses[i], _value);
        }
    }

    /**
     * batch transfer for ERC20 token.(specify amount)
     *
     * @param _contractAddress ERC20 token address
     * @param _addresses array of address to sent
     * @param _values array of transfer amount
     */
    function batchTransferToken2(address _contractAddress, address[] memory _addresses, uint[] memory _values) public {
        // transfer circularly
        for (uint i = 0; i < _addresses.length; i++) {
            IERC20(_contractAddress).safeTransferFrom(msg.sender, _addresses[i], _values[i]);
        }
    }

    /**
     * batch transfer ether.(the same amount)
     *
     * @param _addresses array of address to sent
     */
    function batchTransfer(address[] memory _addresses, uint _value) public payable {
        for (uint i = 0; i < _addresses.length; i++) {
            payable(_addresses[i]).transfer(_value);
        }
    }

    /**
     * batch transfer ether.(specify amount)
     *
     * @param _addresses array of address to sent
     * @param _values array of transfer amount
     */
    function batchTransfer2(address[] memory _addresses, uint[] memory _values) public payable {
        for (uint i = 0; i < _addresses.length; i++) {
            payable(_addresses[i]).transfer(_values[i]);
        }
    }

}
