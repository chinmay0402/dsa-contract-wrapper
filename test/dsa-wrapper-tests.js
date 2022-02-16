const { expect, should } = require("chai");
require('hardhat');
const DSA = require('dsa-connect');
const { parseEther } = require("ethers/lib/utils");
require("@nomiclabs/hardhat-web3");
const dsaContractAbi = require("./dsaContractAbi.js");

describe("DSA Wrapper Contract", function () {
  let owner;
  let dsaWrapper;
  let dsa, dsaId, dsaAddress;
  const address = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';

  dsa = new DSA({
    web3: web3,
    mode: "node",
    privateKey: process.env.PRIVATE_KEY
  });

  before(async () => {
    await dsa.build({
      gasPrice: web3.utils.toWei('1000000', 'gwei'), // gas estimate, necessary when using NodeJs for calls
      authority: address, // the address to be added as authority for the account
      version: 2
    });

    const accounts = await dsa.getAccounts(address);
    console.log(accounts)
    dsaAddress = accounts[0].address;
    
    dsaContract = new ethers.Contract(dsaAddress, dsaContractAbi, ethers.provider);

    dsaId = accounts[0].id;

    const dsaWrapperFactory = await ethers.getContractFactory("DsaWrapper");
    [owner] = await ethers.getSigners();
    dsaWrapper = await dsaWrapperFactory.deploy();

    await dsa.setInstance(dsaId);

    let spells = dsa.Spell();
    spells.add({
      connector: "AUTHORITY-A",
      method: "add",
      args: [dsaWrapper.address]
    });
    const transactionHash = await spells.cast({
      gasPrice: web3.utils.toWei('1000000', 'gwei'), // in gwei, used in node implementation.
    });
  });

  describe('Deployment', async () => {
    it('Sets the correct owner', async () => {
      expect(await dsaWrapper.getOwner()).to.equal(owner.address);
    });
  });

  describe('Authority', async () => {
    it('should return correct account authority', async () => {
      expect(await dsaWrapper.getAuthority(dsaId)).to.have.all.members([owner.address, dsaWrapper.address]);
    });
  });

  describe('Deposit Ether', async () => {
    it('Should deposit Ether to DSA and update balances', async () => {
      expect(await dsaWrapper.depositEtherToDsa(dsaId, {
        value: parseEther('1')
      }))
        .to.changeEtherBalances([owner, dsaContract], [parseEther('-1'), parseEther('1')]);
    });
  });
});
