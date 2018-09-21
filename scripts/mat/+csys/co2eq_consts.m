function [ co2eq ] = co2eq_consts( temperature, salinity , mehrbach)

% \[ [[k_h2co3]] = \frac{[H][HCO_3]}{[H_2CO_3]}, \]
% from Millero p.664 (1995) using Mehrbach et al.\ data on seawater scale.
%
% \[ [[k_hbo2]] = \frac{[H][BO_2]}{[HBO_2]}, \]
% from Millero p.669 (1995) using data from Dickson (1990).
%
% \[ [[k_h3po4]] = \frac{[H][H_2PO_4]}{[H_3PO_4]}, \]
% from Millero p.670 (1995).
%
% \[ [[k_h2po4]] = \frac{[H][HPO_4]}{[H_2PO_4]} \]
% from Millero p.670 (1995).
%
% \[ [[k_hpo4]] = \frac{[H][PO_4]}{[HPO_4]} \]
% from Millero p.670 (1995).
%
% \[ [[k_sioh4]] = \frac{[H][SiO(OH)_3]}{[Si(OH)_4]} \]
% from Millero p.671 (1995) using data from Yao and Millero (1995).
%
% \[ [[k_oh]] = [H][OH] \]
% from Millero p.670 (1995) using composite data.
%
% \[ [[k_hso4]] = \frac{[H][SO_4]}{[HSO_4]} \]
% from Dickson (1990, J. chem.\ Thermodynamics 22, 113).
%
% \[ [[k_hf]] = \frac{[H][F]}{[HF]} \]
% from Dickson and Riley (1979) -- change pH scale to total.
%
% The calculations of concentrations for boron_total, sulfate, and fluoride
% are from Uppstrom (1974), Morris and Riley (1966), and Riley (1965).
%
% Temperature is in degrees~C and salinity is in parts per thousand.
% Both are two dimensional.  {\em Concentrations (of boron_total, sulfate,
% and fluoride) are calculated in $\frac{mol}{kg}$.}


ZERO_C_IN_KELVIN = 273.15;

t_kel = temperature + ZERO_C_IN_KELVIN;
t_sca = t_kel .* 0.01;
t_sq = t_sca .* t_sca;
t_inv = 1.0 ./ t_kel;
t_log = log( t_kel );

s = salinity;
s_sq = s .* s;
s_sqrt = sqrt( s );
s_1p5 = s .^ 1.5;
s_cl = s ./ 1.80655;

is = 19.924 .* s ./ ( 1000.0 - 1.005 .* s );
is_sq = is .* is;
is_sqrt = sqrt( is );

if mehrbach
    % Mehrbach on pH_total
    k_h2co3 = 10 .^ ( ...
        - 3633.86 ./ t_kel + 61.2172 - 9.6777 .* t_log + 0.011555 .* s ...
        - 0.0001152 .* s_sq ...
        );
    k_hco3 = 10 .^ ( ...
        - 471.78 ./ t_kel - 25.9290 + 3.16967 .* t_log + 0.01781 .* s ...
        - 0.0001122 .* s_sq ...
        );
    % Mehrbach on pH_sws
%     k_h2co3 = 10.0 .^ ...
%         ( - 3670.7 .* t_inv + 62.008 - 9.7944 .* t_log ...
%         + 0.0118 .* s  - 0.000116 .* s_sq );
%     k_hco3 = 10.0 .^ ...
%         ( - 1394.7 .* t_inv - 4.777 + 0.0184 .* s ...
%         - 0.000118 .* s_sq );
else
    % roy et al (1993) Marine Chemistry, 44, 249, on pH_T (DOE rec)
    k_h2co3 = exp( ...
        -2307.1266 ./ t_kel + 2.83655 - 1.5529413 * log( t_kel ) ...
        + ( -4.0484 ./ t_kel - 0.20760841 ) .* s_sqrt + 0.08468345 .* s ...
        - 0.00654208 .* s_1p5 + log( 1 - 0.001005 .* s) ...
        );

    % Dickson (1990) Deep-sea res. 37, 755 (DOE rec)
    k_hco3 = exp( ...
        -3351.6106 ./ t_kel - 9.226508 - 0.2005743 .* log( t_kel ) ...
        + ( -23.9722 ./ t_kel - 0.106901773 ) .* s_sqrt + 0.1130822 .* s ...
        - 0.00846934 .* s_1p5 + log( 1 - 0.001005 .* s) ...
        );
end

k_h3po4 = exp ...
    ( - 4576.752 .* t_inv + 115.540 - 18.453 .* t_log ...
    + ( -106.736 .* t_inv + 0.69171 ) .* s_sqrt ...
    + ( -0.65643 .* t_inv - 0.01844 ) .* s ...
    );

