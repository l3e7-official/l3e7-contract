// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


library Constants {
    address payable constant BURN_ADDRESS = payable(0x000000000000000000000000000000000000dEaD);

    uint constant C1_ID = 210001;

    function C1_IDS() internal pure returns (uint[] memory res) {
        uint[3] memory const = [uint(210001), 210002, 210003];
        res = new uint[](const.length);
        for (uint i = 0; i < res.length; i++) {res[i] = const[i];}
    }

}