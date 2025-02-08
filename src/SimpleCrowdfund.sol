// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

contract SimpleCrowdfund {
    bool public campaignEnded;
    bool public goalReached;
    bool public fundsWithdrawned;

    uint256 public constant MINIMAL_AMOUNT = 1e15; // ~3$

    address public immutable i_owner = payable(msg.sender);
    uint256 public immutable i_timeInitiation = block.timestamp; // Setting up initiation time
    uint256 public immutable GOAL = 2e18; //2 eth in wei
    uint256 public immutable i_secToComplete;
    uint256 public immutable i_deadline = i_timeInitiation + i_secToComplete; // final time to complete the task

    address[] public s_ContributorsList;

    event Contributed(address contributor, uint256 amount);
    event Withdraw(address owner, uint256 amount);
    event Refunded(address contributor, uint256 amount);

    mapping(address contributor => uint256 amountDonated) internal s_contributorToAmount;
    mapping(address contributor => bool isContributor) private s_alreadyContributed;

    error SimpleCrowdfund__NoPermission();
    error SimpleCrowdfund__ZeroAddress();
    error SimpleCrowdfund__ToLittleDonation();
    error SimpleCrowdfund__CampaignIsNotEnded();
    error SimpleCrowdfund__CampaignIsEnded();
    error SimpleCrowdfund__CallFailed();
    error SimpleCrowdfund__TimeOut();

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert SimpleCrowdfund__NoPermission();
        _;
    }

    modifier isWithdrawned( // test that modifier
    ) {
        if (fundsWithdrawned) revert SimpleCrowdfund__CampaignIsEnded();
        _;
    }

    modifier isGoalReached( // test that modifier
    ) {
        if ((address(this).balance) - msg.value >= GOAL) revert SimpleCrowdfund__CampaignIsEnded();
        if (goalReached) revert SimpleCrowdfund__CampaignIsEnded(); //Second check in case of double withdraw
        _;
    }

    constructor(address _owner, uint256 _secToComplete, uint256 _GOAL) {
        if (_owner == address(0)) {
            revert SimpleCrowdfund__ZeroAddress();
        }
        i_owner = _owner;
        i_timeInitiation = block.timestamp;
        GOAL = _GOAL;
        i_secToComplete = _secToComplete;
        i_deadline = i_timeInitiation + _secToComplete;
    }

    function contribute() public payable isWithdrawned isGoalReached {
        // Check: If a user calls contribute() after the deadline, the call should revert or fail.
        // The contract should keep track of the total amount raised. Check: Every time function is envoke, check if goal is reached

        if (msg.value < MINIMAL_AMOUNT) revert SimpleCrowdfund__ToLittleDonation();
        if ((address(this).balance) - msg.value >= GOAL) goalReached = true;
        if (timePassed()) revert SimpleCrowdfund__CampaignIsEnded();

        if (s_alreadyContributed[msg.sender] == false) {
            s_ContributorsList.push(msg.sender);
            s_contributorToAmount[msg.sender] = s_contributorToAmount[msg.sender] + msg.value;
            s_alreadyContributed[msg.sender] = true;
            emit Contributed(msg.sender, msg.value);
            if (address(this).balance >= GOAL) goalReached = true;
        } else {
            s_contributorToAmount[msg.sender] = s_contributorToAmount[msg.sender] + msg.value;
            emit Contributed(msg.sender, msg.value);
            if (address(this).balance >= GOAL) goalReached = true;
        }
    }

    receive() external payable {
        contribute();
    }

    fallback() external payable {
        contribute();
    }

    function withdraw() public onlyOwner isWithdrawned {
        // DONE check: only the Project Owner should be able to withdraw the entire balance.
        // DONE check: If the goal is reached on or before the deadline, only the Project Owner should be able to withdraw the entire balance.
        // DONE check: If the owner tries to call withdraw() before the deadline but the goal isn’t reached yet, it should fail.
        // DONE check: If the user calling withdraw() is not the Project Owner, it should fail.
        // check: After withdraw user should not be able to contribute more
        // If the user calling withdraw() is not the Project Owner, it should fail.

        if (address(this).balance >= GOAL && fundsWithdrawned == false) {
            (bool callSuccess,) = payable(i_owner).call{value: address(this).balance}("");
            if (!callSuccess) revert SimpleCrowdfund__CallFailed();
            else emit Withdraw(i_owner, address(this).balance);
            fundsWithdrawned = true;
        } else {
            revert SimpleCrowdfund__CampaignIsNotEnded();
        }
    }

    function refund() public isWithdrawned {
        // check: If the goal is not reached by the time the deadline passes, backers should be able to get their ETH back by calling refund()
        // check:  If the goal is reached or if we are still before the deadline, calling refund() should fail.
        if (timePassed() && address(this).balance < GOAL) {
            if (s_alreadyContributed[msg.sender] == true) {
                (bool callSuccess,) = payable(msg.sender).call{value: s_contributorToAmount[msg.sender]}("");
                if (!callSuccess) revert SimpleCrowdfund__CallFailed();
                else emit Refunded(msg.sender, s_contributorToAmount[msg.sender]);
            } else {
                revert SimpleCrowdfund__NoPermission();
            }
        }
    }

    function timePassed() public view returns (bool isEnded) {
        uint256 currentTimestamp = block.timestamp;
        if (currentTimestamp > i_timeInitiation + i_secToComplete) {
            return true;
        }
    }

    //Getter functions

    function GetContributorsListLength() external view returns (uint256) {
        return s_ContributorsList.length;
    }

    function GetContributorToAmount(address _contributor) external view returns (uint256) {
        return s_contributorToAmount[_contributor];
    }
}
