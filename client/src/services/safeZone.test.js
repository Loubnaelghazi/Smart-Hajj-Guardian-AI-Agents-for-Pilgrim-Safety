import test from 'node:test';
import assert from 'node:assert/strict';
import {zonePayload} from './safeZone.js';
const base={name:'Mina meeting point',latitude:21.4133,longitude:39.8933,radius_m:'250'};
test('map coordinates retain precision and radius becomes API integer',()=>assert.deepEqual(zonePayload(base),{...base,radius_m:250}));
test('unselected map cannot silently save zero coordinates',()=>assert.throws(()=>zonePayload({...base,latitude:''})));
test('zero coordinates are valid when explicitly selected',()=>assert.equal(zonePayload({...base,latitude:0,longitude:0}).latitude,0));
test('invalid coordinates and radii fail before sending',()=>{for(const patch of [{latitude:91},{longitude:181},{latitude:NaN},{radius_m:0},{radius_m:1.5},{radius_m:Infinity}])assert.throws(()=>zonePayload({...base,...patch}));});
