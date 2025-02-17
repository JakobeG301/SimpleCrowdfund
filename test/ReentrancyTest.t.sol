//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {Test, Vm} from "lib/forge-std/src/Test.sol";
import {SimpleCrowdfund} from "../src/SimpleCrowdfund.sol";
import {AttackersContract} from "../test/contracts/AttackersContract.sol";

contract AttackersContractTest is Test{

    SimpleCrowdfund simpleCrowdfund;
    AttackersContract attackersContract;

    uint256 contractBalance;

    function checkBalance() internal returns (uint256) {
        contractBalance = address(simpleCrowdfund).balance;
    }

    function setUp() external {
        address _owner = address(this);
        uint256 _secToComplete = 30;
        uint256 _goal = 10e18;

        simpleCrowdfund = new SimpleCrowdfund(_owner, _secToComplete, _goal);
        attackersContract = new AttackersContract(address(simpleCrowdfund));

        checkBalance();
        vm.recordLogs();
    }


    function test_ReentrancyAttack() public{
        
        vm.recordLogs();
        //deploy simpleCrowdfund
        //deploy attackersCrowdfund
  
        //make first contribution
        vm.deal(address(1), 100 ether);
        vm.deal(address(2), 100 ether);
        vm.deal(address(attackersContract), 100 ether);

        vm.prank(address(1));
        simpleCrowdfund.contribute{value: 2 ether}();
        checkBalance();
        //make second contribution
        vm.prank(address(2));
        simpleCrowdfund.contribute{value: 2 ether}();
        checkBalance();

        //make contribution by attacker thu AttackerContract
        vm.prank(address(attackersContract));
        attackersContract.PreperationAttack();
        checkBalance();

        //timetravel
        vm.warp(simpleCrowdfund.i_deadline() + 100);
        
        //refund by attacker
        vm.expectRevert();
        attackersContract.StartAttack();

        assertEq(contractBalance, 5 ether, "there should be 5 ether left!");

        //check if attacker drained all the funds
        vm.prank(address(1));
        simpleCrowdfund.refund();
        checkBalance();

        assertEq(contractBalance, 3 ether, "there should be 3 ether left!");


        Vm.Log[] memory records = vm.getRecordedLogs();
        assertEq(records.length, 4, "Wrong number of events");
    }
}