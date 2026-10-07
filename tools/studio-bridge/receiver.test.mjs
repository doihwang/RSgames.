import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { createReceiver } from './receiver.mjs';
test('append-only snapshots; reject unauthorized requests and unowned roots', async () => {
  const output = await fs.mkdtemp(path.join(os.tmpdir(), 'warrr-bridge-'));
  const server = createReceiver({token:'test-token', output});
  await new Promise(resolve => server.listen(0,'127.0.0.1',resolve));
  try {
    const url = `http://127.0.0.1:${server.address().port}/snapshot`;
    const payload = {version:1,roots:[{path:'Workspace/UserOwned',tree:{name:'UserOwned',className:'Folder',children:[{name:'../../escape',className:'Part',children:[]}]}}]};
    const send = (body, token='test-token', extra={}) => fetch(url,{method:'POST',headers:{'X-Warrr-Token':token,...extra},body:JSON.stringify(body)});
    assert.equal((await send(payload,'wrong')).status,403);
    assert.equal((await send(payload,'test-token',{Origin:'https://example.com'})).status,403);
    assert.equal((await send({version:1,roots:[{...payload.roots[0],path:'Workspace'}]})).status,400);
    const first = await (await send(payload)).json();
    const second = await (await send(payload)).json();
    assert.equal(first.ok,true); assert.notEqual(first.snapshot,second.snapshot);
    assert.equal((await fs.readdir(output)).length,2);
    assert.deepEqual((await fs.readdir(path.join(output,first.snapshot))).sort(),['snapshot.json','tree.txt']);
    const saved = JSON.parse(await fs.readFile(path.join(output,first.snapshot,'snapshot.json'),'utf8'));
    assert.equal(saved.roots[0].tree.children[0].name,'../../escape');
    assert.equal((await fetch(url,{method:'GET',headers:{'X-Warrr-Token':'test-token'}})).status,404);
  } finally { await new Promise(resolve => server.close(resolve)); }
});
