use starknet::{ContractAddress, get_block_timestamp};
use contracts::staking::interface::{StakerPoolInfo, StakerInfo, StakerInfoTrait};
use core::num::traits::Zero;
use contracts::types::{Amount, Index, TimeDelta, TimeStamp};
use core::cmp::max;

#[derive(Hash, Drop, Serde, Copy, starknet::Store)]
pub struct UndelegateIntentKey {
    pub pool_contract: ContractAddress,
    // The identifier is generally the pool member address, but it can be any unique identifier,
    // depending on the logic of the pool contract.
    pub identifier: felt252
}

#[derive(Debug, PartialEq, Drop, Serde, Copy, starknet::Store)]
pub struct UndelegateIntentValue {
    pub unpool_time: u64,
    pub amount: Amount
}

pub impl UndelegateIntentValueZero of core::num::traits::Zero<UndelegateIntentValue> {
    fn zero() -> UndelegateIntentValue {
        UndelegateIntentValue { unpool_time: Zero::zero(), amount: Zero::zero() }
    }
    #[inline(always)]
    fn is_zero(self: @UndelegateIntentValue) -> bool {
        *self == Self::zero()
    }
    #[inline(always)]
    fn is_non_zero(self: @UndelegateIntentValue) -> bool {
        !self.is_zero()
    }
}

#[derive(Debug, PartialEq, Drop, Serde, Copy, starknet::Store)]
pub(crate) struct InternalStakerInfo {
    pub(crate) reward_address: ContractAddress,
    pub(crate) operational_address: ContractAddress,
    pub(crate) unstake_time: Option<u64>,
    pub(crate) amount_own: Amount,
    pub(crate) index: Index,
    pub(crate) unclaimed_rewards_own: Amount,
    pub(crate) pool_info: Option<StakerPoolInfo>,
}

#[generate_trait]
pub(crate) impl InternalStakerInfoImpl of InternalStakerInfoTrait {
    fn compute_unpool_time(self: @InternalStakerInfo, exit_wait_window: TimeDelta) -> TimeStamp {
        if let Option::Some(unstake_time) = *self.unstake_time {
            return max(unstake_time, get_block_timestamp());
        }
        get_block_timestamp() + exit_wait_window
    }

    fn get_pool_info_unchecked(self: InternalStakerInfo) -> StakerPoolInfo {
        let staker_info: StakerInfo = self.into();
        return staker_info.get_pool_info_unchecked();
    }
}

pub(crate) impl InternalStakerInfoInto of Into<InternalStakerInfo, StakerInfo> {
    #[inline(always)]
    fn into(self: InternalStakerInfo) -> StakerInfo {
        StakerInfo {
            reward_address: self.reward_address,
            operational_address: self.operational_address,
            unstake_time: self.unstake_time,
            amount_own: self.amount_own,
            index: self.index,
            unclaimed_rewards_own: self.unclaimed_rewards_own,
            pool_info: self.pool_info,
        }
    }
}
