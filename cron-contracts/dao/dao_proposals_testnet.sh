set -e
MASTER_ACC=in.testnet
DAO_ROOT_ACC=sputnikv2.testnet
DAO_NAME=croncat
DAO_ACCOUNT=$DAO_NAME.$DAO_ROOT_ACC
CRON_ACCOUNT=manager_v1.croncat.testnet
BOND_AMOUNT=0.1

export NEAR_ENV=testnet

## CRONCAT Launch proposal (unpause)
# ARGS=`echo "{ \"paused\": false }" | base64`
# FIXED_ARGS=`echo $ARGS | tr -d '\r' | tr -d ' '`
# near call $DAO_ACCOUNT add_proposal '{"proposal": {"description": "Unpause the croncat manager contract to enable cron tasks", "kind": {"FunctionCall": {"receiver_id": "'$CRON_ACCOUNT'", "actions": [{"method_name": "update_settings", "args": "'$FIXED_ARGS'", "deposit": "0", "gas": "50000000000000"}]}}}}' --accountId $MASTER_ACC --amount $BOND_AMOUNT

## CRONCAT config change proposal
# ARGS=`echo "{ \"agents_eject_threshold\": \"600\" }" | base64`
# FIXED_ARGS=`echo $ARGS | tr -d '\r' | tr -d ' '`
# near call $DAO_ACCOUNT add_proposal '{"proposal": {"description": "Change agent kick length to 10 hours", "kind": {"FunctionCall": {"receiver_id": "'$CRON_ACCOUNT'", "actions": [{"method_name": "update_settings", "args": "'$FIXED_ARGS'", "deposit": "0", "gas": "50000000000000"}]}}}}' --accountId $MASTER_ACC --amount $BOND_AMOUNT


# ## CRONCAT Launch proposal: TICK Task
# ARGS=`echo "{\"contract_id\": \"$CRON_ACCOUNT\",\"function_id\": \"tick\",\"cadence\": \"0 0 * * * *\",\"recurring\": true,\"deposit\": \"0\",\"gas\": 9000000000000}" | base64`
# FIXED_ARGS=`echo $ARGS | tr -d '\r' | tr -d ' '`
# near call $DAO_ACCOUNT add_proposal '{"proposal": {"description": "Create cron task to manage TICK method to handle agents every hour", "kind": {"FunctionCall": {"receiver_id": "'$CRON_ACCOUNT'", "actions": [{"method_name": "create_task", "args": "'$FIXED_ARGS'", "deposit": "10000000000000000000000000", "gas": "50000000000000"}]}}}}' --accountId $MASTER_ACC --amount $BOND_AMOUNT


# ## CRONCAT Slot Management proposal
# ARGS=`echo "{\"slot\": \"1638307260000000000\"}" | base64`
# FIXED_ARGS=`echo $ARGS | tr -d '\r' | tr -d ' '`
# near call $DAO_ACCOUNT add_proposal '{"proposal": {"description": "Remove a slot that has missing tasks", "kind": {"FunctionCall": {"receiver_id": "'$CRON_ACCOUNT'", "actions": [{"method_name": "remove_slot", "args": "'$FIXED_ARGS'", "deposit": "0", "gas": "50000000000000"}]}}}}' --accountId $MASTER_ACC --amount $BOND_AMOUNT


## payout proposal
# near call $DAO_ACCOUNT add_proposal '{"proposal": { "description": "", "kind": { "Transfer": { "token_id": "", "receiver_id": "in.testnet", "amount": "1000000000000000000000000" } } } }' --accountId $MASTER_ACC --amount $BOND_AMOUNT

## add member to one of our roles
# ROLE=founders
# ROLE=applications
# ROLE=agents
# ROLE=commanders
# NEW_MEMBER=pa.testnet
# near call $DAO_ACCOUNT add_proposal '{ "proposal": { "description": "Welcome '$NEW_MEMBER' to the '$ROLE' team", "kind": { "AddMemberToRole": { "member_id": "'$NEW_MEMBER'", "role": "'$ROLE'" } } } }' --accountId $MASTER_ACC --amount $BOND_AMOUNT

