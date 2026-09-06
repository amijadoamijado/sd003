"""Windows regression checks for real checkout/worktree Lead lock ownership.
Run: python tests/integration/lead-lock-regression.py
Uses isolated temporary Git repositories; never accesses the project Lead lock.
"""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


def checked(*args):
    return subprocess.run(args, check=True, capture_output=True, text=True).stdout.strip()


def run(repo, action, expected=0):
    result = subprocess.run(
        ['pwsh', '-NoProfile', '-File', str(repo / 'scripts/lead-lock.ps1'), action, 'codex'],
        capture_output=True, text=True,
    )
    assert result.returncode == expected, (action, result.stdout, result.stderr)
    return result


def main():
    source = Path(__file__).resolve().parents[2] / 'scripts/lead-lock.ps1'
    with tempfile.TemporaryDirectory(prefix='sd003-lock-regression-') as temporary:
        base = Path(temporary)
        repo, work = base / 'repo', base / 'worktree'
        repo.mkdir()
        checked('git', 'init', str(repo))
        (repo / 'scripts').mkdir()
        shutil.copyfile(source, repo / 'scripts/lead-lock.ps1')
        checked('git', '-C', str(repo), 'add', 'scripts/lead-lock.ps1')
        checked('git', '-C', str(repo), '-c', 'user.name=Lock QA', '-c', 'user.email=qa@localhost', 'commit', '-m', 'fixture')
        checked('git', '-C', str(repo), 'worktree', 'add', '--detach', str(work))
        try:
            for checkout in (repo, work):
                run(checkout, 'acquire')
                assert 'live ai=codex' in run(checkout, 'status').stdout
                run(checkout, 'acquire')
                run(checkout, 'release')
            run(repo, 'acquire')
            run(work, 'acquire')
            run(repo, 'release')
            run(work, 'release')
            print('PASS: checkout/worktree lifecycle, idempotence and independent locks', flush=True)

            lock = repo / '.git/sd-lead.lock'
            lock.write_text(json.dumps(dict(ai='codex', pid=os.getppid(), startedAt='fixture')))
            before = lock.read_bytes()
            run(repo, 'acquire', 1)
            run(repo, 'release', 1)
            assert lock.read_bytes() == before
            lock.unlink()
            lock.write_text('{')
            run(repo, 'acquire', 1)
            assert lock.read_text() == '{'
            lock.unlink()
            print('PASS: foreign owner and malformed lock remain protected', flush=True)

            # Distinct Python parents stay alive while both acquisitions finish.
            script = str(repo / 'scripts/lead-lock.ps1')
            worker = ('import subprocess,time,json; p=subprocess.run('
                      + repr(['pwsh', '-NoProfile', '-File', script, 'acquire', 'codex'])
                      + ',capture_output=True,text=True); print(json.dumps([p.returncode,p.stdout,p.stderr]),flush=True); time.sleep(10)')
            children = [subprocess.Popen([sys.executable, '-c', worker], stdout=subprocess.PIPE, text=True) for _ in range(2)]
            try:
                results = [json.loads(child.stdout.readline()) for child in children]
                assert sorted(result[0] for result in results) == [0, 1], results
            finally:
                for child in children:
                    child.wait(timeout=30)
            run(repo, 'acquire')
            run(repo, 'release')
            print('PASS: concurrent acquisition has one winner; stale owner recovery succeeds', flush=True)

            # Deny only file creation in the disposable fixture, then restore its ACL.
            user = checked('whoami')
            git_dir = str(repo / '.git')
            try:
                checked('icacls', git_dir, '/deny', user + ':(WD)')
                result = run(repo, 'acquire', 1)
                assert 'acquired' not in result.stdout
                assert not lock.exists()
            finally:
                checked('icacls', git_dir, '/remove:d', user)
            print('PASS: write failure returns nonzero without success or lock', flush=True)
        finally:
            checked('git', '-C', str(repo), 'worktree', 'remove', str(work))


if __name__ == '__main__':
    main()
