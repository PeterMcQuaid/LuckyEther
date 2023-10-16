<a name="readme-top"></a>

[![Unit Tests](https://github.com/PeterMcQuaid/LuckyEther/actions/workflows/test.yml/badge.svg)](https://github.com/PeterMcQuaid/LuckyEther/actions/workflows/test.yml) 
[![MythXBadge](https://badgen.net/https/api.mythx.io/v1/projects/38f0122a-fead-4e5a-aebd-14fcd01516f6/badge/data?cache=300&icon=https://raw.githubusercontent.com/ConsenSys/mythx-github-badge/main/logo_white.svg)](https://docs.mythx.io/dashboard/github-badges)
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
    <a href="https://github.com/PeterMcQuaid/LuckyEther#installation"><strong>Installation & Testing »</strong></a>
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
- [Roadmap](#roadmap)
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

**Testnets:**
  - [ ] Arbitrum Goerli
  - [x] Sepolia

**Mainnets:**
  - [ ] Arbitrum One
  - [ ] Ethereum Mainnet


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

```
myth analyze src/contracts/**/*.sol --solc-json mythril.config.json
```


### Mythx

```
mythx analyze
```



### Generate Inheritance and Control-Flow Graphs

First [install surya](https://github.com/ConsenSys/surya/), then run:
```
surya inheritance ./src/contracts/**/*.sol | dot -Tpng > InheritanceGraph.png
```
Or:
```
surya mdreport surya_report.md ./src/contracts/**/*.sol
```

    
## Deployments

### Current Testnet Deployment



#### Sepolia <span style="font-size: 10px; margin-left: 12px;">[ChainID: 11155111]</span>

| Name | Solidity | Proxy | Implementation | Notes |
|--------| -------- |:--------:| -------- | -------- | 
| LotteryContract | [`LotteryContract`](https://github.com/PeterMcQuaid/LuckyEther/blob/main/src/contracts/core/LotteryContract.sol) | [`0x3E18...c1E6`](https://sepolia.etherscan.io/address/0x3e181e1d26f6f3fc33f4626227ef7a491263c1e6) | [`0x6d56...d574`](https://sepolia.etherscan.io/address/0x6d564ac24f600c6aeb920c3b16cb2da99d23d574) | Proxy: [OpenZeppelin TUP@5.0.0](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.0/contracts/proxy/transparent/TransparentUpgradeableProxy.sol) 
| PauserRegistry | [`PauserRegistry`](https://github.com/PeterMcQuaid/LuckyEther/blob/main/src/contracts/permissions/PauserRegistry.sol) | - | [`0x86Ed...54C8`](https://sepolia.etherscan.io/address/0x86ed2d12af5e2fad95da1ab36f5ea3773a0254c8) | |
| Proxy Admin | [OpenZeppelin ProxyAdmin@5.0.0](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.0/contracts/proxy/transparent/ProxyAdmin.sol) | - | [`0x32dC...9A13`](https://sepolia.etherscan.io/address/0x32dca5c35a92925e986de019656ad76df2549a13) | |

## Legal Disclaimer
  
Please note that LuckyEther is intended for educational and demonstration purposes. The author is not responsible for any loss of funds or other damages caused by the use of project or its contracts. Always ensure you have backups of your keys and use this software at your own risk
  
## Contributions

Pull requests are welcome! Please ensure that any changes or additions you make are well-documented and covered by test cases.

For any bugs or issues, please open an [issue](https://github.com/PeterMcQuaid/LuckyEther/issues).


## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details