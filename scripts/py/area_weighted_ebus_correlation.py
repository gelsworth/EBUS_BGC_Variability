"""
Area Weighted EBUS Correlation
----------------------------
Author: Riley X. Brady
Date: Oct 11, 2017
Updated: Dec. 12, 2017

This script will correlate the area-weighted residuals time series for a given
EBUS with a climate index time series (from its corresponding ensemble member).
This is an updated script from the old version that used to use numpy arrays.
This will use xarray to its fully capacity and output an entire ensemble of 
correlations as a single netCDF file.

This now accounts for autocorrelation and thus computes the effective degrees
of freedom. This means that the p-value can be used more seriously when
smoothing data and correlating.

E.g. you can correlate the entire California Current FG_ALT_CO2 residuals with
the NPGO index. You can also specify whatever lag and smoothing necessary.

NOTE: To compare with an EOF of CO2 flux, just use EOF1, EOF2, or EOF3 for the
VARY argument. However, beware that this is only operational for FG_ALT_CO2
EOFs currently.

NOTE: There is probably a way to do this with "apply" but I can't figure out
how. It isn't as simple as doing .groupby('ensemble') and then calling
ds.x and ds.y in the apply function.

NOTE: This script is also written to handle PDO, ENSO, AMO, etc. from the
climate diagnostics package as well as NPGO. You will have to add functionality
for other single time series in the future. 

INPUT 1: Str for EBUS ('CalCS', 'CanCS', 'HumCS', 'BenCS')
INPUT 2: Predictor climate variable for the residuals 
    ('NPGO', 'PDO', 'ENSO', 'AMO', etc.)
INPUT 3: Dependent variable in the EBU
    (FG_ALT_CO2, FG_CO2, EOF1, EOF2, EOF3)
INPUT 4: Int for number of months to lag (0 is no lag).
INPUT 5: Int for how many months to smooth by (0 is no smoothing). 
"""
import glob
import sys
import os
import numpy as np
import xarray as xr
import esmtools as et

def load_AW_residuals(e, v):
    """
    Loads in the area-weighted residuals time series for the given upwelling
    system (e) and variable (v).
    """
    filepath = ('/glade/p/work/rbrady/EBUS_BGC_Variability/' + v + '/' +
                e + '/filtered_output/')
    filename = e.lower() + '-' + v + '-residuals-AW-chavez-800km.nc'
    ds = xr.open_dataset(filepath + filename)
    ds = ds[v + '_AW']
    return ds

