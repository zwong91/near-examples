MASTER_ACC=in.testnet
DAO_ROOT_ACC=sputnikv2.testnet
DAO_NAME=croncat_testnet_v3
DAO_ACCOUNT=$DAO_NAME.$DAO_ROOT_ACC

export NEAR_ENV=testnet

FOUNDERS='["per.testnet", "in.testnet", "escrow.testnet", "cron.testnet", "ion.testnet"]'
APPLICATIONS='[]'
AGENTS='[]'
COMMANDERS='[]'

#DAO Policy
export POLICY='{
  "roles": [
    {
      "name": "founders",
      "kind": { "Group": '$FOUNDERS' },
      "permissions": [
        "*:Finalize",
        "*:AddProposal",
        "*:VoteApprove",
        "*:VoteReject",
        "*:VoteRemove"
      ],
      "vote_policy": {
        "Group": {
          "weight_kind": "RoleWeight",
          "quorum": "0",
          "threshold": [1, 5]
        }
      }
    },
    {
      "name": "applications",
      "kind": { "Group": '$APPLICATIONS' },
      "permissions": [
        "*:AddProposal",
        "*:VoteApprove",
        "*:VoteReject"
      ],
      "vote_policy": {}
    },
    {
      "name": "agents",
      "kind": { "Group": '$AGENTS' },
      "permissions": [
        "*:AddProposal",
        "*:VoteApprove",
        "*:VoteReject"
      ],
      "vote_policy": {}
    },
    {
      "name": "commanders",
      "kind": { "Group": '$COMMANDERS' },
      "permissions": [
        "*:AddProposal"
      ],
      "vote_policy": {
        "Group": {
          "weight_kind": "RoleWeight",
          "quorum": "0",
          "threshold": [1, 2]
        }
      }
    }
  ],
  "default_vote_policy": {
    "weight_kind": "RoleWeight",
    "quorum": "0",
    "threshold": [1, 2]
  },
  "proposal_bond": "100000000000000000000000",
  "proposal_period": "604800000000000",
  "bounty_bond": "100000000000000000000000",
  "bounty_forgiveness_period": "604800000000000"
}'

#Args for creating DAO in sputnik-factory2
ARGS=`echo "{\"config\":  {\"name\": \"$DAO_NAME\", \"purpose\": \"Enabling a community to own grow and maintain the blockchain scheduling utility\", \"metadata\":\"\"}, \"policy\": $POLICY}" | base64`
FIXED_ARGS=`echo $ARGS | tr -d '\r' | tr -d ' '`

# Call sputnik factory for deploying new dao with custom policy
near call $DAO_ROOT_ACC create "{\"name\": \"$DAO_NAME\", \"args\": \"$FIXED_ARGS\"}" --accountId $MASTER_ACC --amount 5 --gas 150000000000000
near view $DAO_ACCOUNT get_policy
echo "'$NEAR_ENV' Deploy Complete!"