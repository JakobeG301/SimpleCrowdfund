// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {Test, Vm, console} from "lib/forge-std/src/Test.sol";
import {SimpleCrowdfund} from "../src/SimpleCrowdfund.sol";

contract SimpleCrowdfundTest is Test {
    SimpleCrowdfund simpleCrowdfund;

    function setUp() external {
        address _owner = address(this);
        uint256 _secToComplete = 30;
        uint256 _GOAL = 2e18;

        simpleCrowdfund = new SimpleCrowdfund(_owner, _secToComplete, _GOAL);

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
        //  And the campaignEnded should be false
        //  And the goalReached should be false
        //  And the fundsWithdrawned should be false
        //  And the minimalAmount should be 0.001 ETH
        //  And the ContributorsList should be empty
        vm.deal(address(2), 100e18);
        vm.recordLogs();
        console.log("balance:", address(simpleCrowdfund).balance);
        address _owner = address(this);
        uint256 contractBalance = address(simpleCrowdfund).balance;

        assertEq(simpleCrowdfund.i_owner(), _owner);
        console.log("balance:", address(simpleCrowdfund).balance);
        assertEq(address(simpleCrowdfund).balance, 0);
        console.log("secondsToComplete:", simpleCrowdfund.i_secToComplete());
        console.log("timeInitiation:", simpleCrowdfund.i_timeInitiation());
        console.log("deadline:", simpleCrowdfund.i_deadline());
        assertEq(simpleCrowdfund.i_deadline(), simpleCrowdfund.i_secToComplete() + block.timestamp);
        assertEq(simpleCrowdfund.GOAL(), 2e18);
        assertEq(simpleCrowdfund.amountRaised(), 0);
        assertEq(simpleCrowdfund.campaignEnded(), false);
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

        console.log("MINIMAL_AMOUNT:", simpleCrowdfund.MINIMAL_AMOUNT());
        console.log("Current goal reached:", simpleCrowdfund.goalReached());
        console.log("Funds withdrawn:", simpleCrowdfund.fundsWithdrawned());
        console.log("Time passed:", simpleCrowdfund.timePassed());

        assertEq(simpleCrowdfund.GetContributorToAmount(address(2)) ==  1 ether, true,  "Value is not mapped!");
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
        console.log("Contract balance Before:", address(simpleCrowdfund).balance);
        vm.deal(address(2), 100e18);
        vm.prank(address(2));

        (bool success,) = payable(address(simpleCrowdfund)).call{value: 0.001 ether}("");
        console.log("Contract balance After:", address(simpleCrowdfund).balance);
        console.log("Robert balance:", address(2).balance);
        // console.log( "Array length4:",simpleCrowdfund.GetContributorsListLength());
        // assertEq(simpleCrowdfund.GetContributorsListLength(), 1, "its not 1");
        Vm.Log[] memory records = vm.getRecordedLogs();
        console.log("records length:", records.length);
        assertEq(records.length, 1, "Different than 1");
        assertEq(simpleCrowdfund.amountRaised(), 0.001 ether);

        assertEq(simpleCrowdfund.GetContributorToAmount(address(2)) ==  0.001 ether, true,  "Value is not mapped!");
        console.log("Amount mapped:", simpleCrowdfund.GetContributorToAmount(address(2)));

        assertEq(address(simpleCrowdfund).balance, 0.001 ether);

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
        Vm.Log[] memory records = vm.getRecordedLogs();
        assertEq(address(simpleCrowdfund).balance, 0, "Balance should be 0 ETH");
        assertEq(simpleCrowdfund.GetContributorToAmount(address(2)) ==  0 ether, true,  "Value is mapped!");
        console.log("Amount mapped:", simpleCrowdfund.GetContributorToAmount(address(2)));
        assertEq(records.length, 0, "Event was emited!");
        assertEq(simpleCrowdfund.amountRaised(), 0 ether);
        assertEq(simpleCrowdfund.amountRaised(), 0, "Amount raised is more than 0");
    }

    function test_SendByFallback() public {
        // Scenario: Contributing through the fallback function
        // Given the contract is deployed with Bob's address, goal = 2 ETH, deadline is in 1 day and minimalAmount = 0.001 ETH
        // And the Robert has 100 ETH in his wallet
        // When Robert sends 0.001 ETH to the contract with not matching function signature
        // Then the amountRaised in the contract should be 0.001 ETH
        // And the contribution mapping for Robert should be 0.001 ETH
        // And the contract should log a "Contributed" event with (Robert, 0.001 ETH)
        
        vm.deal(address(2), 100e18);
        vm.recordLogs();
        simpleCrowdfund = new SimpleCrowdfund(address(1), 3600, 2e18);
        vm.deal(address(2), 100 ether);
        vm.prank(address(2));
        vm.expectRevert(SimpleCrowdfund.SimpleCrowdfund__ToLittleDonation.selector);
        (bool success,) = payable(address(simpleCrowdfund)).call{value: 0.001 ether}("0x12");
        assertEq(success, true, "Transaction failed");
        Vm.Log[] memory records = vm.getRecordedLogs();
        assertEq(address(simpleCrowdfund).balance, 0.001 ether, "Balance should be 0.001 ether");
        assertEq(simpleCrowdfund.GetContributorToAmount(address(2)) ==  0.001 ether, true,  "Value is not mapped!");
        console.log("Amount mapped:", simpleCrowdfund.GetContributorToAmount(address(2)));
        assertEq(records.length, 1, "Event was not emited!");
        assertEq(simpleCrowdfund.amountRaised(), 0.001 ether);
        assertEq(simpleCrowdfund.amountRaised(), 0.001 ether, "Amount raised is not the 0.001 ether");
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

        (bool success,) = payable(address(simpleCrowdfund)).call{value: 0.0001 ether}("0x12");
        
        assertEq(success, false, "Transaction succed, but shouldn't");
        Vm.Log[] memory records = vm.getRecordedLogs();
        assertEq(address(simpleCrowdfund).balance, 0 ether, "Balance should be 0 ether");
        assertEq(simpleCrowdfund.GetContributorToAmount(address(2)) ==  0 ether, true,  "Value is mapped!");
        console.log("Amount mapped:", simpleCrowdfund.GetContributorToAmount(address(2)));
        assertEq(records.length, 0, "Event was emited!");
        assertEq(simpleCrowdfund.amountRaised(), 0 ether);
        assertEq(simpleCrowdfund.amountRaised(), 0 ether, "Amount raised is more than 0 ether");
        
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
        simpleCrowdfund.contribute{value: 0.0001 ether}();
        vm.expectRevert(SimpleCrowdfund.SimpleCrowdfund__ToLittleDonation.selector);
        assertEq(address(simpleCrowdfund).balance, 0, "Balance should be 0 ETH");
        assertEq(simpleCrowdfund.GetContributorToAmount(address(2)) ==  0.001 ether, true,  "Value is not mapped!");
        console.log("Amount mapped:", simpleCrowdfund.GetContributorToAmount(address(2)));
        Vm.Log[] memory records = vm.getRecordedLogs();
        assertEq(records.length, 0, "Event was emmited!");
        assertEq(simpleCrowdfund.amountRaised(), 0 ether);
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
        console.log("Contract balance Before:", address(simpleCrowdfund).balance);
        vm.deal(address(2), 100e18);
        vm.prank(address(2));

        simpleCrowdfund.contribute{value: 0.002 ether}();
        console.log("Contract balance After:", address(simpleCrowdfund).balance);
        console.log("Robert balance:", address(2).balance);
        // console.log( "Array length4:",simpleCrowdfund.GetContributorsListLength());
        // assertEq(simpleCrowdfund.GetContributorsListLength(), 1, "its not 1");
        Vm.Log[] memory records = vm.getRecordedLogs();
        console.log("records length:", records.length);
        assertEq(records.length, 1, "Different than 1");
        assertEq(simpleCrowdfund.amountRaised(), 0.002 ether);
        assertEq(address(simpleCrowdfund).balance, 0.002 ether);
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
        console.log("Contract balance Before:", address(simpleCrowdfund).balance);
        vm.deal(address(2), 100e18);
        vm.prank(address(2));

        simpleCrowdfund.contribute{value: 0.001 ether}();
        console.log("Contract balance After:", address(simpleCrowdfund).balance);
        console.log("Robert balance:", address(2).balance);
        // console.log( "Array length4:",simpleCrowdfund.GetContributorsListLength());
        // assertEq(simpleCrowdfund.GetContributorsListLength(), 1, "its not 1");
        Vm.Log[] memory records = vm.getRecordedLogs();
        console.log("records length:", records.length);
        assertEq(records.length, 1, "Different than 1");
        assertEq(simpleCrowdfund.amountRaised(), 0.001 ether);
        assertEq(address(simpleCrowdfund).balance, 0.001 ether);
    }


    function test_OneWeiBelowMinimumEth() public{
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
        simpleCrowdfund.contribute{value: 1e15- 1}();
        assertEq(address(simpleCrowdfund).balance, 0, "Balance should be 0 ETH");
        assertEq(simpleCrowdfund.GetContributorToAmount(address(2)) ==  0 , true,  "Value is not mapped!");
        console.log("Amount mapped:", simpleCrowdfund.GetContributorToAmount(address(2)));
        Vm.Log[] memory records = vm.getRecordedLogs();
        assertEq(simpleCrowdfund.amountRaised(), 0 ether);
        assertEq(records.length, 0, "Event was emmited!");
    }

    function test_OneWeiAboveMinimumEth() public{
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
        console.log("Contract balance Before:", address(simpleCrowdfund).balance);
        vm.deal(address(2), 100e18);
        vm.prank(address(2));

        simpleCrowdfund.contribute{value: 0.001 ether + 1 wei}();
        console.log("Contract balance After:", address(simpleCrowdfund).balance);
        console.log("Robert balance:", address(2).balance);
        // console.log( "Array length4:",simpleCrowdfund.GetContributorsListLength());
        // assertEq(simpleCrowdfund.GetContributorsListLength(), 1, "its not 1");
        Vm.Log[] memory records = vm.getRecordedLogs();
        console.log("records length:", records.length);
        assertEq(records.length, 1, "Different than 1");
        assertEq(simpleCrowdfund.amountRaised(), 0.001 ether + 1 wei);
        assertEq(address(simpleCrowdfund).balance, 0.001 ether + 1 wei, "Contribute failed!");

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
        console.log("Contract balance Before:", address(simpleCrowdfund).balance);
        vm.deal(address(2), 100e18);
        vm.prank(address(2));

        simpleCrowdfund.contribute{value: 5 ether}();
        console.log("Contract balance After:", address(simpleCrowdfund).balance);
        console.log("Robert balance:", address(2).balance);
        // console.log( "Array length4:",simpleCrowdfund.GetContributorsListLength());
        // assertEq(simpleCrowdfund.GetContributorsListLength(), 1, "its not 1");
        Vm.Log[] memory records = vm.getRecordedLogs();
        console.log("records length:", records.length);
        assertEq(records.length, 1, "Different than 1");
        if (records[0].topics[0] == keccak256("Contributed(address,uint256)")) eventFound = true;
        assertEq(eventFound, true, "No event was emitet!");

        assertEq(simpleCrowdfund.goalReached(), false, "Goal should be false!");
        assertEq(simpleCrowdfund.amountRaised(), 5 ether);
        assertEq(address(simpleCrowdfund).balance, 5 ether);
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
        console.log("Contract balance Before:", address(simpleCrowdfund).balance);
        vm.deal(address(2), 100e18);
        vm.prank(address(2));
        vm.expectRevert(SimpleCrowdfund.SimpleCrowdfund__CampaignIsEnded.selector);
        simpleCrowdfund.contribute{value: 1 ether}();
        console.log("Contract balance After:", address(simpleCrowdfund).balance);
        console.log("Robert balance:", address(2).balance);

        Vm.Log[] memory records = vm.getRecordedLogs();
        console.log("records length:", records.length);
        assertEq(records.length, 0, "Different than 0");
        // if (records[0].topics[0] == keccak256("Contributed(address,uint256)")) eventFound = true;
        // assertEq(eventFound, true, "No event was emitet!");

        assertEq(simpleCrowdfund.goalReached(), false, "Goal should be false!");
        assertEq(simpleCrowdfund.amountRaised(), 0 ether);
        assertEq(address(simpleCrowdfund).balance, 0 ether);

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
        console.log("Contract balance Before:", address(simpleCrowdfund).balance);
        vm.deal(address(2), 100e18);
        vm.prank(address(2));
        simpleCrowdfund.contribute{value: 7 ether}();
        console.log("Contract balance After:", address(simpleCrowdfund).balance);
        console.log("Robert balance:", address(2).balance);
        // console.log( "Array length4:",simpleCrowdfund.GetContributorsListLength());
        // assertEq(simpleCrowdfund.GetContributorsListLength(), 1, "its not 1");
        Vm.Log[] memory records = vm.getRecordedLogs();
        console.log("records length:", records.length);
        assertEq(records.length, 1, "Different than 1");
        if (records[0].topics[0] == keccak256("Contributed(address,uint256)")) eventFound = true;
        assertEq(eventFound, true, "No event was emitet!");

        assertEq(simpleCrowdfund.goalReached(), false, "Goal should be false!");
        assertEq(simpleCrowdfund.amountRaised(), 7 ether);
        assertEq(address(simpleCrowdfund).balance, 7 ether);

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
        
        vm.deal(address(2), 100e18);
        vm.recordLogs();
        simpleCrowdfund = new SimpleCrowdfund(address(1), 60, 10 ether);
        vm.deal(address(3), 100e18);
        vm.prank(address(3));
        simpleCrowdfund.contribute{value: 6 ether}();

        vm.deal(address(4), 100e18);
        vm.prank(address(4));
        simpleCrowdfund.contribute{value: 3 ether}();

        
        console.log("Contract balance Before:", address(simpleCrowdfund).balance);
        vm.deal(address(2), 100e18);
        vm.prank(address(2));
        vm.expectRevert(SimpleCrowdfund.SimpleCrowdfund__CampaignIsEnded.selector);
        simpleCrowdfund.contribute{value: 1 ether}();
        console.log("Contract balance After:", address(simpleCrowdfund).balance);
        console.log("Alice balance:", address(2).balance);

        Vm.Log[] memory records = vm.getRecordedLogs();
        console.log("records length:", records.length);
        assertEq(records.length, 2, "Different than 1");
        if (records[0].topics[0] == keccak256("Contributed(address,uint256)")) eventFound += 1;
        if (records[0].topics[0] == keccak256("Contributed(address,uint256)")) eventFound += 1;
        assertEq(eventFound, 2);

        assertEq(simpleCrowdfund.goalReached(), false, "Goal should be false!");
        assertEq(simpleCrowdfund.amountRaised(), 0 ether);
        assertEq(address(simpleCrowdfund).balance, 0 ether);
    }

    function test_AddingContributors() public {
        // Scenario: Adding contributors to the list
        //   Given the contract is deployed with goal = 10 ETH, deadline is in 1 day
        //   And user "Alice" contributes 7 ETH
        //   And user "Bob" contributes 3 ETH
        //   Then the total amountRaised is 10 ETH
        //   And Alice and Bob should be in the ContributorsList
        //   And the contract should log a "Contributed" event for Alice and Bob
    }

    function test_AddingContributorTwice() public {
        // Scenario: Adding the same contributor twice
        //   Given the contract is deployed with goal = 10 ETH, deadline is in 1 day
        //   And user "Alice" contributes 7 ETH
        //   And user "Alice" contributes 3 ETH
        //   Then the total amountRaised is 10 ETH
        //   And Alice should be in the ContributorsList only once
        //   And the contract should log a "Contributed" event for Alice twice
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
    }

    function test_ContributeAfterRefund() public {
        // Scenario: Attempting to contribute after backers has refunded the funds
        //   Given the contract is deployed with goal = 10 ETH, deadline is in 1 day
        //   And user "Charlie" contributes 7 ETH
        //   When the Deadline is reached and the goal is not reached
        //   And the backers calls "refund()"
        //   Then the transaction should succeed
        //   And the contract should log a "Refunded" event
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
    }

    function test_OwnerWithdrawWhenGoalNotReachedYet() public {
        // Scenario: The owner withdraws when the goal is not reached yet
    }

    function test_NotTheOwnerWithdrawGoalNotReachedYet() public {
        // Scenario: A user that is not the owner tries to withdraw when the goal is not reached yet
    }

    function test_NotTheOwnerWithdrawGoalReached() public {
        // Scenario: A user that is not the owner tries to withdraw when the goal is reached
    }

    function test_OwnerWithdrawTwice() public {
        // Scenario: The owner withdraws twice after the goal is reached
    }

    function test_OwnerWithdrawAfterRefund() public {
        // Scenario: The owner withdraws after the backers have refunded
    }

    function test_OwnerWithdrawBeforeDeadline() public {
        // Scenario: The owner withdraws before the deadline
    }

    function test_OwnerWithdrawAfterDeadline() public {}

    /*/////////////////////////////////////////////////////////////////////////////
                                    Refund Section
    /////////////////////////////////////////////////////////////////////////////*/

    function BackerRefundGoalNotReached() public {
        // Scenario: The goal is reached on time, then the owner withdraws
        //   Given the contract is deployed with goal = 10 ETH, deadline is in 1 day
        //   And user "Charlie" contributes 7 ETH
        //   And user "Diana" contributes 3 ETH
        //   Then the total amountRaised is 10 ETH
        //   When the deadline is reached
        //   And the backers call "refund()"
        //   Then the transaction should succeed
        //   And the contract should log a "Refunded" event for Charlie and Diana
        //   And the Charlie and Diana’s balances should increase by 7 ETH and 3 ETH respectively
        //   And the contract’s balance should be 0
        //   And the goalReached should be false
        //   And the fundsWithdrawned should be false
        //   And the campaignEnded should be true
    }

    function BackerRefundGoalReached() public {
        // Scenario: The goal is reached on time, then the backers try to refund
        //   Given the contract is deployed with goal = 10 ETH, deadline is in 1 day
        //   And user "Charlie" contributes 7 ETH
        //   And user "Diana" contributes 4 ETH
        //   Then the total amountRaised is 11 ETH
        //   And the goalReached is true
        //   When the Charlie call "refund()"
        //   Then the transaction should revert with SimpleCrowdfund__NoPermission()
        //   And the contract should not log a "Refunded" event
    }

    //Finish after code is finished
}
