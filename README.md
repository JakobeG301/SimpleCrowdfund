# 🚀SimpleCrowdfund

A simple crowdfunding smart contract written in Solidity using Foundry for testing. The contract allows users to contribute ETH to a campaign. If the funding goal is met, the owner can withdraw the funds. If the goal is not met before the deadline, contributors can get refunds.

---

## ✨Features

- Users can contribute ETH to the campaign.
- A minimum contribution of **0.001 ETH** is required.
- If the goal is met before the deadline, the owner can withdraw the funds.
- If the goal is **not met**, contributors can request a refund.
- Automatic tracking of contributors and their donations.

---

## 🧱Installation

1. Install **Foundry** (if not installed):  
   ```sh
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. Clone this repository:  
   ```sh
   git clone <repo-url>
   cd <repo-folder>
   ```

3. Install dependencies:  
   ```sh
   forge install
   ```

---

## 🧪Testing

Run all tests using Foundry:
   ```sh
   forge test
   ```
To see detailed logs:
   ```sh
   forge test -vv
   ```

---

## 📜ABI

The Application Binary Interface (ABI) allows interaction with the smart contract. Here is the ABI:
```json
[
  {
    "inputs": [
      { "internalType": "address", "name": "_owner", "type": "address" },
      { "internalType": "uint256", "name": "_timeToComplete", "type": "uint256" },
      { "internalType": "uint256", "name": "_goalAmount", "type": "uint256" }
    ],
    "stateMutability": "nonpayable",
    "type": "constructor"
  },
  {
    "inputs": [],
    "name": "contribute",
    "outputs": [],
    "stateMutability": "payable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "withdraw",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "refund",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }
]
```

---

## 🔐Security Considerations

- Only the contract owner can withdraw funds.
- Contributors can only refund if the goal is **not met**.
- Prevents double withdrawals and multiple refunds.

---

## 🎯Future Improvements

- Support for multiple campaigns.
- More detailed error messages.
- UI for easy interaction.

---

## License
This project is licensed under the **MIT License**.

