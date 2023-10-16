<a name="readme-top"></a>

[![Unit Tests](https://github.com/PeterMcQuaid/LuckyEther/actions/workflows/build.yaml/badge.svg)](https://github.com/PeterMcQuaid/LuckyEther/actions/workflows/build.yaml) 
 [![Coverage Status](https://coveralls.io/repos/github/PeterMcQuaid/LuckyEther/badge.svg?branch=master)](
https://coveralls.io/github/PeterMcQuaid/LuckyEther?branch=master)
[![Solidity](https://img.shields.io/badge/solidity-0.8.20-blue.svg)](https://github.com/ethereum/solidity/releases/tag/v0.8.20) 
 [![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
 [![Chainlink](https://img.shields.io/badge/Powered%20by%20Chainlink-375BD2?logo=chainlink&logoColor=white)](https://chain.link/)


<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/PeterMcQuaid/LuckyEther/images">
    <img src="https://raw.githubusercontent.com/PeterMcQuaid/LuckyEther/main/images/logo.JPG" alt="Logo">
  </a>

  <h3 align="center">LuckyEther</h3>

  <p align="center">
    Transforming Lotteries: Fair, Fast, and Fully Automated with LuckyEther
    <br />
    <a href="https://github.com/PeterMcQuaid/LuckyEther#installation"><strong>Setup & Installation »</strong></a>
    <br />
    <br />
    <a href="https://github.com/PeterMcQuaid/LuckyEther#contributions">Contribute to LuckyEther</a>
    ·
    <a href="https://github.com/PeterMcQuaid/LuckyEther/issues">Report Bug</a>
    ·
    <a href="https://github.com/PeterMcQuaid/LuckyEther/issues">Request Feature</a>
  </p>
</div>


## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Project Layout](#project-layout)
- [Roadmap](#project-roadmap)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Testing](#testing)
- [Static Analysis](#static-analysis)
- [Deployments](#deployments)
- [Legal Disclaimer](#legal-disclaimer)
- [Contributions](#contributions)
- [License](#license)

## Introduction

LuckyEther is a decentralized, fully-automated lottery project. Prize draws occur daily, and utilize Chainlink's VRF and Automation workflows to provide a provably fair, decentralized lottery. Winners have 12 hours to claim their pot, otherwise their winnings role over into the next prize pot.

LuckyEther is fully upgradeable and pausable and aims to take full advantage of the liquidity and low fees that exist in top layer 2 protocols.

## Features

- Fully-decentralized lottery
- Fully automated with Chainlink Automation
- Verifiably random with Chainlink VRF
- Contract fully pausable 
- Contract fully upgradeable through the OpenZeppelin Transparent Proxy
- Prize pot rolls over if unclaimed
- New lottery draw every 24 hours
- To be launched on Ethereum mainnet as well as Arbitrum One layer 2

## Project Layout
```
.
├── CHANGELOG.md
├── Makefile
├── README.md
├── foundry.toml
├── images
│   └── logo.JPG
├── lib
│   ├── chainlink
│   ├── forge-std
│   ├── foundry-devops
│   ├── openzeppelin-contracts
│   ├── openzeppelin-contracts-upgradeable
│   └── solmate
├── script
│   ├── DeployLotteryContract.s.sol
│   ├── DeployPauserRegistry.s.sol
│   ├── HelperConfig.s.sol
│   └── Interactions.s.sol
├── src
│   ├── contracts
│   │   ├── core
│   │   ├── interfaces
│   │   ├── libraries
│   │   └── permissions
│   └── test
│       └── mocks
└── test
    ├── integration
    │   ├── DeployScripts.t.sol
    │   └── Integrations.t.sol
    ├── mocks
    │   └── LinkToken.sol
    └── unit
        ├── EmptyContract.t.sol
        ├── LinkTokenMock.t.sol
        ├── LotteryMainLogic.t.sol
        ├── LotteryPausable.t.sol
        ├── LotteryReentrancy.t.sol
        └── PauserRegistryTest.t.sol
```

## Roadmap

- [x] **Testnets:**
  - Arbitrum Goerli
  - Sepolia

- [ ] **Coming Soon:**
  - Arbitrum One
  - Ethereum Mainnet


## Prerequisites

- Forge 0.2.0

This repository uses Foundry as a smart contract development toolchain. If you do not have Foundry, then complete the installation:

```
foundryup

forge install
```
See the [Foundry Docs](https://book.getfoundry.sh/) for more info on installation and usage

## Installation

1. Clone the repository
   ```bash
   git clone https://github.com/PeterMcQuaid/LuckyEther.git
   cd LuckyEther
   ```
2. Install Git submodule dependencies

    ```bash
   forge install
   ```

## Usage

1. Set environment varibles based on [.env.example](.env.example)
    ```
    touch .env
    // Add relevant variables
    source .env
    ```
    Note - Storing a private key as an environment variable is NOT secure and should never be used to store real funds. Storing a private key in a Foundry encrypted keystore is also not secure. 

2. Build the project
    ```
    forge build
    ```
    
## Testing
    
Run tests on local Anvil chain or fork:
```
forge test
```

Or from the [Makefile](Makefile), for example:

```
make test-sepolia
```

## Static Analysis

### Linting

To lint all files inside `contracts` directory:

```sh
solhint src/contracts/**/*.sol
```

Or to lint a single file:

```sh
solhint src/contracts/core/LotteryContract.sol
```


### Slither

```
slither .
```
### Mythril




### Mythx



### Generate Inheritance and Control-Flow Graphs

first [install surya](https://github.com/ConsenSys/surya/)

then run

`surya inheritance ./src/contracts/**/*.sol | dot -Tpng > InheritanceGraph.png`

and/or

`surya graph ./src/contracts/middleware/*.sol | dot -Tpng > MiddlewareControlFlowGraph.png`

and/or

`surya mdreport surya_report.md ./src/contracts/**/*.sol`

    
## Deployments

### Current Testnet Deployment

#### Arbitrum Goerli 
<p style="font-size: 12px;">ChainID: 421613</p>

| Name | Solidity | Proxy | Implementation | Notes |
| -------- | -------- | -------- | -------- | -------- | 
| StrategyManager | [`StrategyManager`](https://github.com/Layr-Labs/eigenlayer-contracts/blob/0139d6213927c0a7812578899ddd3dda58051928/src/contracts/core/StrategyManager.sol) | [`0x8586...075A`](https://etherscan.io/address/0x858646372CC42E1A627fcE94aa7A7033e7CF075A) | [`0x5d25...42Fb`](https://etherscan.io/address/0x5d25EEf8CfEdaA47d31fE2346726dE1c21e342Fb) | Proxy: [OpenZeppelin TUP@5.0.0](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.0/contracts/proxy/transparent/TransparentUpgradeableProxy.sol) 
| DelegationManager | [`DelegationManager`](https://github.com/Layr-Labs/eigenlayer-contracts/blob/0139d6213927c0a7812578899ddd3dda58051928/src/contracts/core/DelegationManager.sol) | [`0x3905...f37A`](https://etherscan.io/address/0x39053D51B77DC0d36036Fc1fCc8Cb819df8Ef37A) | [`0xf97E...75e4`](https://etherscan.io/address/0xf97E97649Da958d290e84E6D571c32F4b7F475e4) | Proxy: [OpenZeppelin TUP@5.0.0](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.0/contracts/proxy/transparent/TransparentUpgradeableProxy.sol) |
| PauserRegistry | [`PauserRegistry`](https://github.com/Layr-Labs/eigenlayer-contracts/blob/0139d6213927c0a7812578899ddd3dda58051928/src/contracts/permissions/PauserRegistry.sol) | - | [`0x0c43...7060`](https://etherscan.io/address/0x0c431C66F4dE941d089625E5B423D00707977060) | |
| Pauser Multisig | [`GnosisSafe@1.3.0`](https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/GnosisSafe.sol) | [`0x5050…2390`](https://etherscan.io/address/0x5050389572f2d220ad927CcbeA0D406831012390) | [`0xd9db...9552`](https://etherscan.io/address/0xd9db270c1b5e3bd161e8c8503c55ceabee709552) | Proxy: [`GnosisSafeProxy@1.3.0`](https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/proxies/GnosisSafeProxy.sol) |
| Community Multisig | [`GnosisSafe@1.3.0`](https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/GnosisSafe.sol) | [`0xFEA4...c598`](https://etherscan.io/address/0xFEA47018D632A77bA579846c840d5706705Dc598) | [`0xd9db...9552`](https://etherscan.io/address/0xd9db270c1b5e3bd161e8c8503c55ceabee709552) | Proxy: [`GnosisSafeProxy@1.3.0`](https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/proxies/GnosisSafeProxy.sol) |
| Proxy Admin | [OpenZeppelin ProxyAdmin@4.7.1](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.0/contracts/proxy/transparent/ProxyAdmin.sol) | - | [`0x8b95...2444`](https://etherscan.io/address/0x8b9566AdA63B64d1E1dcF1418b43fd1433b72444) | |

#### Sepolia 
<p style="font-size: 12px;">ChainID: 11155111</p>

| Name | Solidity | Proxy | Implementation | Notes |
| -------- | -------- | -------- | -------- | -------- | 
| StrategyManager | [`StrategyManager`](https://github.com/Layr-Labs/eigenlayer-contracts/blob/0139d6213927c0a7812578899ddd3dda58051928/src/contracts/core/StrategyManager.sol) | [`0x8586...075A`](https://etherscan.io/address/0x858646372CC42E1A627fcE94aa7A7033e7CF075A) | [`0x5d25...42Fb`](https://etherscan.io/address/0x5d25EEf8CfEdaA47d31fE2346726dE1c21e342Fb) | Proxy: [OpenZeppelin TUP@5.0.0](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.0/contracts/proxy/transparent/TransparentUpgradeableProxy.sol) 
| DelegationManager | [`DelegationManager`](https://github.com/Layr-Labs/eigenlayer-contracts/blob/0139d6213927c0a7812578899ddd3dda58051928/src/contracts/core/DelegationManager.sol) | [`0x3905...f37A`](https://etherscan.io/address/0x39053D51B77DC0d36036Fc1fCc8Cb819df8Ef37A) | [`0xf97E...75e4`](https://etherscan.io/address/0xf97E97649Da958d290e84E6D571c32F4b7F475e4) | Proxy: [OpenZeppelin TUP@5.0.0](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.0/contracts/proxy/transparent/TransparentUpgradeableProxy.sol) |
| PauserRegistry | [`PauserRegistry`](https://github.com/Layr-Labs/eigenlayer-contracts/blob/0139d6213927c0a7812578899ddd3dda58051928/src/contracts/permissions/PauserRegistry.sol) | - | [`0x0c43...7060`](https://etherscan.io/address/0x0c431C66F4dE941d089625E5B423D00707977060) | |
| Pauser Multisig | [`GnosisSafe@1.3.0`](https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/GnosisSafe.sol) | [`0x5050…2390`](https://etherscan.io/address/0x5050389572f2d220ad927CcbeA0D406831012390) | [`0xd9db...9552`](https://etherscan.io/address/0xd9db270c1b5e3bd161e8c8503c55ceabee709552) | Proxy: [`GnosisSafeProxy@1.3.0`](https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/proxies/GnosisSafeProxy.sol) |
| Community Multisig | [`GnosisSafe@1.3.0`](https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/GnosisSafe.sol) | [`0xFEA4...c598`](https://etherscan.io/address/0xFEA47018D632A77bA579846c840d5706705Dc598) | [`0xd9db...9552`](https://etherscan.io/address/0xd9db270c1b5e3bd161e8c8503c55ceabee709552) | Proxy: [`GnosisSafeProxy@1.3.0`](https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/proxies/GnosisSafeProxy.sol) |
| Proxy Admin | [OpenZeppelin ProxyAdmin@4.7.1](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.0/contracts/proxy/transparent/ProxyAdmin.sol) | - | [`0x8b95...2444`](https://etherscan.io/address/0x8b9566AdA63B64d1E1dcF1418b43fd1433b72444) | |

## Legal Disclaimer
  
Please note that LuckyEther is intended for educational and demonstration purposes. The author is not responsible for any loss of funds or other damages caused by the use of project or its contracts. Always ensure you have backups of your keys and use this software at your own risk
  
## Contributions

Pull requests are welcome! Please ensure that any changes or additions you make are well-documented and covered by test cases.

For any bugs or issues, please open an [issue](https://github.com/PeterMcQuaid/LuckyEther/issues).


## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details