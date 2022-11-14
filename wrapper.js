/*
 * *.js wrapper to `.sh` scripts.
 * 
 * - Needed because only *JavaScript actions* support `post` jobs
 * - Also adds the data from the `input` variable to chrisomatic.yml
 *
 * https://docs.github.com/en/free-pro-team@latest/actions/creating-actions/metadata-syntax-for-github-actions#post
 */


const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const assert = require('node:assert/strict');


const IS_POST = !!process.env['STATE_isPost'];



if (process.argv[2] === 'test') {
  test();
}
else {
  main();
}

function main() {
  const inputPlugins = !!process.env['INPUT_plugins'];
  const pluginsAsYml = inputPlugins2yml(inputPlugins);
  const chrisomaticFileName = path.join(__dirname, 'chrisomatic.yml');
  fs.appendFileSync(chrisomaticFileName, pluginsAsYml);

  const script = path.join(__dirname, IS_POST ? 'unmake.sh' : 'minichris.sh');
  execFileSync(script, { stdio: 'inherit' });

  if (!IS_POST) {
    console.log('::save-state name=isPost::true');
  }
}

function test() {
  console.log('running unit tests');

  assert.deepEqual(removeComment(''), '');
  assert.deepEqual(removeComment('bee\n'), 'bee\n');
  assert.deepEqual(removeComment('bee  # comment\n'), 'bee  ');

  assert.deepEqual(
    ['pl-dircopy', 'tabbed', 'https://chrisstore.co/api/v1/plugins/101/'],
    parsePlugins('  pl-dircopy\n#comment line\n  tabbed\nhttps://chrisstore.co/api/v1/plugins/101/\n\n\n')
  );

  assert.deepEqual(
    '\n    - pl-dircopy\n     - pl-med2img\n     - pl-covidnet\n',
    plugins2yml(['pl-dircopy', 'pl-med2img', 'pl-covidnet'])
  );

  assert.deepEqual(
    '',
    inputPlugins2yml('').trim()
  );
}

function inputPlugins2yml(input) {
  return plugins2yml(parsePlugins(input));
}

function plugins2yml(plugins) {
  return `\n${plugins.map((plugin) => `    - ${plugin}\n`).join(' ')}`;
}

function parsePlugins(input) {
  return input
    .split('\n')
    .map(removeComment)
    .map((pl) => pl.trim())
    .filter((pl) => pl !== '')
}

function removeComment(line) {
  const commentStartsAt = line.indexOf('#');
  if (commentStartsAt === -1) {
    return line;
  }
  return line.substring(0, commentStartsAt);
}
