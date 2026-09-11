import test from 'node:test';
import assert from 'node:assert/strict';
import { displayStatus, selectTracking } from './tracking.js';

test('locations expire locally even when polling fails', () => {
  const entry = {status: 'fresh', observation: {age_seconds: 118, zone_state: 'inside'}};
  assert.equal(displayStatus(entry, 1), 'inside');
  assert.equal(displayStatus(entry, 3), 'stale');
});
test('missing and server-stale locations never claim safety', () => {
  assert.equal(displayStatus({observation: null}), 'no_location');
  assert.equal(displayStatus({status: 'stale', observation: {age_seconds: 1, zone_state: 'inside'}}), 'stale');
});

const data = {
  groups: [{id: 'a', guide_id: 'guide-a'}, {id: 'b', guide_id: 'guide-b'}, {id: 'c', guide_id: null}],
  pilgrims: [
    {pilgrim_id: 'p1', name: 'Amal', group_id: 'a', status: 'fresh', observation: {age_seconds: 10, zone_state: 'inside'}},
    {pilgrim_id: 'p2', name: 'Youssef', group_id: 'a', status: 'fresh', observation: {age_seconds: 10, zone_state: 'outside'}},
    {pilgrim_id: 'p3', name: 'Salma', group_id: 'b', observation: null},
    {pilgrim_id: 'p4', name: 'Omar', group_id: 'c', observation: null},
  ],
};
test('guide, group, search and status filters compose', () => {
  const result = selectTracking(data, {guide: 'guide-a', group: 'a', query: ' YOUS ', status: 'outside'});
  assert.deepEqual(result.entries.map(p => p.pilgrim_id), ['p2']);
  assert.equal(selectTracking(data, {guide: 'guide-b', group: 'a'}).entries.length, 0);
  assert.deepEqual(selectTracking(data, {guide: 'unassigned'}).entries.map(p => p.pilgrim_id), ['p4']);
});
test('attention sorting and connection loss never claim fresh inside status', () => {
  assert.equal(selectTracking(data, {sort: 'attention'}).entries[0].pilgrim_id, 'p2');
  const offline = selectTracking(data, {status: 'inside'}, 0, true);
  assert.equal(offline.entries.length, 0);
  assert.equal(offline.counts.stale, 2);
});
test('pagination bounds list and clamps page when results shrink', () => {
  const many = {groups: [], pilgrims: Array.from({length: 27}, (_, i) => ({pilgrim_id: `${i}`, name: `Pilgrim ${String(i).padStart(2, '0')}`, group_id: 'a'}))};
  assert.equal(selectTracking(many, {page: 1, size: 10}).entries.length, 10);
  const last = selectTracking(many, {page: 999, size: 10});
  assert.equal(last.page, 3); assert.equal(last.entries.length, 7);
  const empty = selectTracking(many, {query: 'missing', page: 3});
  assert.equal(empty.page, 1); assert.equal(empty.pages, 1); assert.equal(empty.entries.length, 0);
});
test('invalid age is treated as stale rather than safe', () => {
  assert.equal(displayStatus({status: 'fresh', observation: {zone_state: 'inside'}}), 'stale');
});
