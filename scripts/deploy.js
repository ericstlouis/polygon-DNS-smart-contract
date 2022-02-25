// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {

  const [owner, ranAcc1] = await hre.ethers.getSigners();
  const domainsContractFactory = await hre.ethers.getContractFactory("Domains");
  const domainContract = await domainsContractFactory.deploy("SNS");

  await domainContract.deployed();

  console.log("Domain Contract deployed to:", domainContract.address);
  console.log("contract deployed by", owner.address);

  const txn = await domainContract.register("Boss", {value: hre.ethers.utils.parseEther("1")});
  await txn.wait();

  const txn2 = await domainContract.setRecord("Boss", "i love you");
  await txn2.wait();
  console.log("Set Record for Boss.SNS");

  // const txn3 = await domainContract.getRecord('i love you');
  // await txn3.wait();
  // console.log('record txn3:', txn3);

  const daRecordTxn = await domainContract.records("Boss");
  console.log("da record:", daRecordTxn);


  const domainOwner = await domainContract.getAddress("Boss");
  console.log("owner of domain:", domainOwner)

  const balance = await hre.ethers.provider.getBalance(domainContract.address);
  console.log("contract balance", hre.ethers.utils.formatEther(balance))

  const all = await domainContract.getAllNames();
  console.log(all)

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