## CRONCAT Scheduling proposal example
# near call $DAO_ACCOUNT add_proposal '{"proposal": {"description": "demo croncat test", "kind": {"FunctionCall": {"receiver_id": "crud.in.testnet", "actions": [{"method_name": "tick", "args": "e30=", "deposit": "0", "gas": "20000000000000"}]}}}}' --accountId $MASTER_ACC --amount $BOND_AMOUNT



## -----------------------------------------------
## AUTOMATED TREASURY!
## -----------------------------------------------
TREASURY_ACCT=treasury.vaultfactory.testnet

# Send funds to treasury for auto-management
# near call $DAO_ACCOUNT add_proposal '{"proposal": { "description": "Move near funds to treasury", "kind": { "Transfer": { "token_id": "", "receiver_id": "'$TREASURY_ACCT'", "amount": "1400000000000000000000000000" } } } }' --accountId $MASTER_ACC --amount $BOND_AMOUNT
# TOKEN_ID=token-v3.cheddar.testnet
# near call $DAO_ACCOUNT add_proposal '{"proposal": { "description": "Move token funds to treasury", "kind": { "Transfer": { "token_id": "'$TOKEN_ID'", "receiver_id": "'$TREASURY_ACCT'", "amount": "100000000000000000000000000" } } } }' --accountId $MASTER_ACC --amount $BOND_AMOUNT

# Staking: Deposit & Stake (Manual)
# ARGS=`echo "{\"pool_account_id\": \"meta-v2.pool.testnet\"}" | base64`
# FIXED_ARGS=`echo $ARGS | tr -d '\r' | tr -d ' '`
# near call $DAO_ACCOUNT add_proposal '{"proposal": {"description": "Send funds to stake with a certain pool", "kind": {"FunctionCall": {"receiver_id": "'$TREASURY_ACCT'", "actions": [{"method_name": "deposit_and_stake", "args": "'$FIXED_ARGS'", "deposit": "100000000000000000000000000", "gas": "180000000000000"}]}}}}' --accountId $MASTER_ACC --amount $BOND_AMOUNT
# OR 
# ARGS=`echo "{\"pool_account_id\": \"hotones.pool.f863973.m0\"}" | base64`
# FIXED_ARGS=`echo $ARGS | tr -d '\r' | tr -d ' '`
# near call $DAO_ACCOUNT add_proposal '{"proposal": {"description": "Send funds to stake with a certain pool", "kind": {"FunctionCall": {"receiver_id": "'$TREASURY_ACCT'", "actions": [{"method_name": "deposit_and_stake", "args": "'$FIXED_ARGS'", "deposit": "100000000000000000000000000", "gas": "180000000000000"}]}}}}' --accountId $MASTER_ACC --amount $BOND_AMOUNT

# Staking: Liquid Unstake (Manual)
# ARGS=`echo "{\"pool_account_id\": \"meta-v2.pool.testnet\",\"amount\": \"5000000000000000000000000\"}" | base64`
# FIXED_ARGS=`echo $ARGS | tr -d '\r' | tr -d ' '`
# near call $DAO_ACCOUNT add_proposal '{"proposal": {"description": "Request some funds to be immediately released from liquid stake pool", "kind": {"FunctionCall": {"receiver_id": "'$TREASURY_ACCT'", "actions": [{"method_name": "liquid_unstake", "args": "'$FIXED_ARGS'", "deposit": "0", "gas": "180000000000000"}]}}}}' --accountId $MASTER_ACC --amount $BOND_AMOUNT

# Staking: Unstake (Manual + Autowithdraw)
# ARGS=`echo "{\"pool_account_id\": \"hotones.pool.f863973.m0\",\"amount\": \"5000000000000000000000000\"}" | base64`
# FIXED_ARGS=`echo $ARGS | tr -d '\r' | tr -d ' '`
# near call $DAO_ACCOUNT add_proposal '{"proposal": {"description": "Request some funds to be slowly released from vanilla stake pool", "kind": {"FunctionCall": {"receiver_id": "'$TREASURY_ACCT'", "actions": [{"method_name": "unstake", "args": "'$FIXED_ARGS'", "deposit": "0", "gas": "180000000000000"}]}}}}' --accountId $MASTER_ACC --amount $BOND_AMOUNT

