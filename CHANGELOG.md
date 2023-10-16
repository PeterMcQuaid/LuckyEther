# Changelog

## Sepolia Deployment <span style="font-size: 10px; margin-left: 12px;">2023-10-16</span>


### Additions Summary

The following project files were added:

- `LotteryContract.sol`: The main implementation contract for the project
- `PauserRegistry.sol`: The pauser registry to control pausable features
- `EmptyContract.sol`: The template initial implementation contract
- `DeployLotteryContract.s.sol`: Deploy script for proxy and implementation
- `DeployPauserRegistry.s.sol`: Deploy script for Pauser Registry
- Added unit and integration test suite

As well as repo documentation and configurations:

- `test.yml`: CI GitHub Actions workflow for running Foundry tests
- `foundry.toml`: Local configuration for project
- `Makefile`: Includes all important shortcuts for deployment and testing
- `LuckyEtherMythxReport.pdf`: MythX static analysis report
- `.mythx.yml`: Config file for MythX
- `slither.config.json`
- `mythril.config.json` 
- `.solhint.json`
- `.solhintignore`
- `README.md`
- `CHANGELOG.md`


### Removals Summary

Nothing removed in this version