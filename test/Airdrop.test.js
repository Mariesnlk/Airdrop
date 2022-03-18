const { assert } = require('chai')
const { expect } = require('chai');

const CustomERC20 = artifacts.require('./CustomERC20');
const Airdrop = artifacts.require('./Airdrop');

const {
    BN,
    time,
    ether,
    expectRevert,
    expectEvent
} = require("@openzeppelin/test-helpers");

require("chai")
    .use(require("chai-bn")(BN))
    .should();

const EIP712 = require("./utils/eip712.js");

let chainId;

contract('Airdrop', (accounts) => {

    const [initialHolder, recipient1, recipient2, recipient3, recipient4] = accounts;

    beforeEach(async () => {
        this.customToken = await CustomERC20.new("Custom Token", "CSTMN", 1000);
        this.airdrop = await Airdrop.new(this.customToken.address);
    })

    before(async () => {

        chainId = await web3.eth.getChainId();
    })

    describe('deployment', async () => {
        //test contaract deployment
        it('deploys successfuly', async () => {
            let contract = this.airdrop;
            const address = contract.address;
            assert.notEqual(address, '');
            assert.notEqual(address, null);
            assert.notEqual(address, undefined);
            assert.notEqual(address, 0x0);
        });
    });

    describe('deposit tokens', async () => {
        it('only owner(initialHolder) can deposit tokens', async () => {
            await expectRevert(
                this.airdrop.depositTokens(new BN(100), { from: recipient1 }),
                "Ownable: caller is not the owner"
            );
        });

        it('deposit tokens from initialHolder address to Airdrop contract', async () => {
            let airdrop = this.airdrop;
            expect(await this.customToken.balanceOf(initialHolder))
                .to.be.a.bignumber.equal(new BN(1000));
            await this.customToken.approve(airdrop.address, new BN(100));
            const result = await airdrop.depositTokens(new BN(100));
            expectEvent(result, 'Deposit', {
                from: initialHolder,
                to: airdrop.address,
                value: new BN(100),
            });
            expect(await this.customToken.balanceOf(initialHolder))
                .to.be.a.bignumber.equal(new BN(900));
            expect(await this.customToken.balanceOf(airdrop.address))
                .to.be.a.bignumber.equal(new BN(100));
        });

        it('not enough funds in initialHolder address to deposit', async () => {
            let airdrop = this.airdrop;
            expect(await this.customToken.balanceOf(initialHolder))
                .to.be.a.bignumber.equal(new BN(1000));
            await this.customToken.approve(airdrop.address, new BN(1000));
            const result = await airdrop.depositTokens(new BN(1000));
            expectEvent(result, 'Deposit', {
                from: initialHolder,
                to: airdrop.address,
                value: new BN(1000),
            });
            expect(await this.customToken.balanceOf(initialHolder))
                .to.be.a.bignumber.equal(new BN(0));
            expect(await this.customToken.balanceOf(airdrop.address))
                .to.be.a.bignumber.equal(new BN(1000));
            await expectRevert(
                airdrop.depositTokens(new BN(500)),
                "Airdrop: Not enough funds"
            );
        });
    });

    describe('deposit ether', async () => {
        it('only owner(initialHolder) can deposit ether', async () => {
            await expectRevert(
                this.airdrop.depositEther({ value: ether("1"), from: recipient1 }),
                "Ownable: caller is not the owner"
            );
        });

        it('deposit ether from initialHolder address to Airdrop contract', async () => {
            let contract = this.airdrop;
            const result = await contract.depositEther({ value: ether("10") });
            expectEvent(result, 'Deposit', {
                from: initialHolder,
                to: contract.address,
                value: ether("10"),
            });

            expect(await contract.balancesOfEthers(contract.address))
                .to.be.a.bignumber.equal(ether("10"));
        });
    });

    describe('withdraw tokens', async () => {
        it('only owner(initialHolder) can withdraw tokens', async () => {
            await expectRevert(
                this.airdrop.withdrawTokens({ from: recipient1 }),
                "Ownable: caller is not the owner"
            );
        });

        it('withdraw tokens from Airdrop contract to owner(initialHolder)', async () => {
            let airdrop = this.airdrop;
            await this.customToken.approve(airdrop.address, new BN(100));
            const deposit = await airdrop.depositTokens(new BN(100));
            expectEvent(deposit, 'Deposit', {
                from: initialHolder,
                to: airdrop.address,
                value: new BN(100),
            });
            expect(await this.customToken.balanceOf(airdrop.address))
                .to.be.a.bignumber.equal(new BN(100));
            const withdraw = await airdrop.withdrawTokens();
            expectEvent(withdraw, 'Transfer', {
                from: airdrop.address,
                to: initialHolder,
                value: new BN(100),
            });
            expectEvent(withdraw, 'Withdraw', {
                from: airdrop.address,
                to: initialHolder,
                value: new BN(100),
            });
            expect(await this.customToken.balanceOf(airdrop.address))
                .to.be.a.bignumber.equal(new BN(0));
        });

        it('cannot withdraw tokens if contract balance is zero', async () => {
            let airdrop = this.airdrop;
            expect(await this.customToken.balanceOf(airdrop.address))
                .to.be.a.bignumber.equal(new BN(0));
            await expectRevert(
                this.airdrop.withdrawTokens(),
                "Airdrop: Contract doesn`t have tokens!"
            );
            expect(await this.customToken.balanceOf(airdrop.address))
                .to.be.a.bignumber.equal(new BN(0));
        });
    });


    describe('withdraw ethers', async () => {
        it('only owner(initialHolder) can withdraw ethers', async () => {
            await expectRevert(
                this.airdrop.withdrawEther({ from: recipient1 }),
                "Ownable: caller is not the owner"
            );
        });

        it('cannot withdraw ethers if contract balance is zero', async () => {
            let airdrop = this.airdrop;
            expect(await airdrop.balancesOfEthers(airdrop.address))
                .to.be.a.bignumber.equal(ether("0"));
            await expectRevert(
                airdrop.withdrawEther(),
                "Airdrop: Contract doesn`t have enough ethers!"
            );
            expect(await airdrop.balancesOfEthers(airdrop.address))
                .to.be.a.bignumber.equal(ether("0"));
        });

        it('withdraw ethers from Airdrop contract to owner(initialHolder)', async () => {
            let airdrop = this.airdrop;
            const deposit = await airdrop.depositEther({ value: ether("10") });
            expectEvent(deposit, 'Deposit', {
                from: initialHolder,
                to: airdrop.address,
                value: ether("10"),
            });
            expect(await airdrop.balancesOfEthers(airdrop.address))
                .to.be.a.bignumber.equal(ether("10"));
            const withdraw = await airdrop.withdrawEther();
            expectEvent(withdraw, 'Withdraw', {
                from: airdrop.address,
                to: initialHolder,
                value: ether("10"),
            });
            expect(await airdrop.balancesOfEthers(airdrop.address))
                .to.be.a.bignumber.equal(ether("0"));
        });

    });

    describe('update token address', async () => {
        it('only owner(initialHolder) can updates', async () => {
            let newTokenContract = await CustomERC20.new("New Custom Token", "NCSTMN", 1000);
            let contractAddress = this.customToken.address;
            await expectRevert(
                this.airdrop.updateTokenAddress(newTokenContract.address, { from: recipient1 }),
                "Ownable: caller is not the owner"
            );
            expect(await this.airdrop.customToken()).to.be.a.equal(contractAddress);
        });

        it('token address cannot be updated with the same address', async () => {
            await expectRevert(
                this.airdrop.updateTokenAddress(this.customToken.address),
                "Airdrop: The same address"
            );
        });

        it('transfer tokens back to owner before updating', async () => {
            let airdrop = this.airdrop;
            let newTokenContract = await CustomERC20.new("New Custom Token", "NCSTMN", 1000);
            await this.customToken.approve(airdrop.address, new BN(100));
            const deposit = await airdrop.depositTokens(new BN(100));
            expectEvent(deposit, 'Deposit', {
                from: initialHolder,
                to: airdrop.address,
                value: new BN(100),
            });
            expect(await this.customToken.balanceOf(airdrop.address))
                .to.be.a.bignumber.equal(new BN(100));
            const updatedAddress = expect(await airdrop.updateTokenAddress(newTokenContract.address));
            expect(await airdrop.customToken()).to.be.a.equal(newTokenContract.address);
            expect(await this.customToken.balanceOf(airdrop.address))
                .to.be.a.bignumber.equal(new BN(0));
        });

        
        it('successfully update contract address', async () => {
            let airdrop = this.airdrop;
            let newTokenContract = await CustomERC20.new("New Custom Token", "NCSTMN", 1000);
            await this.customToken.approve(airdrop.address, new BN(100));
            const deposit = await airdrop.depositTokens(new BN(100));
            expectEvent(deposit, 'Deposit', {
                from: initialHolder,
                to: airdrop.address,
                value: new BN(100),
            });
            expect(await this.customToken.balanceOf(airdrop.address))
                .to.be.a.bignumber.equal(new BN(100));
            const updatedAddress = expect(await airdrop.updateTokenAddress(newTokenContract.address));
            expect(await airdrop.customToken()).to.be.a.equal(newTokenContract.address);
            expect(await this.customToken.balanceOf(airdrop.address))
                .to.be.a.bignumber.equal(new BN(0));
        });

    });

    describe('drop tokens', async () => {
        it('only owner(initialHolder) can drop tokens', async () => {
            deadline = (await time.latest()).add(new BN(1000));
            sign = await createSign(
                initialHolder,
                this.airdrop.address,
                deadline
            );

            await expectRevert(this.airdrop.dropTokens(
                [recipient1, recipient2, recipient3],
                [new BN(5), new BN(5), new BN(2)],
                deadline,
                sign.v,
                sign.r,
                sign.s,
                { from: recipient1 }
            ), "Ownable: caller is not the owner");
        });

        it('length of two arrays recipients and amounts not equal', async () => {
            deadline = (await time.latest()).add(new BN(1000));
            sign = await createSign(
                initialHolder,
                this.airdrop.address,
                deadline
            );

            await expectRevert(this.airdrop.dropTokens(
                [recipient1, recipient2],
                [new BN(5), new BN(5), new BN(2)],
                deadline,
                sign.v,
                sign.r,
                sign.s
            ), "Airdrop: The length of two arrays is not equal");
        });

        it('deadline is timed out', async () => {
            deadline = (await time.latest()).add(new BN(1000));
            sign = await createSign(
                initialHolder,
                this.airdrop.address,
                deadline
            );

            const increaseTime = 60 * 60 * 24;
            await time.increase(increaseTime);

            await expectRevert(this.airdrop.dropTokens(
                [recipient1, recipient2],
                [new BN(5), new BN(5)],
                deadline,
                sign.v,
                sign.r,
                sign.s
            ), "Airdrop: Time out");

        });

        it('successfully drop tokens', async () => {
            deadline = (await time.latest()).add(new BN(1000));
            sign = await createSign(
                initialHolder,
                this.airdrop.address,
                deadline
            );
            dropTokens = await this.airdrop.dropTokens(
                [recipient1, recipient2, recipient3],
                [new BN(5), new BN(5), new BN(2)],
                deadline,
                sign.v,
                sign.r,
                sign.s
            );

            expectEvent(
                dropTokens,
                "Airdroped",
                {
                    from: initialHolder,
                    recipient: recipient1,
                    amountToSend: new BN(5)
                }
            );
        });
    });

    describe('drop ethers', async () => {
        it('only owner(initialHolder) can drop ethers', async () => {
            deadline = (await time.latest()).add(new BN(1000));
            sign = await createSign(
                initialHolder,
                this.airdrop.address,
                deadline
            );
            await expectRevert(this.airdrop.dropEther(
                [recipient1, recipient2, recipient3],
                [ether("1"), ether("1"), ether("2")],
                deadline,
                sign.v,
                sign.r,
                sign.s,
                { from: recipient4 }
            ), "Ownable: caller is not the owner");

        });

        it('length of two arrays recipients and amounts not equal', async () => {
            deadline = (await time.latest()).add(new BN(1000));
            sign = await createSign(
                initialHolder,
                this.airdrop.address,
                deadline
            );
            await expectRevert(this.airdrop.dropEther(
                [recipient1, recipient2],
                [ether("1"), ether("1"), ether("2")],
                deadline,
                sign.v,
                sign.r,
                sign.s
            ), "Airdrop: The length of two arrays is not equal");
        });

        it('deadline is timed out', async () => {
            deadline = (await time.latest()).add(new BN(1000));
            sign = await createSign(
                initialHolder,
                this.airdrop.address,
                deadline
            );

            const increaseTime = 60 * 60 * 24;
            await time.increase(increaseTime);

            await expectRevert(this.airdrop.dropEther(
                [recipient1, recipient2, recipient3],
                [ether("1"), ether("1"), ether("2")],
                deadline,
                sign.v,
                sign.r,
                sign.s
            ), "Airdrop: Time out");
        });

        it('successfully drop ethers', async () => {
            deadline = (await time.latest()).add(new BN(1000));
            sign = await createSign(
                initialHolder,
                this.airdrop.address,
                deadline
            );

            dropEther = await this.airdrop.dropEther(
                [recipient1, recipient2, recipient3],
                [ether("1"), ether("1"), ether("2")],
                deadline,
                sign.v,
                sign.r,
                sign.s
            );

            expectEvent(
                dropEther,
                "Airdroped",
                {
                    from: initialHolder,
                    recipient: recipient1,
                    amountToSend: ether("1")
                }
            );
        });
    });


    describe('claim tokens', async () => {

        beforeEach(async () => {
            deadline = (await time.latest()).add(new BN(1000));
            sign = await createSign(
                initialHolder,
                this.airdrop.address,
                deadline
            );
            dropTokens = await this.airdrop.dropTokens(
                [recipient1, recipient2, recipient3],
                [new BN(5), new BN(5), new BN(2)],
                deadline,
                sign.v,
                sign.r,
                sign.s
            );
        })

        it('not the recipient claims tokens', async () => {
            await this.customToken.approve(this.airdrop.address, new BN(100));
            await this.airdrop.depositTokens(new BN(100));
            await expectRevert(
                this.airdrop.claimToken({ from: recipient4 }),
                "Airdrop: you don`t have permission"
            );
        });

        it('tokens are already claimed', async () => {
            await this.customToken.approve(this.airdrop.address, new BN(100));
            await this.airdrop.depositTokens(new BN(100));
            let claimed = await this.airdrop.claimToken({ from: recipient1 });
            expectEvent(claimed, 'Claimed', {
                from: this.airdrop.address,
                to: recipient1,
                value: new BN(5),
            });
            await expectRevert(
                this.airdrop.claimToken({ from: recipient1 }),
                "Airdrop: Tokens is already claimed"
            );
        });

        it('not enought tokens in the contract address', async () => {
            await this.customToken.approve(this.airdrop.address, new BN(1));
            await this.airdrop.depositTokens(new BN(1));
            await expectRevert(
                this.airdrop.claimToken({ from: recipient2 }),
                "Airdrop: Contract doesn`t have enough tokens! "
            );
        });

        it('successfully withdraw tokens', async () => {
            await this.customToken.approve(this.airdrop.address, new BN(100));
            await this.airdrop.depositTokens(new BN(100));
            expect(await this.customToken.balanceOf(this.airdrop.address))
                .to.be.a.bignumber.equal(new BN(100));
            let claimed = await this.airdrop.claimToken({ from: recipient2 });
            expectEvent(claimed, 'Claimed', {
                from: this.airdrop.address,
                to: recipient2,
                value: new BN(5),
            });
            expect(await this.customToken.balanceOf(this.airdrop.address))
                .to.be.a.bignumber.equal(new BN(95));
            expect(await this.customToken.balanceOf(recipient2))
                .to.be.a.bignumber.equal(new BN(5));
        });
    });

    describe('claim ethers', async () => {

        beforeEach(async () => {
            deadline = (await time.latest()).add(new BN(1000));
            sign = await createSign(
                initialHolder,
                this.airdrop.address,
                deadline
            );

            dropEther = await this.airdrop.dropEther(
                [recipient1, recipient2, recipient3],
                [ether("1"), ether("1"), ether("2")],
                deadline,
                sign.v,
                sign.r,
                sign.s
            );

            expectEvent(
                dropEther,
                "Airdroped",
                {
                    from: initialHolder,
                    recipient: recipient1,
                    amountToSend: ether("1")
                }
            );
        })

        it('not the recipient claims ethers', async () => {
            await this.airdrop.depositEther({ value: ether("5") });
            await expectRevert(
                this.airdrop.claimEther({ from: recipient4 }),
                "Airdrop: you don`t have permission"
            );
        });

        it('ethers are already claimed', async () => {
            await this.airdrop.depositEther({ value: ether("5") });
            let claimed = await this.airdrop.claimEther({ from: recipient1 });
            expectEvent(claimed, 'Claimed', {
                from: this.airdrop.address,
                to: recipient1,
                value: ether("1"),
            });
            await expectRevert(
                this.airdrop.claimEther({ from: recipient1 }),
                "Airdrop: Ethers is already claimed"
            );
        });

        it('not enought ethers in the contract address', async () => {
            await expectRevert(
                this.airdrop.claimEther({ from: recipient2 }),
                "Airdrop: Contract doesn`t have enough ethers! "
            );
        });

        it('successfully withdraw ethers', async () => {
            await this.airdrop.depositEther({ value: ether("10") });
            expect(await this.airdrop.balancesOfEthers(this.airdrop.address))
                .to.be.a.bignumber.equal(ether("10"));
            let claimed = await this.airdrop.claimEther({ from: recipient3 });
            expectEvent(claimed, 'Claimed', {
                from: this.airdrop.address,
                to: recipient3,
                value: ether("2"),
            });
            expect(await this.airdrop.balancesOfEthers(this.airdrop.address))
                .to.be.a.bignumber.equal(ether("8"));
            expect(await this.airdrop.balancesOfEthers(recipient3))
                .to.be.a.bignumber.equal(ether("2"));
        });
    });

    async function createSign(
        signer,
        contractAddress,
        deadline = 0
    ) {
        let TYPES;
        let typedData;
        TYPES = {
            Container: [
                { type: "address", name: "sender" },
                { type: "uint256", name: "deadline" }
            ]
        };
        typedData = EIP712.createTypeData(
            TYPES,
            "Container",
            new EIP712.DomainData(
                "Airdrop",
                "v1",
                chainId,
                contractAddress
            ), {
            sender: signer,
            deadline: deadline.toString()
        });
        return await EIP712.signTypedData(web3, signer, typedData);
    };

});
