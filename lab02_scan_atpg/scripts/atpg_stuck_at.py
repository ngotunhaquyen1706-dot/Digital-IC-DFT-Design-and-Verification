#!/usr/bin/env python3
"""Educational exhaustive ATPG for one internal node stuck-at fault.
Model scope: two faults (node AND(q0,q1) SA0 and SA1) only.
Not a replacement for Synopsys TestMAX ATPG.
"""
from pathlib import Path


def next_state(q: int, fault: str = 'GOOD') -> int:
    b = [(q >> i) & 1 for i in range(8)]
    mid = b[0] & b[1]
    if fault == 'SA0': mid = 0
    if fault == 'SA1': mid = 1
    y = [0] * 8
    y[0] = (mid ^ b[2]) & b[3]
    y[1] = b[1] ^ b[3]
    y[2] = b[2] | b[4]
    y[3] = b[3] & (1 - b[5])
    y[4] = b[4] ^ b[6]
    y[5] = b[5] | b[7]
    y[6] = b[6] ^ b[0]
    y[7] = b[7] & b[1]
    return sum(bit << i for i, bit in enumerate(y))


def run():
    lines = ['Educational exhaustive stuck-at pattern generation',
             'Fault site: internal node n0 = q[0] AND q[1]',
             'Propagation: next[0] = (n0 XOR q[2]) AND q[3]',
             'Tested fault universe: 2 single stuck-at faults ONLY', '']
    found = {}
    for fault in ['SA0', 'SA1']:
        matches = [x for x in range(256) if next_state(x) != next_state(x, fault)]
        p = matches[0] if matches else None
        found[fault] = p
        lines.append(f'{fault}: {len(matches)} detecting patterns / 256')
        if p is not None:
            lines.append(f'  first pattern: {p:08b} (0x{p:02X})')
            lines.append(f'  good capture:  {next_state(p):08b} (0x{next_state(p):02X})')
            lines.append(f'  faulty capture:{next_state(p, fault):08b} (0x{next_state(p, fault):02X})')
        else:
            lines.append('  UNDETECTED')
        lines.append('')
    coverage = sum(v is not None for v in found.values()) / len(found) * 100
    lines.append(f'Coverage of the TWO MODELED faults: {coverage:.1f}%')
    lines.append('Not whole-circuit stuck-at fault coverage.')
    output = '\n'.join(lines) + '\n'
    print(output)
    report = Path(__file__).resolve().parent / 'atpg_report.txt'
    report.write_text(output, encoding='utf-8')
    assert found == {'SA0': 0x0B, 'SA1': 0x08}, found
    assert next_state(0x0B) != next_state(0x0B, 'SA0')
    assert next_state(0x08) != next_state(0x08, 'SA1')
    print('PYTHON MODEL CHECKS PASSED')


if __name__ == '__main__':
    run()
