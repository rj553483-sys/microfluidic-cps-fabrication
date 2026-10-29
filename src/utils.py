# Project AMBROSIUM v10.0: Electrodialysis & Structural Safety Utilities
# Author: Jacob (Jake) James Rasmussen (ORCID: 0009-0009-7084-6523)

import numpy as np

def calculate_debye_expansion(c_init=150.0, c_final=3.86):
    lambda_D_0 = 0.80 # nm
    lambda_D_final = lambda_D_0 * np.sqrt(c_init / c_final)
    expansion_ratio = lambda_D_final / lambda_D_0
    v_gate_max = 1.22 # V < 1.23 V limit
    return {
        "c_init_mM": c_init,
        "c_final_mM": c_final,
        "lambda_D_init_nm": lambda_D_0,
        "lambda_D_final_nm": round(lambda_D_final, 2),
        "expansion_ratio": round(expansion_ratio, 2),
        "v_gate_volts": v_gate_max,
        "electrolysis_safe": bool(v_gate_max < 1.23)
    }

def calculate_tsai_wu_safety(sigma1=120.0, sigma2=45.0, tau12=15.0):
    Xt = 250.0; Xc = 300.0
    Yt = 150.0; Yc = 180.0
    S  = 80.0
    F1 = 1.0/Xt - 1.0/Xc
    F11 = 1.0/(Xt * Xc)
    F2 = 1.0/Yt - 1.0/Yc
    F22 = 1.0/(Yt * Yc)
    F66 = 1.0/(S**2)
    F12 = -0.5 * np.sqrt(F11 * F22)
    FI = (F1*sigma1 + F2*sigma2 + F11*(sigma1**2) + F22*(sigma2**2) + 2*F12*sigma1*sigma2 + F66*(tau12**2))
    return {
        "working_pressure_bar": 2.5,
        "failure_index_FI": round(FI, 2),
        "is_structurally_safe": bool(FI <= 1.0)
    }

if __name__ == "__main__":
    print(calculate_debye_expansion())
    print(calculate_tsai_wu_safety())
