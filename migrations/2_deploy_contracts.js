var CusromERC = artifacts.require("./CustomERC20.sol");
var Airdrop = artifacts.require("./Airdrop.sol");

module.exports = async function (deployer) {
  await deployer.deploy(CusromERC, "Custom Token", "CSTMN", 1000);
  await deployer.deploy(Airdrop, CusromERC.address);
};