# Staking: Auto-Stake Retrieve Balances
# CRONCAT_ARGS=`echo "{\"pool_account_id\": \"meta-v2.pool.testnet\"}" | base64`
# # CRONCAT_ARGS=`echo "{\"pool_account_id\": \"hotones.pool.f863973.m0\"}" | base64`
# CRONCAT_FIXED_ARGS=`echo $CRONCAT_ARGS | tr -d '\r' | tr -d ' '`
# ARGS=`echo "{\"contract_id\": \"$TREASURY_ACCT\",\"function_id\": \"get_staked_balance\",\"cadence\": \"0 0 */1 * * *\",\"recurring\": true,\"deposit\": \"0\",\"gas\": 24000000000000,\"arguments\": \"$CRONCAT_FIXED_ARGS\"}" | base64`
# FIXED_ARGS=`echo $ARGS | tr -d '\r' | tr -d ' '`
# near call $DAO_ACCOUNT add_proposal '{"proposal": {"description": "Create cron task to manage staking balance method every day", "kind": {"FunctionCall": {"receiver_id": "'$CRON_ACCOUNT'", "actions": [{"method_name": "create_task", "args": "'$FIXED_ARGS'", "deposit": "5000000000000000000000000", "gas": "50000000000000"}]}}}}' --accountId $MASTER_ACC --amount $BOND_AMOUNT

## -----------------------------------------------
## -----------------------------------------------



# ## METAPOOL STAKING
# METAPOOL_ACCT=meta-v2.pool.testnet
# # Stake (example: 5jh8NP6dwXUELQfTSZSQzKpyaPjuue8btEaxv1Ng1MBT, and https://explorer.testnet.near.org/transactions/4rgrYB9W1UxZVzyVeYRP6sAGsWv18tfsB3zX3KjyYqqF)
# near call $DAO_ACCOUNT add_proposal '{"proposal": {"description": "Stake some funds from croncat dao to metapool", "kind": {"FunctionCall": {"receiver_id": "'$METAPOOL_ACCT'", "actions": [{"method_name": "deposit_and_stake", "args": "e30=", "deposit": "10000000000000000000000000", "gas": "20000000000000"}]}}}}' --accountId $MASTER_ACC --amount $BOND_AMOUNT

# # Unstake all (example: 9xVyewMkzxHfRGtx3EyG82mXX8CfPXLJeW4Xo2y6PpXX)
# ARGS=`echo "{ \"amount\": \"10000000000000000000000000\" }" | base64`
# FIXED_ARGS=`echo $ARGS | tr -d '\r' | tr -d ' '`
# near call $DAO_ACCOUNT add_proposal '{"proposal": {"description": "Unstake all funds from metapool to croncat dao", "kind": {"FunctionCall": {"receiver_id": "'$METAPOOL_ACCT'", "actions": [{"method_name": "unstake", "args": "'$FIXED_ARGS'", "deposit": "0", "gas": "20000000000000"}]}}}}' --accountId $MASTER_ACC --amount $BOND_AMOUNT

# # Withdraw balance back (example: EKZqArNzsjq9hpYuYt37Y59qU1kmZoxguLwRH2RnDELd)
# near call $DAO_ACCOUNT add_proposal '{"proposal": {"description": "Withdraw unstaked funds from metapool to croncat dao", "kind": {"FunctionCall": {"receiver_id": "'$METAPOOL_ACCT'", "actions": [{"method_name": "withdraw_unstaked", "args": "e30=", "deposit": "0", "gas": "20000000000000"}]}}}}' --accountId $MASTER_ACC --amount $BOND_AMOUNT

## NOTE: Examples setup as needed, adjust variables for use cases.
# near view $DAO_ACCOUNT get_policy
near call $DAO_ACCOUNT act_proposal '{"id": 46, "action" :"VoteApprove"}' --accountId $MASTER_ACC  --gas 300000000000000
# near call $DAO_ACCOUNT act_proposal '{"id": 0, "action" :"VoteReject"}' --accountId $MASTER_ACC  --gas 300000000000000
# near call $DAO_ACCOUNT act_proposal '{"id": 0, "action" :"VoteRemove"}' --accountId $MASTER_ACC  --gas 300000000000000
