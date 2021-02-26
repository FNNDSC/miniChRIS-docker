/*
 * *.js wrapper to `.sh` scripts.
 * Needed because only *JavaScript actions* support `post` jobs.
 * https://docs.github.com/en/free-pro-team@latest/actions/creating-actions/metadata-syntax-for-github-actions#post
 */

const { execFileSync } = require('child_process');
const path = require('path');
const isPost = !!process.env['STATE_isPost'];

const script = path.join(__dirname, isPost ? 'unmake.sh' : 'minichris.sh');
execFileSync(script, { stdio: 'inherit' });

if (!isPost) {
  console.log('::save-state name=isPost::true');
}
