const hre = require("hardhat");

async function main() {
  const DsaWrapper = await hre.ethers.getContractFactory("DsaWrapper");
  const dsaWrapper = await DsaWrapper.deploy();

  await dsaWrapper.deployed();

  console.log("DsaWrapper deployed to:", dsaWrapper.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
