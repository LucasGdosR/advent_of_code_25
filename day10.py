from scipy.optimize import milp, LinearConstraint, Bounds
import numpy as np

def parse_diagram(s: str):
    return np.array([c == '#' for c in s])


def parse_buttons(buttons: list[str]) -> list[list[int]]:
    return [list(map(int, b[1:-1].split(','))) for b in buttons]


def parse_joltage(s: str) -> list[int]:
    return np.array(list(map(int, s.split(','))))


def buttons_to_vectors(B: list[list[int]], L: int):
    return np.array([[1 if i in b else 0 for i in range(L)] for b in B])


def solve_p1(X, b):
    A = np.hstack([X.T, -2 * np.eye(len(b))])
    A_sum = np.concatenate([np.ones(len(X)), np.zeros(len(b))]).reshape(1, -1)
    A_full = np.vstack([A, A_sum])
    return int(
        milp(
            c=np.concatenate([np.ones(len(X)), np.zeros(len(b))]),
            constraints=LinearConstraint(
                A_full,
                lb=np.concatenate([b, [1]]),
                ub=np.concatenate([b, [np.inf]])
            ),
            bounds=Bounds(
                lb=np.concatenate([np.zeros(len(X)), -len(b)**2 * np.ones(len(b))]),
                ub=np.concatenate([len(b) * np.ones(len(X)), len(b)**2 * np.ones(len(b))])
            ),
            integrality=1
        ).fun
    )


def solve_p2(X, b):
    return int(
        milp(
            c=np.ones(len(X)),
            constraints=LinearConstraint(
                X.T,
                lb=b,
                ub=b
            ),
            bounds=Bounds(
                lb=0,
                ub=np.inf
            ),
            integrality=1
        ).fun
    )


def main():
    with open('input/10') as f:
        p1 = 0
        p2 = 0
        for line in f:
            fields = line.split(' ')
            lights = parse_diagram(fields[0][1:-1])
            buttons = parse_buttons(fields[1:-1])
            joltage = parse_joltage(fields[-1].strip()[1:-1])
            vectors = buttons_to_vectors(buttons, len(joltage))
            p1 += solve_p1(vectors, lights)
            p2 += solve_p2(vectors, joltage)
        print(p1, p2)


if __name__ == '__main__':
    main()
