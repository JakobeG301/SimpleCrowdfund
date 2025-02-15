// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

contract SimpleCrowdfund {
    bool public goalReached;
    bool public fundsWithdrawned;

    uint256 public constant MINIMAL_AMOUNT = 1e15; // ~3$

    address public immutable i_owner;
    uint256 public immutable i_timeInitiation; // Setting up initiation time
    uint256 public immutable i_goal;
    uint256 public immutable i_secToComplete;
    uint256 public immutable i_deadline; // final time to complete the task

    address[] public s_ContributorsList;

    event Contributed(address contributor, uint256 amount);
    event Withdraw(address owner, uint256 amount);
    event Refunded(address contributor, uint256 amount);

    mapping(address contributor => uint256 amountDonated) internal s_contributorToAmount;
    mapping(address contributor => bool isContributor) internal s_alreadyContributed;

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

    modifier isWithdrawned( 
    ) {
        if (fundsWithdrawned) revert SimpleCrowdfund__CampaignIsEnded();
        _;
    }

    modifier isGoalReached( 
    ) {
        if ((address(this).balance) - msg.value >= i_goal) revert SimpleCrowdfund__CampaignIsEnded();
        if (goalReached) revert SimpleCrowdfund__CampaignIsEnded(); //Second check in case of double withdraw
        _;
    }

    constructor(address _owner, uint256 _secToComplete, uint256 _goal) {
        if (_owner == address(0)) {
            revert SimpleCrowdfund__ZeroAddress();
        }
        i_owner = _owner;
        i_timeInitiation = block.timestamp;
        i_goal = _goal;
        i_secToComplete = _secToComplete;
        i_deadline = i_timeInitiation + _secToComplete;
    }

    function contribute() public payable isWithdrawned isGoalReached {
        // check: If a user calls contribute() after the deadline, the call should revert or fail.
        // check: The contract should keep track of the total amount raised. Check: Every time function is envoke, check if goal is reached

        if (msg.value < MINIMAL_AMOUNT) revert SimpleCrowdfund__ToLittleDonation();
        if ((address(this).balance) - msg.value >= i_goal) goalReached = true;
        if (timePassed()) revert SimpleCrowdfund__CampaignIsEnded();

        if (s_alreadyContributed[msg.sender] == false) {
            s_ContributorsList.push(msg.sender);
            s_contributorToAmount[msg.sender] = s_contributorToAmount[msg.sender] + msg.value;
            s_alreadyContributed[msg.sender] = true;
            emit Contributed(msg.sender, msg.value);
            if (address(this).balance >= i_goal) goalReached = true;
        } else {
            s_contributorToAmount[msg.sender] = s_contributorToAmount[msg.sender] + msg.value;
            emit Contributed(msg.sender, msg.value);
            if (address(this).balance >= i_goal) goalReached = true;
        }
    }

    receive() external payable {
        contribute();
    }

    fallback() external payable {
        contribute();
    }

    function withdraw() public onlyOwner isWithdrawned {
        // check: only the Project Owner should be able to withdraw the entire balance.
        // check: If the goal is reached on or before the deadline, only the Project Owner should be able to withdraw the entire balance.
        // check: If the owner tries to call withdraw() before the deadline but the goal isn’t reached yet, it should fail.
        // check: If the user calling withdraw() is not the Project Owner, it should fail.
        // check: After withdraw user should not be able to contribute more
        // check: If the user calling withdraw() is not the Project Owner, it should fail.

        if (address(this).balance >= i_goal && fundsWithdrawned == false) {
            (bool callSuccess,) = payable(i_owner).call{value: address(this).balance}("");
            if (!callSuccess) revert SimpleCrowdfund__CallFailed();
            if (timePassed()) {
                revert SimpleCrowdfund__CampaignIsEnded();
            } else {
                emit Withdraw(i_owner, address(this).balance);
                fundsWithdrawned = true;
            }
        } else {
            revert SimpleCrowdfund__CallFailed();
        }
    }

    function refund() public isWithdrawned {
        // check: If the goal is not reached by the time the deadline passes, backers should be able to get their ETH back by calling refund()
        // check:  If the goal is reached or if we are still before the deadline, calling refund() should fail.
        if (timePassed() && address(this).balance < i_goal && msg.sender != i_owner) {
            if (s_alreadyContributed[msg.sender] == true) {
                (bool callSuccess,) = payable(msg.sender).call{value: s_contributorToAmount[msg.sender]}("");
                if (!callSuccess) {
                    revert SimpleCrowdfund__CallFailed();
                } else {
                    emit Refunded(msg.sender, s_contributorToAmount[msg.sender]);
                    s_contributorToAmount[msg.sender] = 0 ether;
                }
            }
        } else if (timePassed() || goalReached == true) {
            revert SimpleCrowdfund__CampaignIsEnded();
        } else {
            revert SimpleCrowdfund__NoPermission();
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
