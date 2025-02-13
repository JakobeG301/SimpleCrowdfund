// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {Test, Vm, console} from "lib/forge-std/src/Test.sol";
import {SimpleCrowdfund} from "../src/SimpleCrowdfund.sol";

contract SimpleCrowdfundTest is Test {
    SimpleCrowdfund simpleCrowdfund;

    uint256 contractBalance;

    function checkBalance() internal returns (uint256) {
        contractBalance = address(simpleCrowdfund).balance;
    }

    function setUp() external {
        address _owner = address(this);
        uint256 _secToComplete = 30;
        uint256 _GOAL = 2e18;

        simpleCrowdfund = new SimpleCrowdfund(_owner, _secToComplete, _GOAL);

        checkBalance();
        vm.recordLogs();
    }

    function test_minimalAmountIsSet() public {
        assertEq(simpleCrowdfund.timePassed(), false);
    }

    function test_OwnerisMsgSender() public {
        console.log(simpleCrowdfund.i_owner());
        console.log(address(this));
        assertEq(simpleCrowdfund.i_owner(), address(this));
    }

    /*/////////////////////////////////////////////////////////////////////////////
                                    Deploy Section
    /////////////////////////////////////////////////////////////////////////////*/

    function test_Deploy() public {
        // Scenario: Deploying the contract
        //  Given the contract is deployed with Bob's address, i_secToComplete = 1 day, goal = 2 ETH
        //  Then the owner should be Bob
        //  And the value of the smartcontract should be 0 ETH
        //  And the deadline should be 1 day from now
        //  And the goal should be 2 ETH
        //  And the amountRaised in the contract should be 0 ETH
        //  And the goalReached should be false
        //  And the fundsWithdrawned should be false
        //  And the minimalAmount should be 0.001 ETH
        //  And the ContributorsList should be empty
        vm.deal(address(2), 100e18);
        vm.recordLogs();
        console.log("balance:", contractBalance);
        address _owner = address(this);

        assertEq(simpleCrowdfund.i_owner(), _owner);
        console.log("balance:", contractBalance);
        assertEq(contractBalance, 0);
        console.log("secondsToComplete:", simpleCrowdfund.i_secToComplete());
        console.log("timeInitiation:", simpleCrowdfund.i_timeInitiation());
        console.log("deadline:", simpleCrowdfund.i_deadline());
        assertEq(simpleCrowdfund.i_deadline(), simpleCrowdfund.i_secToComplete() + block.timestamp);
        assertEq(simpleCrowdfund.GOAL(), 2e18);
        assertEq(contractBalance, 0);
        assertEq(simpleCrowdfund.goalReached(), false);
        assertEq(simpleCrowdfund.fundsWithdrawned(), false);
        console.log("minimal amount", simpleCrowdfund.MINIMAL_AMOUNT());
        assertEq(simpleCrowdfund.MINIMAL_AMOUNT(), 1e15);
        // assertEq(simpleCrowdfund.getContributorsCount(), 0);
        console.log(simpleCrowdfund.GetContributorsListLength());
        Vm.Log[] memory entiries = vm.getRecordedLogs();
        assertEq(entiries.length, 0, "Expected some events");
    }

    function test_DeployWithZeroAddress() public {
        // Scenario: Deploying the contract with a zero address
        //  Given the contract is deployed with zero address, i_secToComplete = 1 day, goal = 2 ETH
        //  Then the transaction should revert with SimpleCrowdfund__ZeroAddress() error
        //  And the deployment should fail

        console.log(address(0));
        vm.expectRevert(SimpleCrowdfund.SimpleCrowdfund__ZeroAddress.selector);
        simpleCrowdfund = new SimpleCrowdfund(address(0), 30, 2e18);
    }

    function test_AddToContributorList() public {
        vm.recordLogs();

        console.log("MINIMAL_AMOUNT:", simpleCrowdfund.MINIMAL_AMOUNT());
        console.log("Current goal reached:", simpleCrowdfund.goalReached());
        console.log("Funds withdrawn:", simpleCrowdfund.fundsWithdrawned());
        console.log("Time passed:", simpleCrowdfund.timePassed());

        vm.deal(address(2), 100e18);

        console.log("Array length1:", simpleCrowdfund.GetContributorsListLength());
        vm.prank(address(2));
        simpleCrowdfund.contribute{value: 1 ether}();
        checkBalance();

        console.log("MINIMAL_AMOUNT:", simpleCrowdfund.MINIMAL_AMOUNT());
        console.log("Current goal reached:", simpleCrowdfund.goalReached());
        console.log("Funds withdrawn:", simpleCrowdfund.fundsWithdrawned());
        console.log("Time passed:", simpleCrowdfund.timePassed());

        assertEq(simpleCrowdfund.GetContributorToAmount(address(2)) == 1 ether, true, "Value is not mapped!");
        console.log("Amount mapped:", simpleCrowdfund.GetContributorToAmount(address(2)));

        // SimpleCrowdfund(payable(address(simpleCrowdfund))).contribute{value: 0.001 ether}();
        console.log("Array length:", simpleCrowdfund.GetContributorsListLength());

        //(bool success,) = payable(address(simpleCrowdfund)).call{value: 0.001 ether}(""); //Triggering receive function
        Vm.Log[] memory records = vm.getRecordedLogs();
    }

    /*/////////////////////////////////////////////////////////////////////////////
                                    Contribute Section
    /////////////////////////////////////////////////////////////////////////////*/

    function test_SendByReceive() public {
        // to do: And the contribution mapping for Robert should be 0.001 ETH
        // Scenario: Contributing through the receive function
        // Given the contract is deployed with Bob's address, goal = 2 ETH, deadline is in 1 day and minimalAmount = 0.001 ETH
        // And the Robert has 100 ETH in his wallet
        // When Robert sends 0.001 ETH to the contract with no data
        // Then the amountRaised in the contract should be 0.001 ETH
        // And the contribution mapping for Robert should be 0.001 ETH
        // And the contract should log a "Contributed" event with (Robert, 0.001 ETH)

        vm.deal(address(2), 100e18);
        vm.recordLogs();
        simpleCrowdfund = new SimpleCrowdfund(address(1), 30, 2e18);
        console.log("Contract balance Before:", contractBalance);
        vm.deal(address(2), 100e18);
        vm.prank(address(2));

        (bool success,) = payable(address(simpleCrowdfund)).call{value: 0.001 ether}("");
        checkBalance();
        console.log("Contract balance After:", contractBalance);
        console.log("Robert balance:", address(2).balance);
        // console.log( "Array length4:",simpleCrowdfund.GetContributorsListLength());
        // assertEq(simpleCrowdfund.GetContributorsListLength(), 1, "its not 1");
        Vm.Log[] memory records = vm.getRecordedLogs();
        console.log("records length:", records.length);
        assertEq(records.length, 1, "Different than 1");
        assertEq(contractBalance, 0.001 ether);

        assertEq(simpleCrowdfund.GetContributorToAmount(address(2)) == 0.001 ether, true, "Value is not mapped!");
        console.log("Amount mapped:", simpleCrowdfund.GetContributorToAmount(address(2)));

        assertEq(contractBalance, 0.001 ether);
    }

    function test_SendLessThanMinimumByReceive() public {
        // to do: And the contribution mapping for Robert should be 0 ETH
        // Scenario: Contributing through the receive function
        // Given the contract is deployed with Bob's address, goal = 2 ETH, deadline is in 1 day and minimalAmount = 0.001 ETH
        // And the Robert has 100 ETH in his wallet
        // When Robert sends 0.0001 ETH to the contract with no data
        // Then the transaction should revert with SimpleCrowdfund__ToLittleDonation() error
        // And the amountRaised in the contract remains 0 ETH
        // And the contribution mapping for Robert should be 0 ETH
        // And the contract should not log a "Contributed" event
        vm.deal(address(2), 100e18);
        vm.recordLogs();
        simpleCrowdfund = new SimpleCrowdfund(address(1), 3600 * 24, 2e18);
        vm.deal(address(2), 100 ether);
        vm.prank(address(2));
        vm.expectRevert(SimpleCrowdfund.SimpleCrowdfund__ToLittleDonation.selector);
        (bool success,) = payable(address(simpleCrowdfund)).call{value: 0.0001 ether}("");
        checkBalance();
        Vm.Log[] memory records = vm.getRecordedLogs();
        assertEq(contractBalance, 0, "Balance should be 0 ETH");
        assertEq(simpleCrowdfund.GetContributorToAmount(address(2)) == 0 ether, true, "Value is mapped!");
        console.log("Amount mapped:", simpleCrowdfund.GetContributorToAmount(address(2)));
        assertEq(records.length, 0, "Event was emited!");
        assertEq(contractBalance, 0, "Amount raised is more than 0");
    }

    function test_SendByFallback() public {
        // Scenario: Contributing through the fallback function
        // Given the contract is deployed with Bob's address, goal = 2 ETH, deadline is in 1 day and minimalAmount = 0.001 ETH
        // And the Robert has 100 ETH in his wallet
        // When Robert sends 0.001 ETH to the contract with not matching function signature
        // Then the amountRaised in the contract should be 0.001 ETH
        // And the contribution mapping for Robert should be 0.001 ETH
        // And the contract should log a "Contributed" event with (Robert, 0.001 ETH)

        vm.recordLogs();
        simpleCrowdfund = new SimpleCrowdfund(address(1), 3600, 2e18);
        vm.deal(address(2), 100 ether);
        vm.prank(address(2));
        (bool success,) = payable(address(simpleCrowdfund)).call{value: 0.001 ether}("0x12");
        console.log("a2", address(2));
        checkBalance();
        assertEq(success, true, "Transaction failed");
        Vm.Log[] memory records = vm.getRecordedLogs();
        assertEq(contractBalance, 0.001 ether, "Balance should be 0.001 ether");
        console.log("mapping for Robert:", simpleCrowdfund.GetContributorToAmount(address(2)));
        assertEq(simpleCrowdfund.GetContributorToAmount(address(2)) == 0.001 ether, true, "Value is not mapped!");
        console.log("Amount mapped:", simpleCrowdfund.GetContributorToAmount(address(2)));
        assertEq(records.length, 1, "Event was not emited!");
        assertEq(contractBalance, 0.001 ether, "Amount raised is not the 0.001 ether");
    }

    function test_SendLessThanMinimumByFallback() public {
        // Scenario: Contributing through the fallback function with less than minimum amount
        // Given the contract is deployed with Bob's address, goal = 2 ETH, deadline is in 1 day and minimalAmount = 0.001 ETH
        // And the Robert has 100 ETH in his wallet
        // When Robert sends 0.0001 ETH to the contract with not matching function signature
        // Then the transaction should revert with SimpleCrowdfund__ToLittleDonation() error
        // And the amountRaised in the contract remains 0 ETH
        // And the contribution mapping for Robert should be 0 ETH
        // And the contract should not log a "Contributed" event

        vm.deal(address(2), 100e18);
        vm.recordLogs();
        simpleCrowdfund = new SimpleCrowdfund(address(1), 3600, 2e18);
        vm.deal(address(2), 100 ether);
        vm.prank(address(2));
        vm.expectRevert(SimpleCrowdfund.SimpleCrowdfund__ToLittleDonation.selector);
        payable(address(simpleCrowdfund)).call{value: 0 ether}("0x12");
        checkBalance();
        console.log("Contract balance After:", contractBalance);
        Vm.Log[] memory records = vm.getRecordedLogs();
        assertEq(contractBalance, 0 ether, "Balance should be 0 ether");
        assertEq(simpleCrowdfund.GetContributorToAmount(address(2)) == 0 ether, true, "Value is mapped!");
        console.log("Amount mapped:", simpleCrowdfund.GetContributorToAmount(address(2)));
        assertEq(records.length, 0, "Event was emited!");
        assertEq(contractBalance, 0 ether, "Amount raised is more than 0 ether");
    }

    function test_LessThanMinimumEth() public {
        // Scenario: Contributing less than the minimum amount
        //  Given the contract is deployed with goal = 2 ETH, deadline is in 1 day and minimalAmount = 0.001 ETH
        //  And user "Jakob" has 100 ETH in her wallet
        //  When Jakob calls "contribute()" with 0.0001 ETH
        //  Then the transaction should revert with SimpleCrowdfund__ToLittleDonation() error
        //  And the amountRaised in the contract remains 0 ETH
        //  And the contribution mapping for Jakob should be 0 ETH
        //  And the contract should not log a "Contributed" event

        vm.deal(address(2), 100e18);
        vm.recordLogs();
        simpleCrowdfund = new SimpleCrowdfund(address(1), 3600, 2e18);
        vm.deal(address(2), 100 ether);
        vm.prank(address(2));
        vm.expectRevert(SimpleCrowdfund.SimpleCrowdfund__ToLittleDonation.selector);
        simpleCrowdfund.contribute{value: 0.0001 ether}();
        checkBalance();

        assertEq(contractBalance, 0, "Balance should be 0 ETH");
        assertEq(simpleCrowdfund.GetContributorToAmount(address(2)) == 0 ether, true, "Value is mapped!");
        console.log("Amount mapped:", simpleCrowdfund.GetContributorToAmount(address(2)));
        Vm.Log[] memory records = vm.getRecordedLogs();
        assertEq(records.length, 0, "Event was emmited!");
        assertEq(contractBalance, 0 ether);
    }

    function test_MoreThanMinimumEth() public {
        // Scenario: Contributing more than the minimum amount
        //  Given the contract is deployed with goal = 2 ETH, deadline is in 1 day and minimalAmount = 0.001 ETH
        //  And user "Jakob" has 100 ETH in her wallet
        //  When Jakob calls "contribute()" with 0.001 ETH
        //  Then the amountRaised in the contract should be 0.001 ETH
        //  And the contribution mapping for Jakob should be 0.001 ETH
        //  And the contract should log a "Contributed" event with (Jakob, 0.001 ETH)
        vm.deal(address(2), 100e18);
        vm.recordLogs();
        simpleCrowdfund = new SimpleCrowdfund(address(1), 30, 2e18);
        console.log("Contract balance Before:", contractBalance);
        vm.deal(address(2), 100e18);
        vm.prank(address(2));

        simpleCrowdfund.contribute{value: 0.002 ether}();
        checkBalance();
        console.log("Contract balance After:", contractBalance);
        console.log("Robert balance:", address(2).balance);
        // console.log( "Array length4:",simpleCrowdfund.GetContributorsListLength());
        // assertEq(simpleCrowdfund.GetContributorsListLength(), 1, "its not 1");
        Vm.Log[] memory records = vm.getRecordedLogs();
        console.log("records length:", records.length);
        assertEq(records.length, 1, "Different than 1");
        assertEq(contractBalance, 0.002 ether);
    }

    function test_ExaclyMinimumEth() public {
        // Scenario: Contributing exactly the minimum amount
        //  Given the contract is deployed with goal = 2 ETH, deadline is in 1 day and minimalAmount = 0.001 ETH
        //  And user "Jakob" has 100 ETH in her wallet
        //  When Jakob calls "contribute()" with 0.001 ETH
        //  Then the amountRaised in the contract should be 0.001 ETH
        //  And the contribution mapping for Jakob should be 0.001 ETH
        //  And the contract should log a "Contributed" event with (Jakob, 0.001 ETH)
        vm.deal(address(2), 100e18);
        vm.recordLogs();
        simpleCrowdfund = new SimpleCrowdfund(address(1), 30, 2e18);
        console.log("Contract balance Before:", contractBalance);
        vm.deal(address(2), 100e18);
        vm.prank(address(2));

        simpleCrowdfund.contribute{value: 0.001 ether}();
        checkBalance();
        console.log("Contract balance After:", contractBalance);
        console.log("Robert balance:", address(2).balance);
        // console.log( "Array length4:",simpleCrowdfund.GetContributorsListLength());
        // assertEq(simpleCrowdfund.GetContributorsListLength(), 1, "its not 1");
        Vm.Log[] memory records = vm.getRecordedLogs();
        console.log("records length:", records.length);
        assertEq(records.length, 1, "Different than 1");
        assertEq(contractBalance, 0.001 ether);
    }

    function test_OneWeiBelowMinimumEth() public {
        // Scenario: Contributing one wei below the minimum amount
        //  Given the contract is deployed with goal = 2 ETH, deadline is in 1 day and minimalAmount = 0.001 ETH
        //  And user "Jakob" has 100 ETH in her wallet
        //  When Jakob calls "contribute()" with 0,000999999999999999 ETH (999999999999999 Wei)
        //  Then the transaction should revert with SimpleCrowdfund__ToLittleDonation() error
        //  And the amountRaised in the contract remains 0 ETH
        //  And the contribution mapping for Jakob should be 0 ETH
        //  And the contract should not log a "Contributed" event
        vm.deal(address(2), 100e18);
        vm.recordLogs();
        simpleCrowdfund = new SimpleCrowdfund(address(1), 3600, 2e18);
        vm.deal(address(2), 100 ether);
        vm.prank(address(2));
        vm.expectRevert(SimpleCrowdfund.SimpleCrowdfund__ToLittleDonation.selector);
        simpleCrowdfund.contribute{value: 1e15 - 1}();
        checkBalance();
        assertEq(contractBalance, 0, "Balance should be 0 ETH");
        assertEq(simpleCrowdfund.GetContributorToAmount(address(2)) == 0, true, "Value is not mapped!");
        console.log("Amount mapped:", simpleCrowdfund.GetContributorToAmount(address(2)));
        Vm.Log[] memory records = vm.getRecordedLogs();
        assertEq(contractBalance, 0 ether);
        assertEq(records.length, 0, "Event was emmited!");
    }

    function test_OneWeiAboveMinimumEth() public {
        // Scenario: Contributing one wei above the minimum amount
        //  Given the contract is deployed with goal = 2 ETH, deadline is in 1 day and minimalAmount = 0.001 ETH
        //  And user "Jakob" has 100 ETH in her wallet
        //  When Jakob calls "contribute()" with 0,001000000000000001 ETH (1000000000000001 Wei)
        //  Then the amountRaised in the contract should be 0,001000000000000001 ETH
        //  And the contribution mapping for Jakob should be 0,001000000000000001 ETH
        //  And the contract should log a "Contributed" event with (Jakob, 0,001000000000000001 ETH)
        vm.deal(address(2), 100e18);
        vm.recordLogs();
        simpleCrowdfund = new SimpleCrowdfund(address(1), 30, 2e18);
        console.log("Contract balance Before:", contractBalance);
        vm.deal(address(2), 100e18);
        vm.prank(address(2));

        simpleCrowdfund.contribute{value: 0.001 ether + 1 wei}();
        checkBalance();
        console.log("Contract balance After:", contractBalance);
        console.log("Robert balance:", address(2).balance);
        // console.log( "Array length4:",simpleCrowdfund.GetContributorsListLength());
        // assertEq(simpleCrowdfund.GetContributorsListLength(), 1, "its not 1");
        Vm.Log[] memory records = vm.getRecordedLogs();
        console.log("records length:", records.length);
        assertEq(records.length, 1, "Different than 1");
        assertEq(contractBalance, 0.001 ether + 1 wei, "Contribute failed!");
    }

    function test_ContributeBeforeDeadline() public {
        // Scenario: Contributing to the crowdfund before the deadline
        //  Given the contract is deployed with goal = 10 ETH, deadline is in 10 minutes from now
        //  And user "Alice" has 100 ETH in her wallet
        //  When Alice calls "contribute()" with 5 ETH
        //  Then the contract should log a "Contributed" event with (Alice, 5 ETH)
        //  And the amountRaised in the contract should be 5 ETH
        //  And the contribution mapping for Alice should be 5 ETH
        bool eventFound = false;

        vm.deal(address(2), 100e18);
        vm.recordLogs();
        simpleCrowdfund = new SimpleCrowdfund(address(1), 600, 10e18);
        console.log("Contract balance Before:", contractBalance);
        vm.deal(address(2), 100e18);
        vm.prank(address(2));

        simpleCrowdfund.contribute{value: 5 ether}();
        checkBalance();
        console.log("Contract balance After:", contractBalance);
        console.log("Robert balance:", address(2).balance);
        // console.log( "Array length4:",simpleCrowdfund.GetContributorsListLength());
        // assertEq(simpleCrowdfund.GetContributorsListLength(), 1, "its not 1");
        Vm.Log[] memory records = vm.getRecordedLogs();
        console.log("records length:", records.length);
        assertEq(records.length, 1, "Different than 1");
        if (records[0].topics[0] == keccak256("Contributed(address,uint256)")) eventFound = true;
        assertEq(eventFound, true, "No event was emitet!");

        assertEq(simpleCrowdfund.goalReached(), false, "Goal should be false!");
        assertEq(contractBalance, 5 ether);
    }

    function test_ContributeAfterDeadline() public {
        // Scenario: Attempting to contribute after the deadline
        //   Given the contract is deployed with goal = 10 ETH, deadline is now + 1 minute
        //   And user "Bob" has 100 ETH in his wallet
        //   And we move the blockchain time to after the deadline
        //   When Bob calls "contribute()" with 1 ETH
        //   Then the transaction should revert with SimpleCrowdfund__CampaignIsEnded()
        //   And the amountRaised in the contract remains 0 ETH
        bool eventFound = false;

        vm.deal(address(2), 100e18);
        vm.recordLogs();
        simpleCrowdfund = new SimpleCrowdfund(address(1), 60, 10e18);
        vm.warp(simpleCrowdfund.i_timeInitiation() + simpleCrowdfund.i_secToComplete() + 10);
        console.log("Contract balance Before:", contractBalance);
        vm.deal(address(2), 100e18);
        vm.prank(address(2));
        vm.expectRevert(SimpleCrowdfund.SimpleCrowdfund__CampaignIsEnded.selector);
        simpleCrowdfund.contribute{value: 1 ether}();
        checkBalance();
        console.log("Contract balance After:", contractBalance);
        console.log("Robert balance:", address(2).balance);

        Vm.Log[] memory records = vm.getRecordedLogs();
        console.log("records length:", records.length);
        assertEq(records.length, 0, "Different than 0");
        // if (records[0].topics[0] == keccak256("Contributed(address,uint256)")) eventFound = true;
        // assertEq(eventFound, true, "No event was emitet!");

        assertEq(simpleCrowdfund.goalReached(), false, "Goal should be false!");
        assertEq(contractBalance, 0 ether);
    }

    function test_ContributeBeforeGoalReached() public {
        // Scenario: Contributing to the crowdfund before the goal is reached
        //   Given the contract is deployed with goal = 10 ETH, deadline is in 1 day
        //   And user "Alice" contributes 7 ETH
        //   Then the total amountRaised is 7 ETH
        //   And Alice should be in the ContributorsList
        //   And the contract should log a "Contributed" event

        bool eventFound = true;

        vm.deal(address(2), 100e18);
        vm.recordLogs();
        simpleCrowdfund = new SimpleCrowdfund(address(1), 600, 10e18);
        console.log("Contract balance Before:", contractBalance);
        vm.deal(address(2), 100e18);
        vm.prank(address(2));
        simpleCrowdfund.contribute{value: 7 ether}();
        checkBalance();
        console.log("Contract balance After:", contractBalance);
        console.log("Robert balance:", address(2).balance);
        // console.log( "Array length4:",simpleCrowdfund.GetContributorsListLength());
        // assertEq(simpleCrowdfund.GetContributorsListLength(), 1, "its not 1");
        Vm.Log[] memory records = vm.getRecordedLogs();
        console.log("records length:", records.length);
        assertEq(records.length, 1, "Different than 1");
        if (records[0].topics[0] == keccak256("Contributed(address,uint256)")) eventFound = true;
        assertEq(eventFound, true, "No event was emitet!");

        assertEq(simpleCrowdfund.goalReached(), false, "Goal should be false!");
        assertEq(contractBalance, 7 ether);
    }

    function test_ContributeAfterGoalReached() public {
        // Scenario: Attempting to contribute after the goal is reached
        //   Given the contract is deployed with goal = 10 ETH, deadline is in 1 day
        //   And user "Charlie" contributes 7 ETH
        //   And user "Dominic" contributes 3 ETH
        //   Then the total amountRaised is 10 ETH
        //   When user "Eve" calls "contribute()" with 1 ETH
        //   Then the transaction should revert with SimpleCrowdfund__CampaignIsEnded() error
        //   And the amountRaised in the contract remains 10 ETH
        //   And the Eve should not be in the ContributorsList
        //   And the contract should not log a "Contributed" event
        uint256 eventFound = 0;

        vm.recordLogs();
        simpleCrowdfund = new SimpleCrowdfund(address(1), 60, 10 ether);

        vm.deal(address(3), 100e18);
        vm.prank(address(3));
        simpleCrowdfund.contribute{value: 6 ether}();
        checkBalance();

        vm.deal(address(4), 100e18);
        vm.prank(address(4));
        simpleCrowdfund.contribute{value: 5 ether}();
        checkBalance();

        console.log("Contract balance Before:", contractBalance);
        vm.deal(address(2), 100e18);
        vm.prank(address(2));
        vm.expectRevert(SimpleCrowdfund.SimpleCrowdfund__CampaignIsEnded.selector);
        simpleCrowdfund.contribute{value: 1 ether}();
        checkBalance();
        console.log("Contract balance After:", contractBalance);
        console.log("Alice balance:", address(2).balance);

        Vm.Log[] memory records = vm.getRecordedLogs();
        console.log("records length:", records.length);
        assertEq(records.length, 2, "Different than 1");
        if (records[0].topics[0] == keccak256("Contributed(address,uint256)")) eventFound += 1;
        if (records[0].topics[0] == keccak256("Contributed(address,uint256)")) eventFound += 1;
        assertEq(eventFound, 2);

        assertEq(simpleCrowdfund.goalReached(), true, "Goal should be false!");
        assertEq(contractBalance, 11 ether);
    }

    // function test_AddingContributors() public {
    //     // Scenario: Adding contributors to the list
    //     //   Given the contract is deployed with goal = 10 ETH, deadline is in 1 day
    //     //   And user "Alice" contributes 7 ETH
    //     //   And user "Bob" contributes 3 ETH
    //     //   Then the total amountRaised is 10 ETH
    //     //   And Alice and Bob should be in the ContributorsList
    //     //   And the contract should log a "Contributed" event for Alice and Bob
    //     bool eventFound = true;

    //     vm.deal(address(2), 100e18);
    //     vm.recordLogs();
    //     simpleCrowdfund = new SimpleCrowdfund(address(1), 600, 10e18);
    //     console.log("Contract balance Before:", contractBalance);
    //     vm.deal(address(2), 100e18);
    //     vm.prank(address(2));
    //     simpleCrowdfund.contribute{value: 7 ether}();
    //     checkBalance();
    //     console.log("Contract balance After:", contractBalance);
    //     console.log("Robert balance:", address(2).balance);
    //     // console.log( "Array length4:",simpleCrowdfund.GetContributorsListLength());
    //     // assertEq(simpleCrowdfund.GetContributorsListLength(), 1, "its not 1");
    //     Vm.Log[] memory records = vm.getRecordedLogs();
    //     console.log("records length:", records.length);
    //     assertEq(records.length, 1, "Different than 1");
    //     if (records[0].topics[0] == keccak256("Contributed(address,uint256)")) eventFound = true;
    //     assertEq(eventFound, true, "No event was emitet!");

    //     assertEq(simpleCrowdfund.goalReached(), false, "Goal should be false!");
    //     assertEq(contractBalance, 7 ether);
    // }

    function test_AddingContributorTwice() public {
        // Scenario: Adding the same contributor twice
        //   Given the contract is deployed with goal = 10 ETH, deadline is in 1 day
        //   And user "Alice" contributes 7 ETH
        //   And user "Alice" contributes 3 ETH
        //   Then the total amountRaised is 10 ETH
        //   And Alice should be in the ContributorsList only once
        //   And the contract should log a "Contributed" event for Alice twice
        bool eventFound = true;

        vm.deal(address(2), 100e18);
        vm.recordLogs();
        simpleCrowdfund = new SimpleCrowdfund(address(1), 600, 10e18);
        console.log("Contract balance Before:", contractBalance);
        vm.startPrank(address(2));
        simpleCrowdfund.contribute{value: 7 ether}();
        checkBalance();
        console.log("Contract balance After:", contractBalance);
        console.log("Alice balance:", address(2).balance);

        assertEq(simpleCrowdfund.GetContributorsListLength(), 1, "its not 1");
        simpleCrowdfund.contribute{value: 3 ether}();
        checkBalance();
        vm.stopPrank();

        assertEq(simpleCrowdfund.GetContributorsListLength(), 1, "its not 1");
        assertEq(simpleCrowdfund.goalReached(), true, "Goal should be true!");
        assertEq(contractBalance, 10 ether);
        Vm.Log[] memory records = vm.getRecordedLogs();
        console.log("records length:", records.length);
        assertEq(records.length, 2, "Different than 2");
        if (records[0].topics[0] == keccak256("Contributed(address,uint256)")) eventFound = true;
        assertEq(eventFound, true, "No event was emitet!");
    }

    function test_ContributeAfterWithdraw() public {
        // Scenario: Attempting to contribute after the owner has withdrawn the funds
        //   Given the contract is deployed with goal = 10 ETH, deadline is in 1 day
        //   And user "Charlie" contributes 7 ETH
        //   And user "Diana" contributes 3 ETH
        //   Then the total amountRaised is 10 ETH
        //   When the owner calls "withdraw()"
        //   Then the transaction should succeed
        //   And the contract should log a "Withdrawn" event
        //   And the owner’s balance should increase by 10 ETH
        //   And the contract’s balance should be 0
        //   When user "Eve" calls "contribute()" with 1 ETH
        //   Then the transaction should revert with SimpleCrowdfund__CampaignIsEnded() error
        //   And the amountRaised in the contract remains 0 ETH

        uint256 eventFound = 0;

        vm.recordLogs();
        simpleCrowdfund = new SimpleCrowdfund(address(1), 3600 * 24, 10 ether);

        vm.deal(address(3), 100e18);
        vm.prank(address(3));
        simpleCrowdfund.contribute{value: 7 ether}();
        checkBalance();

        vm.deal(address(4), 100e18);
        vm.prank(address(4));
        simpleCrowdfund.contribute{value: 3 ether}();
        checkBalance();

        //Withdraw

        console.log("Contract balance before withdraw:", contractBalance);
        console.log("Owners balance before:", simpleCrowdfund.i_owner());
        vm.prank(simpleCrowdfund.i_owner());
        simpleCrowdfund.withdraw();
        console.log("Contract balance after withdraw:", contractBalance);
        console.log("Owners balance before:", simpleCrowdfund.i_owner());
        Vm.Log[] memory records = vm.getRecordedLogs(); //logs consumed
        assertEq(records.length, 3, "Different than 3");
        if (records[0].topics[0] == keccak256("Contributed(address,uint256)")) eventFound += 1;
        if (records[1].topics[0] == keccak256("Contributed(address,uint256)")) eventFound += 1;
        if (records[2].topics[0] == keccak256("Withdraw(address,uint256)")) eventFound += 1;
        assertEq(eventFound, 3);

        //After withdraw
        console.log("Contract balance Before:", contractBalance);
        vm.deal(address(2), 100e18);
        vm.prank(address(2));
        vm.expectRevert(SimpleCrowdfund.SimpleCrowdfund__CampaignIsEnded.selector);
        simpleCrowdfund.contribute{value: 1 ether}();
        checkBalance();
        assertEq(contractBalance, 0 ether, "Contract balance should be 0 ether");
        console.log("Contract balance After:", contractBalance);
        console.log("Alice balance:", address(2).balance);

        records = vm.getRecordedLogs();
        console.log("records length:", records.length);
        assertEq(records.length, 0, "Different than 0");
        if (records.length > 0) {
            if (records[0].topics[0] == keccak256("Contributed(address,uint256)")) eventFound += 1;
        }
        assertEq(eventFound, 3);

        assertEq(simpleCrowdfund.goalReached(), true, "Goal should be false!");
        assertEq(contractBalance, 0 ether);
    }

    function test_ContributeAfterRefund() public {
        // Scenario: Attempting to contribute after backers has refunded the funds
        //   Given the contract is deployed with goal = 10 ETH, deadline is in 1 day
        //   And user "Charlie" contributes 7 ETH
        //   When the Deadline is reached and the goal is not reached
        //   And the backers calls "refund()"
        //   Then the transaction should succeed
        //   And the contract should log a "Refunded" event

        bool eventFound = false;

        vm.deal(address(2), 100e18);
        vm.recordLogs();
        simpleCrowdfund = new SimpleCrowdfund(address(1), 3600 * 24, 10e18);
        console.log("Contract balance Before:", contractBalance);
        vm.deal(address(2), 100e18);
        vm.prank(address(2));
        // vm.expectRevert(SimpleCrowdfund.SimpleCrowdfund__CampaignIsEnded.selector);
        simpleCrowdfund.contribute{value: 7 ether}();
        checkBalance();
        console.log("Contract balance After:", contractBalance);
        console.log("Charlie balance:", address(2).balance);

        Vm.Log[] memory records = vm.getRecordedLogs();
        console.log("records length:", records.length);
        assertEq(records.length, 1, "Different than 0");

        assertEq(simpleCrowdfund.goalReached(), false, "Goal should be false!");
        assertEq(contractBalance, 7 ether);

        //Timetravel
        vm.warp(simpleCrowdfund.i_timeInitiation() + simpleCrowdfund.i_secToComplete() + 10);

        vm.deal(address(3), 100e18);
        vm.prank(address(3));
        vm.expectRevert(SimpleCrowdfund.SimpleCrowdfund__CampaignIsEnded.selector);
        simpleCrowdfund.contribute{value: 1 ether}();
        checkBalance();
        console.log("Contract balance After:", contractBalance);
        console.log("Robert balance:", address(3).balance);
        assertEq(simpleCrowdfund.GetContributorsListLength(), 1);
    }

    /*/////////////////////////////////////////////////////////////////////////////
                                    Withdraw Section
    /////////////////////////////////////////////////////////////////////////////*/

    function test_OwnerWithdrawGoalReached() public {
        // Scenario: The goal is reached on time, then the owner withdraws
        //   Given the contract is deployed with goal = 10 ETH, deadline is in 1 day
        //   And user "Charlie" contributes 7 ETH
        //   And user "Diana" contributes 3 ETH
        //   Then the total amountRaised is 10 ETH
        //   When the owner calls "withdraw()"
        //   Then the transaction should succeed
        //   And the contract should log a "Withdrawn" event
        //   And the owner’s balance should increase by 10 ETH
        //   And the contract’s balance should be 0
        //   And the goalReached should be true
        //   And the fundsWithdrawned should be true

        uint256 eventFound = 0;

        vm.recordLogs();
        simpleCrowdfund = new SimpleCrowdfund(address(1), 3600 * 24, 10 ether);

        vm.deal(address(3), 100e18);
        vm.prank(address(3));
        simpleCrowdfund.contribute{value: 7 ether}();
        checkBalance();

        vm.deal(address(4), 100e18);
        vm.prank(address(4));
        simpleCrowdfund.contribute{value: 3 ether}();
        checkBalance();

        //Withdraw

        console.log("Contract balance before withdraw:", contractBalance);
        console.log("Owners balance before:", simpleCrowdfund.i_owner());
        vm.prank(simpleCrowdfund.i_owner());
        simpleCrowdfund.withdraw();
        console.log("Contract balance after withdraw:", contractBalance);
        console.log("Owners balance before:", simpleCrowdfund.i_owner());
        Vm.Log[] memory records = vm.getRecordedLogs(); //logs consumed
        assertEq(records.length, 3, "Different than 3");
        if (records[0].topics[0] == keccak256("Contributed(address,uint256)")) eventFound += 1;
        if (records[1].topics[0] == keccak256("Contributed(address,uint256)")) eventFound += 1;
        if (records[2].topics[0] == keccak256("Withdraw(address,uint256)")) eventFound += 1;
        assertEq(eventFound, 3);
    }

    function test_OwnerWithdrawGoalNotReachedInTime() public {
        // Scenario: The goal is not reached on time, then the owner withdraws
        //   Given the contract is deployed with goal = 10 ETH, deadline is in 1 day
        //   And user "Adam" contributes 7 ETH
        //   And the deadline is reached
        //   Then the total amountRaised is 7 ETH
        //   When the owner calls "withdraw()"
        //   Then the transaction should fail
        //   And the contract should not log a "Withdrawn" event
        //   And the owner’s balance should not increase
        //   And the contract’s balance should be 7 ETH (the amount raised)

        uint256 eventFound = 0;

        vm.recordLogs();
        simpleCrowdfund = new SimpleCrowdfund(address(1), 3600 * 24, 10 ether);

        vm.deal(address(3), 100e18);
        vm.prank(address(3));
        simpleCrowdfund.contribute{value: 7 ether}();
        checkBalance();

        // vm.deal(address(4), 100e18);
        // vm.prank(address(4));
        // simpleCrowdfund.contribute{value: 3 ether}();
        // checkBalance();

        //Withdraw

        console.log("Contract balance before withdraw:", contractBalance);
        console.log("Owners balance before:", simpleCrowdfund.i_owner());
        vm.warp(simpleCrowdfund.i_deadline() + simpleCrowdfund.i_secToComplete() + 10);
        vm.prank(simpleCrowdfund.i_owner());
        vm.expectRevert(SimpleCrowdfund.SimpleCrowdfund__CallFailed.selector);
        simpleCrowdfund.withdraw();
        console.log("Contract balance after withdraw:", contractBalance);
        console.log("Owners balance before:", simpleCrowdfund.i_owner());
        Vm.Log[] memory records = vm.getRecordedLogs(); //logs consumed
        assertEq(records.length, 1, "Different than 1");
        if (records[0].topics[0] == keccak256("Contributed(address,uint256)")) eventFound += 1;
        assertEq(eventFound, 1);
    }

    function test_OwnerWithdrawWhenGoalNotReachedYet() public {
        // Scenario: The owner withdraws when the goal is not reached yet
        //   Given the contract is deployed with goal = 10 ETH, deadline is in 1 day
        //   And user "Charlie" contributes 7 ETH
        //   And time is before the deadline
        //   Then the total amountRaised is 7 ETH
        //   When the owner calls "withdraw()"
        //   Then the transaction should fail with error SimpleCrowdfund__CampaignIsNotEnded
        //   And the contract should not log a "Withdrawn" event
        //   And the owner’s balance should not increase
        uint256 eventFound = 0;

        vm.recordLogs();
        simpleCrowdfund = new SimpleCrowdfund(address(1), 3600 * 24, 10 ether);

        vm.deal(address(3), 100e18);
        vm.prank(address(3));
        simpleCrowdfund.contribute{value: 7 ether}();
        checkBalance();

        // vm.deal(address(4), 100e18);
        // vm.prank(address(4));
        // simpleCrowdfund.contribute{value: 3 ether}();
        // checkBalance();

        //Withdraw

        console.log("Contract balance before withdraw:", contractBalance);
        console.log("Owners balance before:", simpleCrowdfund.i_owner());
        vm.prank(simpleCrowdfund.i_owner());
        vm.expectRevert(SimpleCrowdfund.SimpleCrowdfund__CallFailed.selector);
        simpleCrowdfund.withdraw();
        console.log("Contract balance after withdraw:", contractBalance);
        console.log("Owners balance before:", simpleCrowdfund.i_owner());
        Vm.Log[] memory records = vm.getRecordedLogs(); //logs consumed
        assertEq(records.length, 1, "Different than 1");
        if (records[0].topics[0] == keccak256("Contributed(address,uint256)")) eventFound += 1;
        assertEq(eventFound, 1);
    }

    function test_NotTheOwnerWithdrawGoalNotReachedYet() public {
        // Scenario: A user that is not the owner tries to withdraw when the goal is not reached yet
        //   Given the contract is deployed with goal = 10 ETH, deadline is in 1 day
        //   And user "Charlie" contributes 7 ETH
        //   And time is before the deadline
        //   Then the total amountRaised is 7 ETH
        //   When Charlie calls "withdraw()"
        //   Then the transaction should fail with error SimpleCrowdfund__NoPermission
        //   And the contract should not log a "Withdrawn" event
        //   And Charlie’s balance should not increase
        uint256 eventFound = 0;

        vm.recordLogs();
        simpleCrowdfund = new SimpleCrowdfund(address(1), 3600 * 24, 10 ether);

        vm.deal(address(3), 100e18);
        vm.prank(address(3));
        simpleCrowdfund.contribute{value: 7 ether}();
        checkBalance();

        // vm.deal(address(4), 100e18);
        // vm.prank(address(4));
        // simpleCrowdfund.contribute{value: 3 ether}();
        // checkBalance();

        //Withdraw

        console.log("Contract balance before withdraw:", contractBalance);
        console.log("Owners balance before:", address(2));
        vm.prank(address(0));
        vm.expectRevert(SimpleCrowdfund.SimpleCrowdfund__NoPermission.selector);
        simpleCrowdfund.withdraw();
        console.log("Contract balance after withdraw:", contractBalance);
        console.log("Owners balance before:", address(2));
        Vm.Log[] memory records = vm.getRecordedLogs(); //logs consumed
        assertEq(records.length, 1, "Different than 1");
        if (records[0].topics[0] == keccak256("Contributed(address,uint256)")) eventFound += 1;
        assertEq(eventFound, 1);
    }

    function test_NotTheOwnerWithdrawGoalReached() public {
        // Scenario: A user that is not the owner tries to withdraw when the goal is reached
        //   Given the contract is deployed with goal = 10 ETH, deadline is in 1 day
        //   And user "Charlie" contributes 7 ETH
        //   And user "Diana" contributes 4 ETH
        //   Then the total amountRaised is 11 ETH
        //   And the goalReached is true
        //   When Charlie calls "withdraw()"
        //   Then the transaction should revert with SimpleCrowdfund__NoPermission()
        //   And the contract should not log a "Withdrawn" event
        uint256 eventFound = 0;

        vm.recordLogs();
        simpleCrowdfund = new SimpleCrowdfund(address(1), 3600 * 24, 10 ether);

        vm.deal(address(3), 100e18);
        vm.prank(address(3));
        simpleCrowdfund.contribute{value: 7 ether}();
        checkBalance();

        vm.deal(address(4), 100e18);
        vm.prank(address(4));
        simpleCrowdfund.contribute{value: 3 ether}();
        checkBalance();

        //Withdraw

        console.log("Contract balance before withdraw:", contractBalance);
        console.log("Owners balance before:", address(3));
        vm.prank(address(3));
        vm.expectRevert(SimpleCrowdfund.SimpleCrowdfund__NoPermission.selector);
        simpleCrowdfund.withdraw();
        console.log("Contract balance after withdraw:", contractBalance);
        console.log("Owners balance before:", address(3));
        Vm.Log[] memory records = vm.getRecordedLogs(); //logs consumed
        assertEq(records.length, 2, "Different than 2");
        if (records[0].topics[0] == keccak256("Contributed(address,uint256)")) eventFound += 1;
        if (records[1].topics[0] == keccak256("Contributed(address,uint256)")) eventFound += 1;
        assertEq(eventFound, 2);
    }

    function test_OwnerWithdrawTwice() public {
        // Scenario: The owner withdraws twice after the goal is reached
        //  Given the contract is deployed with goal = 10 ETH, deadline is in 1 day
        //  And user "Charlie" contributes 7 ETH
        //  And user "Diana" contributes 4 ETH
        //  Then the total amountRaised is 11 ETH
        //  And the goalReached is true
        //  When the owner calls "withdraw()" for the first time
        //  Then the first transaction should succeed
        //  And the contract should log a "Withdrawn" event
        //  And the owner’s balance should increase by 11 ETH
        //  And the contract’s balance should be 0
        //  And the fundsWithdrawned should be true
        //  When the owner calls "withdraw()" for the second time
        //  Then the transaction should fail with SimpleCrowdfund__NoPermission()
        //  And the contract should not log a "Withdrawn" event

        uint256 eventFound = 0;

        vm.recordLogs();
        simpleCrowdfund = new SimpleCrowdfund(address(1), 3600 * 24, 10 ether);

        vm.deal(address(3), 100e18);
        vm.prank(address(3));
        simpleCrowdfund.contribute{value: 7 ether}();
        checkBalance();

        vm.deal(address(4), 100e18);
        vm.prank(address(4));
        simpleCrowdfund.contribute{value: 4 ether}();
        checkBalance();

        //Withdraw

        console.log("Contract balance before withdraw:", contractBalance);
        console.log("Owners balance before:", simpleCrowdfund.i_owner());
        vm.prank(simpleCrowdfund.i_owner());
        simpleCrowdfund.withdraw();
        console.log("Contract balance after withdraw:", contractBalance);
        console.log("Owners balance before:", simpleCrowdfund.i_owner());

        console.log("Contract balance before second withdraw:", contractBalance);
        console.log("Owners balance before second:", simpleCrowdfund.i_owner());
        vm.prank(simpleCrowdfund.i_owner());
        vm.expectRevert(SimpleCrowdfund.SimpleCrowdfund__CampaignIsEnded.selector);
        simpleCrowdfund.withdraw();
        console.log("Contract balance after second withdraw:", contractBalance);
        console.log("Owners balance second before:", simpleCrowdfund.i_owner());

        Vm.Log[] memory records = vm.getRecordedLogs(); //logs consumed
        assertEq(records.length, 3, "Different than 3");
        if (records[0].topics[0] == keccak256("Contributed(address,uint256)")) eventFound += 1;
        if (records[1].topics[0] == keccak256("Contributed(address,uint256)")) eventFound += 1;
        if (records[2].topics[0] == keccak256("Withdraw(address,uint256)")) eventFound += 1;
        assertEq(eventFound, 3);
    }

    function test_OwnerWithdrawAfterRefund() public {
        // Scenario: The owner withdraws after the backers have refunded
        //   Given the contract is deployed with goal = 10 ETH, deadline is in 1 day
        //   And user "Charlie" contributes 7 ETH
        //   And user "Diana" contributes 2 ETH
        //   And the deadline is reached
        //   And the backers call "refund()"
        //   Then the total amountRaised is 0 ETH
        //   When the owner calls "withdraw()"
        //   Then the transaction should fail with SimpleCrowdfund__CampaignIsNotEnded()
        //   And the contract should not log a "Withdrawn" event
        //   And the owner’s balance should not increase

        bool eventFound = false;

        vm.deal(address(2), 100e18);
        vm.recordLogs();
        simpleCrowdfund = new SimpleCrowdfund(address(1), 3600 * 24, 10e18);
        console.log("Contract balance Before:", contractBalance);
        vm.deal(address(2), 100e18);
        vm.prank(address(2));
        // vm.expectRevert(SimpleCrowdfund.SimpleCrowdfund__CampaignIsEnded.selector);
        simpleCrowdfund.contribute{value: 7 ether}();
        checkBalance();
        console.log("Contract balance After:", contractBalance);
        console.log("Charlie balance:", address(2).balance);

        //Timetravel
        vm.warp(simpleCrowdfund.i_timeInitiation() + simpleCrowdfund.i_secToComplete() + 10);

        vm.prank(address(2));
        simpleCrowdfund.refund();

        Vm.Log[] memory records = vm.getRecordedLogs();
        console.log("records length:", records.length);
        assertEq(records.length, 2, "Different than 2");

        assertEq(address(2).balance, 100 ether, "Error");

        assertEq(simpleCrowdfund.goalReached(), false, "Goal should be false!");
        assertEq(contractBalance, 7 ether);

        vm.deal(simpleCrowdfund.i_owner(), 100e18);
        vm.prank(simpleCrowdfund.i_owner());
        vm.expectRevert(SimpleCrowdfund.SimpleCrowdfund__CallFailed.selector);
        simpleCrowdfund.withdraw();
        checkBalance();
        console.log("Contract balance After:", contractBalance);
        console.log("Robert balance:", simpleCrowdfund.i_owner().balance);
        assertEq(simpleCrowdfund.GetContributorsListLength(), 1);
    }

    function test_OwnerWithdrawBeforeDeadline() public {
        // Scenario: The owner withdraws before the deadline and goal is reached
        //   Given the contract is deployed with goal = 10 ETH, deadline is in 1 day
        //   And user "Charlie" contributes 7 ETH
        //   And user "Diana" contributes 3 ETH
        //   And time is before the deadline
        //   Then the total amountRaised is 10 ETH
        //   When the owner calls "withdraw()"
        //   Then the transaction should succeed
        //   And the contract should log a "Withdrawn" event
        //   And the owner’s balance should increase by 10 ETH
        //   And the contract’s balance should be 0
        //   And the goalReached should be true

        uint256 eventFound = 0;

        vm.recordLogs();
        simpleCrowdfund = new SimpleCrowdfund(address(1), 3600 * 24, 10 ether);

        vm.deal(address(3), 100e18);
        vm.prank(address(3));
        simpleCrowdfund.contribute{value: 7 ether}();
        checkBalance();

        //Withdraw

        console.log("Contract balance before withdraw:", contractBalance);
        console.log("Owners balance before:", simpleCrowdfund.i_owner());
        vm.prank(simpleCrowdfund.i_owner());
        vm.expectRevert(SimpleCrowdfund.SimpleCrowdfund__CallFailed.selector);
        simpleCrowdfund.withdraw();
        console.log("Contract balance after withdraw:", contractBalance);
        console.log("Owners balance before:", simpleCrowdfund.i_owner());
        Vm.Log[] memory records = vm.getRecordedLogs(); //logs consumed
        assertEq(records.length, 1, "Different than 1");
        if (records[0].topics[0] == keccak256("Contributed(address,uint256)")) eventFound += 1;
        assertEq(eventFound, 1);
    }

    function test_OwnerWithdrawAfterDeadline() public {
        // Scenario: The owner withdraws after the deadline and goal is reached
        //   Given the contract is deployed with goal = 10 ETH, deadline is in 1 day
        //   And user "Charlie" contributes 7 ETH
        //   And the deadline is reached
        //   Then the total amountRaised is 7 ETH
        //   When the owner calls "withdraw()"
        //   Then the transaction should fail with SimpleCrowdfund__CampaignIsNotEnded()
        //   And the contract should not log a "Withdrawn" event
        //   And the owner’s balance should not increase
        uint256 eventFound = 0;

        vm.recordLogs();
        simpleCrowdfund = new SimpleCrowdfund(address(1), 3600 * 24, 10 ether);

        vm.deal(address(3), 100e18);
        vm.prank(address(3));
        simpleCrowdfund.contribute{value: 7 ether}();
        checkBalance();

        //Withdraw

        vm.warp(simpleCrowdfund.i_timeInitiation() + simpleCrowdfund.i_secToComplete() + 10);

        console.log("Contract balance before withdraw:", contractBalance);
        console.log("Owners balance before:", simpleCrowdfund.i_owner());
        vm.prank(simpleCrowdfund.i_owner());
        vm.expectRevert(SimpleCrowdfund.SimpleCrowdfund__CallFailed.selector);
        simpleCrowdfund.withdraw();
        console.log("Contract balance after withdraw:", contractBalance);
        console.log("Owners balance before:", simpleCrowdfund.i_owner());
        Vm.Log[] memory records = vm.getRecordedLogs(); //logs consumed
        assertEq(records.length, 1, "Different than 1");
        if (records[0].topics[0] == keccak256("Contributed(address,uint256)")) eventFound += 1;
        assertEq(eventFound, 1);
    }

    /*/////////////////////////////////////////////////////////////////////////////
                                    Refund Section
    /////////////////////////////////////////////////////////////////////////////*/

    function test_TwoBackersRefundGoalNotReached() public {
        // Scenario: The goal is reached on time, then the owner withdraws
        //   Given the contract is deployed with goal = 10 ETH, deadline is in 1 day
        //   And user "Charlie" contributes 7 ETH
        //   And user "Diana" contributes 2 ETH
        //   Then the total amountRaised is 9 ETH
        //   When the deadline is reached
        //   And the Charlie call "refund()"
        //   Then the transaction should succeed
        //   And the contract should log a "Refunded" event for Charlie
        //   And the Charlie balances should increase by 7 ETH
        //   And the contract’s balance should be 2 ETH
        //   When the Diana call "refund()"
        //   Then the transaction should succeed
        //   And the contract should log a "Refunded" event for Diana
        //   And the Diana balances should increase by 2 ETH
        //   And the contract’s balance should be 0
        //   And the goalReached should be false
        //   And the fundsWithdrawned should be false

        uint256 eventFound = 0;

        vm.deal(address(2), 100e18);
        vm.recordLogs();
        simpleCrowdfund = new SimpleCrowdfund(address(1), 3600 * 24, 10e18);
        console.log("Contract balance Before:", contractBalance);
        vm.prank(address(2));
        simpleCrowdfund.contribute{value: 7 ether}();
        checkBalance();
        console.log("Contract balance After:", contractBalance);
        console.log("Alice balance:", address(2).balance);

        assertEq(simpleCrowdfund.GetContributorsListLength(), 1, "its not 1");

        vm.prank(address(3));
        vm.deal(address(3), 100e18);
        simpleCrowdfund.contribute{value: 2 ether}();
        checkBalance();

        assertEq(simpleCrowdfund.GetContributorsListLength(), 2, "its not 2");
        assertEq(simpleCrowdfund.goalReached(), false, "Goal should be false!");
        assertEq(contractBalance, 9 ether);
        Vm.Log[] memory records = vm.getRecordedLogs();
        console.log("records length:", records.length);
        assertEq(records.length, 2, "Different than 2");
        if (records[0].topics[0] == keccak256("Contributed(address,uint256)")) eventFound += 1;
        if (records[1].topics[0] == keccak256("Contributed(address,uint256)")) eventFound += 1;
        assertEq(eventFound, 2, "Number of events is not 2");

        // Timetravel
        vm.warp(simpleCrowdfund.i_timeInitiation() + 3600 * 25); // 1 hour after deadline
        assertEq(simpleCrowdfund.timePassed(), true, "Deadline is not reached yet!"); // deadline is reached
        vm.prank(address(2));
        simpleCrowdfund.refund();
        checkBalance();

        console.log("Chalie's balance:", address(2).balance);
        assertEq(contractBalance, 2 ether);

        vm.prank(address(3));
        simpleCrowdfund.refund();
        checkBalance();

        console.log("Diana's balance:", address(3).balance);
        assertEq(contractBalance, 0 ether);

        if (records[0].topics[0] == keccak256("Refunded(address,uint256)")) eventFound += 1;
        if (records[1].topics[0] == keccak256("Refunded(address,uint256)")) eventFound += 1;
        assertEq(eventFound, 2, "Number of events is not 2");
    }

    function test_BackerRefundGoalReached() public {
        // Scenario: The goal is reached on time, then the backers try to refund
        //   Given the contract is deployed with goal = 10 ETH, deadline is in 1 day
        //   And user "Charlie" contributes 7 ETH
        //   And user "Diana" contributes 4 ETH
        //   Then the total amountRaised is 11 ETH
        //   And the goalReached is true
        //   When the Charlie call "refund()"
        //   Then the transaction should revert with SimpleCrowdfund__NoPermission()
        //   And the contract should not log a "Refunded" event

        uint256 eventFound = 0;

        vm.deal(address(2), 100e18);
        vm.recordLogs();
        simpleCrowdfund = new SimpleCrowdfund(address(1), 3600 * 24, 10 ether);
        console.log("Contract balance Before:", contractBalance);
        vm.prank(address(2));
        simpleCrowdfund.contribute{value: 7 ether}();
        checkBalance();
        console.log("Contract balance After:", contractBalance);
        console.log("Alice balance:", address(2).balance);

        assertEq(simpleCrowdfund.GetContributorsListLength(), 1, "its not 1");

        vm.prank(address(3));
        vm.deal(address(3), 100e18);
        simpleCrowdfund.contribute{value: 4 ether}();
        checkBalance();

        assertEq(simpleCrowdfund.GetContributorsListLength(), 2, "its not 2");
        assertEq(simpleCrowdfund.goalReached(), true, "Goal should be true!");
        assertEq(contractBalance, 11 ether);
        Vm.Log[] memory records = vm.getRecordedLogs();
        console.log("records length:", records.length);
        assertEq(records.length, 2, "Different than 2");
        if (records[0].topics[0] == keccak256("Contributed(address,uint256)")) eventFound += 1;
        if (records[1].topics[0] == keccak256("Contributed(address,uint256)")) eventFound += 1;
        assertEq(eventFound, 2, "Number of events is not 2");

        console.log("timepassed:", simpleCrowdfund.timePassed());
        console.log("goalreached:", simpleCrowdfund.goalReached());
        console.log("Chalie's balance:", address(3).balance);
        console.log("Contract balance After:", contractBalance);

        vm.startPrank(address(3));
        vm.expectRevert();
        simpleCrowdfund.refund();
        checkBalance();
        vm.stopPrank();

        console.log("Chalie's balance:", address(2).balance);
        console.log("Contract balance After:", contractBalance);
        assertEq(contractBalance, 11 ether);
    }

    function test_BackerRefundTwice() public {
        // Scenario: The backers try to refund twice
        //   Given the contract is deployed with goal = 10 ETH, deadline is in 1 day
        //   And user "Charlie" contributes 7 ETH
        //   And user "Diana" contributes 2 ETH
        //   Then the total amountRaised is 9 ETH
        //   And the goalReached is false
        //   When the Charlie calls "refund()"
        //   Then the transaction should succeed
        //   And the contract should log a "Refunded" event
        //   And the Charlie’s balance should increase by 7 ETH
        //   And the contract’s balance should be 2 ETH
        //   And the goalReached should be true
        //   And the fundsWithdrawned should be false
        //   When the Charlie calls "refund()" again
        //   Then the transaction should fail with SimpleCrowdfund__NoPermission()

        uint256 eventFound = 0;

        vm.deal(address(2), 100e18);
        vm.recordLogs();
        simpleCrowdfund = new SimpleCrowdfund(address(1), 3600 * 24, 10e18);
        console.log("Contract balance Before:", contractBalance);
        vm.prank(address(2));
        simpleCrowdfund.contribute{value: 7 ether}();
        checkBalance();
        console.log("Contract balance After:", contractBalance);
        console.log("Alice balance:", address(2).balance);

        assertEq(simpleCrowdfund.GetContributorsListLength(), 1, "its not 1");

        vm.prank(address(3));
        vm.deal(address(3), 100e18);
        simpleCrowdfund.contribute{value: 2 ether}();
        checkBalance();

        assertEq(simpleCrowdfund.GetContributorsListLength(), 2, "its not 2");
        assertEq(simpleCrowdfund.goalReached(), false, "Goal should be false!");
        assertEq(contractBalance, 9 ether);
        Vm.Log[] memory records = vm.getRecordedLogs();
        console.log("records length:", records.length);
        assertEq(records.length, 2, "Different than 2");
        if (records[0].topics[0] == keccak256("Contributed(address,uint256)")) eventFound += 1;
        if (records[1].topics[0] == keccak256("Contributed(address,uint256)")) eventFound += 1;
        assertEq(eventFound, 2, "Number of events is not 2");

        // Timetravel
        vm.warp(simpleCrowdfund.i_timeInitiation() + 3600 * 25); // 1 hour after deadline
        assertEq(simpleCrowdfund.timePassed(), true, "Deadline is not reached yet!"); // deadline is reached
        vm.prank(address(2));
        simpleCrowdfund.refund();
        checkBalance();

        console.log("Chalie's balance:", address(2).balance);
        assertEq(contractBalance, 2 ether);

        vm.prank(address(2));

        simpleCrowdfund.refund();
        checkBalance();

        console.log("Diana's balance:", address(2).balance);
        assertEq(contractBalance, 2 ether);

        if (records[0].topics[0] == keccak256("Refunded(address,uint256)")) eventFound += 1;
        if (records[1].topics[0] == keccak256("Refunded(address,uint256)")) eventFound += 1;
        assertEq(eventFound, 2, "Number of events is not 2");
    }

    function test_BackerRefundAfterOwnerWithdraw() public {
        // Scenario: The backers try to refund after the owner has withdrawn
        //   Given the contract is deployed with goal = 10 ETH, deadline is in 1 day
        //   And user "Charlie" contributes 7 ETH
        //   And user "Diana" contributes 4 ETH
        //   Then the total amountRaised is 11 ETH
        //   And the goalReached is true
        //   When the owner calls "withdraw()"
        //   Then the transaction should succeed
        //   And the contract should log a "Withdrawn" event
        //   And the owner’s balance should increase by 11 ETH
        //   And the contract’s balance should be 0
        //   And the goalReached should be true
        //   And the fundsWithdrawned should be true
        //   When the Charlie calls "refund()"
        //   Then the transaction should fail with SimpleCrowdfund__CampaignIsEnded()
        //   And the contract should not log a "Refunded" event

        uint256 eventFound = 0;

        vm.deal(address(2), 100e18);
        vm.recordLogs();
        simpleCrowdfund = new SimpleCrowdfund(address(1), 3600 * 24, 10 ether);
        console.log("Contract balance Before:", contractBalance);
        vm.prank(address(2));
        simpleCrowdfund.contribute{value: 7 ether}();
        checkBalance();
        console.log("Contract balance After:", contractBalance);
        console.log("Alice balance:", address(2).balance);

        assertEq(simpleCrowdfund.GetContributorsListLength(), 1, "its not 1");

        vm.prank(address(3));
        vm.deal(address(3), 100e18);
        simpleCrowdfund.contribute{value: 4 ether}();
        checkBalance();

        assertEq(simpleCrowdfund.GetContributorsListLength(), 2, "its not 2");
        assertEq(simpleCrowdfund.goalReached(), true, "Goal should be true!");
        assertEq(contractBalance, 11 ether);

        vm.prank(simpleCrowdfund.i_owner());
        simpleCrowdfund.withdraw();
        checkBalance();

        console.log("timepassed:", simpleCrowdfund.timePassed());
        console.log("goalreached:", simpleCrowdfund.goalReached());
        console.log("owners balance:", simpleCrowdfund.i_owner().balance);
        console.log("Contract balance After:", contractBalance);

        vm.startPrank(address(3));
        vm.expectRevert();
        simpleCrowdfund.refund();
        checkBalance();
        vm.stopPrank();

        console.log("Chalie's balance:", address(2).balance);
        console.log("Contract balance After:", contractBalance);
        assertEq(contractBalance, 0 ether);
        assertEq(simpleCrowdfund.fundsWithdrawned(), true);

        Vm.Log[] memory records = vm.getRecordedLogs();

        if (records[0].topics[0] == keccak256("Contributed(address,uint256)")) eventFound += 1;
        if (records[1].topics[0] == keccak256("Contributed(address,uint256)")) eventFound += 1;
        if (records[2].topics[0] == keccak256("Withdraw(address,uint256)")) eventFound += 1;
        if (records[2].topics[0] == keccak256("Refunded(address,uint256)")) eventFound += 1;

        console.log("records length:", records.length);
        assertEq(records.length, 3, "Different than 3");
        assertEq(eventFound, 3, "Number of events is not 3");

        assertEq(contractBalance, 0 ether, "Contract balance should be 0");
        assertEq(eventFound, 3, "Number of events is not 3");
    }

    function test_BackerRefundBeforeDeadline() public {
        // Scenario: The backers try to refund before the deadline
        //   Given the contract is deployed with goal = 10 ETH, deadline is in 1 day
        //   And user "Charlie" contributes 7 ETH
        //   And user "Diana" contributes 2 ETH
        //   Then the total amountRaised is 9 ETH
        //   And the goalReached is False
        //   And time is before the deadline
        //   When the Charlie calls "refund()"
        //   Then the transaction should fail with SimpleCrowdfund__CampaignIsNotEnded()
        //   And the contract should not log a "Refunded" event
        uint256 eventFound = 0;

        vm.deal(address(2), 100e18);
        vm.recordLogs();
        simpleCrowdfund = new SimpleCrowdfund(address(1), 3600 * 24, 10e18);
        console.log("Contract balance Before:", contractBalance);
        vm.prank(address(2));
        simpleCrowdfund.contribute{value: 7 ether}();
        checkBalance();
        console.log("Contract balance After:", contractBalance);
        console.log("Alice balance:", address(2).balance);

        assertEq(simpleCrowdfund.GetContributorsListLength(), 1, "its not 1");

        vm.prank(address(3));
        vm.deal(address(3), 100e18);
        simpleCrowdfund.contribute{value: 2 ether}();
        checkBalance();

        assertEq(simpleCrowdfund.GetContributorsListLength(), 2, "its not 2");
        assertEq(simpleCrowdfund.goalReached(), false, "Goal should be false!");
        assertEq(contractBalance, 9 ether);
        Vm.Log[] memory records = vm.getRecordedLogs();
        console.log("records length:", records.length);
        assertEq(records.length, 2, "Different than 2");
        if (records[0].topics[0] == keccak256("Contributed(address,uint256)")) eventFound += 1;
        if (records[1].topics[0] == keccak256("Contributed(address,uint256)")) eventFound += 1;
        assertEq(eventFound, 2, "Number of events is not 2");

        // Timetravel
        vm.warp(simpleCrowdfund.i_timeInitiation() + 3600 * 25); // 1 hour after deadline
        assertEq(simpleCrowdfund.timePassed(), true, "Deadline is not reached yet!"); // deadline is reached
        vm.prank(address(2));
        simpleCrowdfund.refund();
        checkBalance();

        console.log("Chalie's balance:", address(2).balance);
        assertEq(contractBalance, 2 ether);

        vm.prank(address(3));
        simpleCrowdfund.refund();
        checkBalance();

        console.log("Diana's balance:", address(3).balance);
        assertEq(contractBalance, 0 ether);

        if (records[0].topics[0] == keccak256("Refunded(address,uint256)")) eventFound += 1;
        if (records[1].topics[0] == keccak256("Refunded(address,uint256)")) eventFound += 1;
        assertEq(eventFound, 2, "Number of events is not 2");
    }

    function test_OwnerTryToRefund() public {
        // Scenario: The owner tries to refund
        //   Given the contract is deployed with goal = 10 ETH, deadline is in 1 day
        //   And user "Charlie" contributes 7 ETH
        //   And user "Diana" contributes 2 ETH
        //   Then the total amount Raised is 9 ETH
        //   And the goalReached is False
        //   And time is after the deadline
        //   When the owner calls "refund()"
        //   Then the transaction should fail with SimpleCrowdfund__CampaignIsEnded()
        //   And the contract should not log a "Refunded" event
        uint256 eventFound = 0;

        simpleCrowdfund = new SimpleCrowdfund(address(1), 3600 * 24, 10 ether);
        vm.recordLogs();
        vm.deal(address(2), 100 ether);
        vm.prank(address(2));
        simpleCrowdfund.contribute{value: 7 ether}();
        checkBalance();
        console.log("Contranct balance", contractBalance);

        vm.deal(address(3), 100 ether);
        vm.prank(address(3));
        simpleCrowdfund.contribute{value: 2 ether}();
        checkBalance();
        console.log("Contranct balance", contractBalance);

        assertEq(contractBalance, 9 ether, "Contract balance should be 9 ether");
        assertEq(simpleCrowdfund.goalReached(), false, "Goal should be not reached");

        vm.warp(simpleCrowdfund.i_timeInitiation() + simpleCrowdfund.i_secToComplete() + 3600);

        vm.prank(address(1));
        vm.expectRevert();
        simpleCrowdfund.refund();
        checkBalance();
        assertEq(contractBalance, 9 ether, "contract balance should be 9 eth");
        Vm.Log[] memory records = vm.getRecordedLogs();
        assertEq(records.length, 2, "There should be only 2 event emmited");
        if (records[0].topics[0] == keccak256("Contributed(address,uint256)")) eventFound += 1;
        if (records[1].topics[0] == keccak256("Contributed(address,uint256)")) eventFound += 1;
        assertEq(eventFound, 2, "There should be 2 events emited");
    }

    function test_OwnerTryToRefundBeforeDeadline() public {
        // Scenario: The owner tries to refund before the deadline
        //   Given the contract is deployed with goal = 10 ETH, deadline is in 1 day
        //   And user "Charlie" contributes 7 ETH
        //   And user "Diana" contributes 2 ETH
        //   Then the total amountRaised is 9 ETH
        //   And the goalReached is False
        //   And time is before the deadline
        //   When the owner calls "refund()"
        //   Then the transaction should fail with SimpleCrowdfund__NoPermission()
        //   And the contract should not log a "Refunded" event
        uint256 eventFound = 0;

        simpleCrowdfund = new SimpleCrowdfund(address(1), 3600 * 24, 10 ether);
        vm.recordLogs();
        vm.deal(address(2), 100 ether);
        vm.prank(address(2));
        simpleCrowdfund.contribute{value: 7 ether}();
        checkBalance();
        console.log("Contranct balance", contractBalance);

        vm.deal(address(3), 100 ether);
        vm.prank(address(3));
        simpleCrowdfund.contribute{value: 2 ether}();
        checkBalance();
        console.log("Contranct balance", contractBalance);

        assertEq(contractBalance, 9 ether, "Contract balance should be 9 ether");
        assertEq(simpleCrowdfund.goalReached(), false, "Goal should be not reached");

        vm.warp(simpleCrowdfund.i_timeInitiation() + simpleCrowdfund.i_secToComplete() + 3600);

        vm.prank(address(1));
        vm.expectRevert(SimpleCrowdfund.SimpleCrowdfund__CampaignIsEnded.selector);
        simpleCrowdfund.refund();
        checkBalance();
        assertEq(contractBalance, 9 ether, "contract balance should be 9 eth");
        Vm.Log[] memory records = vm.getRecordedLogs();
        assertEq(records.length, 2, "There should be only 2 event emmited");
        if (records[0].topics[0] == keccak256("Contributed(address,uint256)")) eventFound += 1;
        if (records[1].topics[0] == keccak256("Contributed(address,uint256)")) eventFound += 1;
        assertEq(eventFound, 2, "There should be 2 events emited");
    }
}