def main():
    EBU = sys.argv[1]
    VARX = sys.argv[2]
    VARY = sys.argv[3]
    LAG = int(sys.argv[4])
    SMOOTH = int(sys.argv[5])
    print("Working on " + VARX + " regressions over the " + EBU + 
          " with " + str(LAG) + "mo. lag and " + str(SMOOTH) +
          " mo. smoothing...")
    if VARX == 'NPGO':
        """
        This was a custom EOF procedure, so the NC files are very different 
        from the way Adam Phillips set his up.
        """
        filepath = '/glade/p/work/rbrady/EBUS_BGC_Variability/NPGO/'
        ds_x = xr.open_mfdataset(filepath + '*.nc', concat_dim='ensemble')
        ds_x = ds_x['pc']
    elif VARX == 'NPH':
        """
        This is another custom procedure. A simple box over the Northeast
        Pacific that represents anomalies in the standard position of the
        NPH.
        """
        filepath = '/glade/p/work/rbrady/EBUS_BGC_Variability/indices/NPH/'
        filename = 'NPH.full_ensemble.192001-201512.nc'
        ds_x = xr.open_dataset(filepath + filename)
        ds_x = ds_x['NPH']
    else:
        """
        This assumes the variable can be found in Adam Phillip's climate
        diagnostics output. Need to edit this loading if that's not the
        case.
        """
        filepath = '/glade/p/work/rbrady/cesmLE_CVDP/processed/'
        filename = 'cvdp_detrended_BGC.nc'
        ds_x = xr.open_dataset(filepath + filename)
        ds_x = ds_x[VARX.lower()]
        if VARX == 'AMOC':
            """
            Account for the time dimension labeling.
             """
            ds_x = ds_x.rename({'TIME': 'time'})
    # Load in the Y variable.
    if VARY in ['EOF1', 'EOF2', 'EOF3']:
        filepath = ('/glade/p/work/rbrady/EBUS_BGC_Variability/' +
                    'regional_EOFs/' + EBU + '/FG_ALT_CO2/')
        filename = 'FG_ALT_CO2.' + EBU + '.EOF.192001-201512.nc'
        ds_y = xr.open_dataset(filepath + filename)
        if VARY == 'EOF1':
            ds_y = ds_y['pc'].sel(mode=0)
        elif VARY == 'EOF2':
            ds_y = ds_y['pc'].sel(mode=1)
        else:
            ds_y = ds_y['pc'].sel(mode=2)
        # Remove any trend (should be very slight).
        ds_y = ds_y.groupby('ensemble', squeeze=True) \
                   .apply(et.ufunc.remove_polynomial_fit)
    else:
        ds_y = load_AW_residuals(EBU, VARY)
    # Resample to annual resolution if dealing with AMOC, since it is only at
    # annual resolution.
    if VARX == 'AMOC':
        ds_y = ds_y.resample(freq='AS', dim='time')
        ds_y['time'] = np.arange(1920, 2016, 1)
    # Smooth if necessary.
    if SMOOTH != 0:
            ds_x = ds_x.rolling(time=SMOOTH).mean().dropna('time')
            ds_y = ds_y.rolling(time=SMOOTH).mean().dropna('time')
    # Combine into one dataset.
    ds_x.name = 'x'
    ds_y.name = 'y'
    ds = ds_x.to_dataset()
    ds['y'] = ds_y
    # Run the correlation (Here can definitely be improved..)
    m, r, p, n = ([] for i in range(4))
    for label, group in ds.groupby('ensemble'):
        """
        Run a simple correlation/regression, but need to check for all of the
        optional lag and smoothing settings.

        Updated to use new esmtools pearsonr which accounts for autocorrelation
        when smoothing.
        """
        if LAG == 0:
            M, _, _, _, _ = et.stats.linear_regression(group.x, group.y)
            R, P, N = et.stats.pearsonr(group.x, group.y)
            m.append(M)
            r.append(R)
            p.append(P)
            n.append(N)
        else:
            M, _, _, _, _ = et.stats.linear_regression(group.x[:-LAG],
                                                       group.y[LAG:])
            R, P, N = et.stats.pearsonr(group.x[:-LAG], group.y[LAG:])
            m.append(M)
            r.append(R)
            p.append(P)
            n.append(N)
    # Set up in dataset.
    ds = xr.Dataset({'m': ('ensemble', m),
                     'r': ('ensemble', r),
                     'p': ('ensemble', p),
                     'n_eff': ('ensemble', n)})
    print("Finished regional correlations.")
    OUT_DIR = ('/glade/p/work/rbrady/EBUS_BGC_Variability/' +
               'area_weighted_regional_regressions/' + EBU + '/' + VARY + '/' + 
               VARX + '/') 
    if not os.path.exists(OUT_DIR):
        os.makedirs(OUT_DIR)
    if SMOOTH != 0: # Save with smoothing in file name.
        out_file = (OUT_DIR + VARX + '.' + VARY + '.' + EBU + '.smoothed' +
                    str(SMOOTH) + '.area_weighted_regional_regression.lag' +
                    str(LAG) + '.nc')
    else:
        out_file = (OUT_DIR + VARX + '.' + VARY + '.' + EBU +
                    '.unsmoothed.area_weighted_regional_regression.lag' +
                    str(LAG) + '.nc')
    print("Saving to netCDF...")
    ds.to_netcdf(out_file)

if __name__ == '__main__':
    main()
