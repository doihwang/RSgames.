import http from 'node:http';
import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

export const roots = ['Workspace','ServerScriptService','ServerStorage','ReplicatedStorage','ReplicatedFirst','StarterGui','StarterPack','Lighting','SoundService'].map(x => `${x}/UserOwned`).concat(['StarterPlayer/StarterPlayerScripts/UserOwned','StarterPlayer/StarterCharacterScripts/UserOwned']);
export function createReceiver({ token, output }) {
  return http.createServer(async (req, res) => {
    const reply = (status, body) => { res.writeHead(status, {'Content-Type':'application/json'}); res.end(JSON.stringify(body)); };
    if (req.headers.origin || req.headers['x-warrr-token'] !== token) return reply(403, {error:'Pairing denied'});
    if (req.method !== 'POST' || req.url !== '/snapshot') return reply(404, {error:'Unknown endpoint'});
    try {
      let size = 0; const chunks = [];
      for await (const chunk of req) {
        size += chunk.length;
        if (size > 10 * 1024 * 1024) return reply(413, {error:'Snapshot exceeds 10 MB'});
        chunks.push(chunk);
      }
      let data;
      try { data = JSON.parse(Buffer.concat(chunks).toString('utf8')); } catch { return reply(400, {error:'Invalid JSON'}); }
      if (data.version !== 1 || !Array.isArray(data.roots) || data.roots.length > roots.length) return reply(400, {error:'Invalid snapshot'});
      let count = 0; const seen = new Set();
      const validate = (node, depth = 0) => {
        if (!node || depth > 100 || ++count > 20000 || typeof node.name !== 'string' || typeof node.className !== 'string' || !Array.isArray(node.children)) throw new Error('Invalid instance tree');
        for (const child of node.children) validate(child, depth + 1);
      };
      try {
        for (const root of data.roots) {
          if (!roots.includes(root.path) || seen.has(root.path) || root.tree?.name !== 'UserOwned' || root.tree?.className !== 'Folder') throw new Error('Invalid ownership root');
          seen.add(root.path); validate(root.tree);
        }
      } catch (error) { return reply(400, {error:error.message}); }
      // Remote instance names and paths NEVER become filesystem paths.
      const id = new Date().toISOString().replace(/[:.]/g,'-') + '-' + crypto.randomUUID();
      const destination = path.join(output, id);
      await fs.mkdir(destination, {recursive:true});
      const envelope = {kind:'reference-only-not-restorable-backup', receivedAt:new Date().toISOString(), ...data};
      await fs.writeFile(path.join(destination, 'snapshot.json'), JSON.stringify(envelope, null, 2), {flag:'wx'});
      const index = [];
      const walk = (node, parent) => {
        const display = `${parent}/${node.name}`;
        index.push(`${display} [${node.className}]`);
        for (const child of node.children) walk(child, display);
      };
      for (const root of data.roots) walk(root.tree, root.path.slice(0, -'/UserOwned'.length));
      await fs.writeFile(path.join(destination, 'tree.txt'), index.join('\n'), {flag:'wx'});
      reply(200, {ok:true, snapshot:id, instances:count});
      console.log(`Snapshot stored: ${id} (${count} instances)`);
    } catch (error) {
      console.error('Snapshot failed:', error.message);
      if (!res.headersSent) reply(500, {error:'Local snapshot write failed'});
    }
  });
}
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
  const config = JSON.parse(await fs.readFile(path.join(root, '.studio-bridge-local.json'), 'utf8'));
  const server = createReceiver({token:config.token, output:path.join(root,'studio-snapshots')});
  server.requestTimeout = 30000;
  server.on('error', error => { console.error(error.message); process.exitCode = 1; });
  server.listen(34873, '127.0.0.1', () => console.log('Studio receiver ready on 127.0.0.1:34873. Leave this terminal running.'));
}
