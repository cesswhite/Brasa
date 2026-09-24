// Online-only policy. Canonical combat and Story balance remain in the export.
export const ONLINE = Object.freeze({
  version: 'online-progression-v1',
  initialRating: 1000, ratingK: 24, ratedPairBattlesPerDay: 3,
  challengeCooldownMs: 3000, maxMutationsPerMinute: 45,
  defensiveFullXpBattles: 5, defensiveReducedXpBattles: 20,
  defensiveReducedXpFactor: 0.25, defensiveDailyXpCap: 1200,
  activeDailyXpCap: 12000, repeatedPairZeroXpAfter: 10,
  matchmakingMinRatio: 0.45, matchmakingMaxRatio: 2.2,
  opponentCandidates: 60, opponentChoices: 6, pageSize: 20,
});
export const dayStart = (now = Date.now()) => Math.floor(now / 86400000) * 86400000;
