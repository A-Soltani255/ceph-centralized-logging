import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
import YAML from 'yaml';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const ignore = new Set(['.git', 'node_modules', 'reports']);
const walk = dir => fs.readdirSync(dir, {withFileTypes: true}).flatMap(e =>
  ignore.has(e.name) ? [] : e.isDirectory() ? walk(path.join(dir,e.name)) : [path.join(dir,e.name)]);
const files = walk(root);
const failures=[];
const fail=(file,message)=>failures.push(`${path.relative(root,file)}: ${message}`);
const headings = content => {
  const counts=new Map();
  return new Set([...content.matchAll(/^#{1,6} (.+)$/gm)].map(m=>{
    let id=m[1].replace(/[`*_]/g,'').toLowerCase().replace(/[^\p{L}\p{N}\s_-]/gu,'').replace(/ /g,'-');
    const n=counts.get(id)||0;counts.set(id,n+1);return n?`${id}-${n}`:id;
  }));
};
let links=0,yamlCount=0,jsonCount=0;
for (const file of files) {
  if (/\.(png|zip|pdf)$/.test(file)) continue;
  const text=fs.readFileSync(file,'utf8');
  if(text.includes('\r')) fail(file,'CR line endings; LF required');
  if(!text.endsWith('\n')) fail(file,'missing terminal newline');
  if(file.endsWith('.md')) {
    const fenceCount=(text.match(/^```/gm)||[]).length;
    if(fenceCount%2)fail(file,'unbalanced fenced blocks');
    for(const m of text.matchAll(/\[[^\]]*\]\(([^)]+)\)/g)) {
      const href=m[1].split(' "')[0];
      if(/^[a-z][a-z0-9+.-]*:/i.test(href))continue;
      const [relative,anchor]=href.split('#');
      const target=relative?path.resolve(path.dirname(file),decodeURIComponent(relative)):file;
      links++;
      if(!target.startsWith(root+path.sep)&&target!==root)fail(file,`link escapes repository: ${href}`);
      else if(!fs.existsSync(target))fail(file,`missing link: ${href}`);
      else if(anchor&&target.endsWith('.md')&&!headings(fs.readFileSync(target,'utf8')).has(anchor))fail(file,`missing anchor: ${href}`);
    }
  }
  if(/\.ya?ml$/.test(file)) {
    yamlCount++;
    for(const doc of YAML.parseAllDocuments(text,{uniqueKeys:true})) {
      for(const error of doc.errors)fail(file,error.message);
      const obj=doc.toJSON();
      if(obj?.kind==='Secret')fail(file,'Secret resource forbidden in published examples');
      if(obj?.kind==='Service'&&obj.spec?.type!=='ClusterIP')fail(file,'unexpected service exposure');
    }
  }
  if(file.endsWith('.json')) {jsonCount++;try{JSON.parse(text);}catch(e){fail(file,e.message);}}
  // Generic safety guard. Detailed confidential-value matching is run separately outside Git.
  if(/-----BEGIN (?:[A-Z ]+)?PRIVATE KEY-----/.test(text))fail(file,'private key material');
  if(text.includes(['-----BEGIN','CERTIFICATE-----'].join(' ')))fail(file,'certificate material not permitted');
  if(/\b(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,}|AKIA[A-Z0-9]{16})\b/.test(text))fail(file,'credential-shaped token');
  if(/(?:https?:\/\/)[^\s/@]+:[^\s/@]+@/.test(text))fail(file,'URL with embedded credentials');
}
const conf=fs.readFileSync(path.join(root,'configs/fluent-bit/ceph.conf'),'utf8');
const parsers=fs.readFileSync(path.join(root,'configs/fluent-bit/ceph-parsers.conf'),'utf8');
const names=new Set([...parsers.matchAll(/^\s+Name\s+(\S+)/gm)].map(m=>m[1]));
for(const m of conf.matchAll(/^\s+Parser\s+(\S+)/gm)) if(!names.has(m[1]))fail('ceph.conf',`undefined parser ${m[1]}`);
const dbs=[...conf.matchAll(/^\s+DB\s+(\S+)/gm)].map(m=>m[1]);
if(dbs.length!==4||new Set(dbs).size!==4)fail('ceph.conf','expected four independent DB paths');
if(!conf.includes('Parsers_File /etc/fluent-bit/ceph-parsers.conf'))fail('ceph.conf','parser deployment path changed');
if(!conf.includes('Host logs.example.com')||!conf.includes('tls.vhost logs.example.com'))fail('ceph.conf','endpoint/SNI mismatch');
for(const item of JSON.parse(fs.readFileSync(path.join(root,'configs/provenance.json'),'utf8'))) {
  const target=path.join(root,item.file);
  const sha=crypto.createHash('sha256').update(fs.readFileSync(target)).digest('hex');
  if(sha!==item.sanitizedContentSha256)fail(target,'extracted artifact differs from provenance hash; review and record change');
}
const result={files:files.length,relativeLinks:links,yamlFiles:yamlCount,jsonFiles:jsonCount,parserDefinitions:names.size,failures};
console.log(JSON.stringify(result,null,2));
process.exitCode=failures.length?1:0;
