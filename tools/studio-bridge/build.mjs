import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
const dir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(dir, '../..');
const configPath = path.join(root, '.studio-bridge-local.json');
let config;
try { config = JSON.parse(await fs.readFile(configPath, 'utf8')); }
catch (error) {
  if (error.code !== 'ENOENT') throw error;
  config = {token:crypto.randomBytes(32).toString('hex')};
  await fs.writeFile(configPath, JSON.stringify(config), {flag:'wx'});
}
const source = (await fs.readFile(path.join(dir, 'Plugin.plugin.luau'), 'utf8')).replace('__PAIRING_TOKEN__', config.token);
const escape = text => text.replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;');
const xml = `<roblox version="4"><Item class="Script"><Properties><string name="Name">WarrrStudioBridge</string><ProtectedString name="Source">${escape(source)}</ProtectedString></Properties></Item></roblox>`;
await fs.mkdir(path.join(dir, 'dist'), {recursive:true});
await fs.writeFile(path.join(dir, 'dist/WarrrStudioBridge.rbxmx'), xml);
console.log('Built tools/studio-bridge/dist/WarrrStudioBridge.rbxmx (contains local pairing token; do not publish).');
