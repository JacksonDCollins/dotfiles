"""Dependency setup with mocked pacman/sudo and a disposable dotfiles clone."""
import os
import subprocess
import tempfile
from pathlib import Path

repo = Path(__file__).resolve().parents[1]
source = (repo / 'setup.sh').read_text()
with tempfile.TemporaryDirectory() as tmp:
    root = Path(tmp)
    (root / 'machines/default').mkdir(parents=True)
    (root / 'setup.sh').write_text(source)
    manifest = root / 'packages-arch.txt'
    original = (repo / 'packages-arch.txt').read_text()
    manifest.write_text(original)
    (root / 'install.sh').write_text('echo "install:$*" >> "$CALLS"\n')
    bin_dir = root / 'bin'
    bin_dir.mkdir()
    for name, content in {
        'pacman': '''#!/bin/bash
printf 'pacman:%s\\n' "$*" >> "$CALLS"
case "$1" in
    -Q) exit "${QUERY_STATUS:-1}" ;;
    -Syu) exit "${INSTALL_STATUS:-0}" ;;
    *) exit 99 ;;
esac
''',
        'sudo': '#!/bin/bash\necho sudo >> "$CALLS"\nexec "$@"\n',
    }.items():
        tool = bin_dir / name
        tool.write_text(content)
        tool.chmod(0o755)
    calls = root / 'calls'
    env = dict(os.environ, PATH=f'{bin_dir}:{os.environ["PATH"]}', CALLS=str(calls))

    def run(status=0, profile='default'):
        calls.write_text('')
        result = subprocess.run(['bash', root / 'setup.sh', profile], env=env, capture_output=True, text=True)
        assert result.returncode == status, result.stderr
        return calls.read_text()

    if os.geteuid() == 0:
        assert run(status=1) == ''  # Guard refuses a real root caller.
        # Exercise the remaining logic in a test-only copy, with all commands mocked.
        (root / 'setup.sh').write_text(source.replace('(( EUID != 0 ))', '(( 1 ))'))
    log = run()
    expected = ' '.join(original.splitlines())
    assert f'pacman:-Syu --needed -- stow {expected}' in log
    assert log.endswith('install:default\n')
    env['QUERY_STATUS'] = '0'
    log = run()
    assert 'sudo' not in log and '-Syu' not in log
    assert log.endswith('install:default\n')
    env['QUERY_STATUS'] = '1'
    env['INSTALL_STATUS'] = '7'
    assert 'install:' not in run(status=7)
    del env['INSTALL_STATUS']
    assert run(status=1, profile='../bad') == ''
    for invalid in ['', '--root=/tmp\n', 'fzf;touch hacked\n', 'fzf\n\n']:
        manifest.write_text(invalid)
        assert run(status=1) == ''
    manifest.unlink()
    assert run(status=1) == ''
print('PASS: missing deps installed, installed deps skipped, failures/invalid manifests stop before config installation')
