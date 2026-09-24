import test from 'node:test';
import assert from 'node:assert/strict';
import {randomUUID} from 'node:crypto';
import {fixture, account, request} from './helpers.mjs';

test('Both cat identities persist, own their default bodies and complete an authoritative Arena battle', async () => {
  const f = await fixture();
  try {
    const owners = [await account(f.db), await account(f.db)];
    const cats = [];
    for (const [index, id] of ['onix', 'bruma'].entries()) {
      const response = await request(f.mf, owners[index], '/v1/fighters', 'POST', {
        archetype_id: id, display_name: id === 'onix' ? 'Ónix' : 'Bruma',
      }, {'Idempotency-Key': randomUUID()});
      assert.equal(response.status, 201, JSON.stringify(response.body));
      const cat = response.body.data;
      assert.equal(cat.archetype_id, id);
      assert.equal(cat.appearance.body_style_id, id);
      assert.equal(cat.progression.level, 1);
      assert.equal(cat.progression.unlocked_moves.length, 2);
      assert.equal(cat.combatant.character_id, id);
      assert.equal(cat.combatant.visual.atlas, `res://assets/sprites/${id}-v1.png`);
      const restored = (await request(f.mf, owners[index], '/v1/fighters')).body.data.fighters;
      assert.equal(restored[0].fighter_id, cat.fighter_id);
      assert.deepEqual(restored[0].progression, cat.progression);
      cats.push(cat);
    }
    const match = await request(f.mf, owners[0], '/v1/battles', 'POST', {
      fighter_id: cats[0].fighter_id, opponent_id: cats[1].fighter_id,
    }, {'Idempotency-Key': randomUUID()});
    assert.equal(match.status, 201, JSON.stringify(match.body));
    const battle = match.body.data.battle;
    const snapshot = battle.record.battle_snapshot;
    assert.equal(snapshot.player.character_id, 'onix');
    assert.equal(snapshot.rival.character_id, 'bruma');
    assert.ok(snapshot.events.some(event => event.type === 'attack'));
    assert.equal(snapshot.events.at(-1).type, 'finished');
    const defense = await request(f.mf, owners[1], `/v1/battles/${battle.id}`);
    assert.equal(defense.status, 200);
    assert.equal(defense.body.data.battle.viewing_side, 'rival');
    for (const owner of owners) {
      const restored = (await request(f.mf, owner, '/v1/fighters')).body.data.fighters[0];
      assert.ok(restored.progression.total_xp > 0);
    }
  } finally {
    await f.close();
  }
});
