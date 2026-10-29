# Project AMBROSIUM v10.0: 1D Thermal PDE Finite Difference Solver & CFL Proof
# Author: Jacob (Jake) James Rasmussen (ORCID: 0009-0009-7084-6523)

import numpy as np

def verify_cfl_stability():
    alpha_T = 1.43e-7  # m^2/s
    dx = 0.5e-6        # 0.5 um
    dt_cfl = (dx**2) / (2.0 * alpha_T) # 874.12 ns
    dt_op = 100.0e-9   # 100.0 ns
    r_ratio = (alpha_T * dt_op) / (dx**2) # 0.0572

    print("=" * 70)
    print("PROJECT AMBROSIUM v10.0: 1D THERMAL PDE CFL STABILITY PROOF")
    print("=" * 70)
    print(f"Grid Resolution (dx):         {dx*1e6:.2f} um")
    print(f"Thermal Diffusivity (alpha_T): {alpha_T:.3e} m^2/s")
    print(f"Critical Max CFL Step (dt_CFL): {dt_cfl*1e9:.2f} ns")
    print(f"Operational Time Step (dt):    {dt_op*1e9:.2f} ns")
    print(f"Courant Stability Ratio (r):  {r_ratio:.4f} << 0.50")
    print("=" * 70)
    assert r_ratio < 0.50, "Courant stability ratio exceeds 0.50!"
    return dt_cfl, dt_op, r_ratio

def run_simulation():
    dx = 0.5e-6
    dt = 100.0e-9
    alpha_T = 1.43e-7
    L = 50.0e-6
    Nx = int(L / dx) + 1
    T = np.full(Nx, 25.0)
    q_rf = 5.8e8
    rho = 1050.0
    cp = 3800.0
    r = alpha_T * dt / (dx**2)
    source_term = (q_rf / (rho * cp)) * dt
    total_steps = int(0.85 / dt)

    for step in range(1, total_steps + 1):
        T_new = T.copy()
        T_new[1:-1] = T[1:-1] + r * (T[2:] - 2*T[1:-1] + T[:-2]) + source_term
        T_new[0] = 25.0
        T_new[-1] = 25.0
        T = T_new

    max_T = np.max(T)
    print(f"Peak Gelation Temp at t=0.85s: {max_T:.2f} deg C")
    return max_T

if __name__ == "__main__":
    verify_cfl_stability()
    run_simulation()