k_h2po4 = exp ...
    ( - 8814.715 .* t_inv + 172.0883 - 27.927 .* t_log ...
    + ( -160.340 .* t_inv + 1.3566 ) .* s_sqrt ...
    + ( 0.37335 .* t_inv - 0.05778 ) .* s ...
    );

k_hpo4 = exp ...
    ( - 3070.75 .* t_inv - 18.126 ...
    + ( 17.27039 .* t_inv + 2.81197 ) .* s_sqrt ...
    + ( -44.99486 .* t_inv - 0.09984 ) .* s ...
    );

k_sioh4 = exp ...
    ( - 8904.2 .* t_inv + 117.385 - 19.334 .* t_log ...
    + ( -458.79 .* t_inv + 3.5913 ) .* is_sqrt ...
    + ( 188.74 .* t_inv - 1.5998) .* is ...
    + (-12.1652 .* t_inv + 0.07871) .* is_sq ...
    + log( 1.0 - 0.001005 .* s ) ...
    );

% k_oh = exp ...
%     ( - 13847.26 .* t_inv + 148.9802 - 23.6521 .* t_log ...
%     + ( 118.67 .* t_inv - 5.977 + ...
%     1.0495 .* t_log ) .* s_sqrt ...
%     - 0.01615 .* s ...
%     );
% following Zeebe and Wolf-Gladrow
k_oh = exp ...
    ( - 13847.26 .* t_inv + 148.96502 - 23.6521 .* t_log ...
    + ( 118.67 .* t_inv - 5.977 + ...
    1.0495 .* t_log ) .* s_sqrt ...
    - 0.01615 .* s ...
    );

k_hso4 = exp ...
    ( - 4276.1 .* t_inv + 141.328 - 23.093 .* t_log ...
    + ( - 13856. .* t_inv + 324.57 ...
    - 47.986 .* t_log ) .* is_sqrt ...
    + ( 35474 .* t_inv - 771.54 ...
    + 114.723 .* t_log ) .* is ...
    - 2698 .* t_inv .* is .^ 1.5 ...
    + 1776 .* t_inv .* is_sq ...
    + log( 1.0 - 0.001005 .* s ) ...
    );

boron_total = 0.000232 .* s_cl ./ 10.811;
sulfate = 0.14 .* s_cl ./ 96.062;
fluoride = 0.000067 .* s_cl ./ 18.9984;

k_hf = exp ...
    ( 1590.2 .* t_inv - 12.641 + 1.525 .* is_sqrt ...
    + log( 1.0 - 0.001005 .* s ) + log(1.0 + ( sulfate ./ k_hso4 ) )...
    );

k_hbo2 = exp ...
    ( ( - 8966.90 - 2890.53 .* s_sqrt - 77.942 .* s ...
    + 1.728 .* s_1p5 - 0.0996 .* s_sq ) .* t_inv ...
    + ...
    ( 148.0248 + 137.1942 .* s_sqrt + 1.62142 .* s ) ...
    + ...
    ( - 24.4344 - 25.085 .* s_sqrt ...
    - 0.2474 .* s ) .* t_log ...
    + ...
    0.053105 .* s_sqrt .* t_kel );

% co2 solubility
% Temperature is expected in degrees C, salinity in parts per thousand.
% The result is in mol.kg^{-1}.atm^{-1}
% co2_solubility = exp( ...
%     9345.17 ./ t_kel - 60.2409 + 23.3585 .* log( t_kel ./ 100 )...
%     + s .* ( ...
%     0.023517 - 0.00023656 .* t_kel + 0.0047036 .* ( t_kel ./ 100 ) .^ 2 ...
%     ) );
%co2_solubility = calc_co2_solubility(temperature,salinity); % mol.kg^{-1}.atm^{-1}
co2_solubility  = csys.co2sol(salinity,temperature,'fugacity') .* 1.0e6;
fugacity_coeff = csys.fugacity_coeff( temperature );

co2eq = struct( 'sol', co2_solubility, ...
    'k_h2co3', k_h2co3, ...
    'k_hco3', k_hco3, ...
    'k_h3po4', k_h3po4, ...
    'k_h2po4', k_h2po4, ...
    'k_hpo4', k_hpo4, ...
    'k_sioh4', k_sioh4, ...
    'k_oh', k_oh, ...
    'k_hso4', k_hso4, ...
    'k_hf', k_hf, ...
    'boron_total', boron_total, ...
    'sulfate', sulfate, ...
    'fluoride', fluoride, ...
    'k_hbo2', k_hbo2, ...
    'fugacity_coeff', fugacity_coeff );

end