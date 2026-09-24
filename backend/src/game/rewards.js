import {gameCatalog} from '../../battle-engine/index.js';
import {catalog} from '../catalog.js';
import {ONLINE} from './config.js';
import {grantXp,progressionOf} from './profiles.js';

export function arenaRewards(player,rival,result,counts) {
  const xp=gameCatalog.balance.xp;
  const pairFactor=counts.pair>=ONLINE.repeatedPairZeroXpAfter?0:Math.max(xp.repeat_opponent_floor,1-Math.max(0,counts.pair+1-xp.repeat_opponent_threshold)*xp.repeat_opponent_decay);
  const timeFactor=Math.min(1,Math.max(xp.short_match_floor,result.duration/xp.short_match_seconds));
  const defensive=counts.defenses<ONLINE.defensiveFullXpBattles?1:counts.defenses<ONLINE.defensiveReducedXpBattles?ONLINE.defensiveReducedXpFactor:0;
  const reward=(row,won,factor,remaining)=>Math.min(Math.max(0,remaining),Math.floor(Math.round((won?xp.win:xp.loss)*(1+(progressionOf(row).level-1)*xp.reward_growth))*factor));
  const p=grantXp(player,reward(player,result.winner==='player',pairFactor*timeFactor,ONLINE.activeDailyXpCap-counts.activeXp));
  const r=grantXp(rival,reward(rival,result.winner==='rival',pairFactor*timeFactor*defensive,ONLINE.defensiveDailyXpCap-counts.defensiveXp));
  const score=result.winner==='player'?1:0;
  const expected=1/(1+10**((rival.rating-player.rating)/400));
  let delta=counts.pair<ONLINE.ratedPairBattlesPerDay?Math.round(ONLINE.ratingK*(score-expected)):0;
  delta=Math.max(-player.rating,Math.min(rival.rating,delta));
  player.rating+=delta;rival.rating-=delta;p.rating_delta=delta;r.rating_delta=-delta;
  p.rating_change=delta;r.rating_change=-delta;
  player[result.winner==='player'?'wins':'losses']++;
  rival[result.winner==='rival'?'wins':'losses']++;
  p.reward_factor=pairFactor*timeFactor;r.reward_factor=pairFactor*timeFactor*defensive;
  return {player:p,rival:r};
}
export function storyReward(player,stage,result,practice=false) {
  const won=result.winner==='player';
  const xp=practice?0:won?stage.xp_win:Math.max(1,Math.floor(stage.xp_loss*Math.max(gameCatalog.campaign.loss_xp_floor,1-player.story_attempts*gameCatalog.campaign.loss_xp_decay)*Math.min(1,Math.max(.15,result.duration/8))));
  const reward=grantXp(player,xp),p=progressionOf(player);
  if(!practice) {
    if(won) {
      player.story_cleared=stage.global_level;player.story_attempts=0;
      const tokens=stage.rewards||{};
      p.stat_points+=tokens.stat_points||0;p.move_points+=tokens.move_points||0;p.perk_points+=tokens.perk_points||0;
      reward.points_gained+=tokens.stat_points||0;reward.move_points_gained=tokens.move_points||0;reward.perk_points_gained=tokens.perk_points||0;
    } else player.story_attempts++;
  }
  player.progression_payload=JSON.stringify(p);
  reward.advanced=won&&!practice;reward.practice=practice;reward.story_cleared=player.story_cleared;
  reward.rating_change=0;
  return {player:reward,rival:{xp_gained:0,rating_delta:0,levels_gained:0,static_opponent:true}};
}
export function earnedCosmetics(row) {
  const level=progressionOf(row).level, won=row.wins, cleared=row.story_cleared;
  return catalog.items.filter(item=>{
    const r=item.unlock||{};
    // Resolved below from the canonical requirement, without trusting clients.
    if(r.kind==='level') return level>=r.threshold;
    if(r.kind==='league_wins') return won>=r.threshold;
    if(r.kind==='story_cleared') return cleared>=r.threshold;
    return false;
  }).map(item=>item.inventory_id);
}
