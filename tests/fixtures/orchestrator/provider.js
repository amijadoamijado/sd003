const fs = require('fs');
const path = require('path');

const [stage, workspace] = process.argv.slice(2);
if (!stage || !workspace) process.exit(2);
const output = path.join(workspace, 'artifacts');
fs.mkdirSync(output, { recursive: true });
fs.writeFileSync(path.join(output, `${stage}.json`), JSON.stringify({ stage, status: 'succeeded' }, null, 2) + '\n');
process.stdout.write(JSON.stringify({ stage, status: 'succeeded' }));
