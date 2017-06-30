# Author  : Riley X. Brady
# Date    : 06/29/2017
# Purpose : This is similar to the climate-correlation script, but instead of
# correlationg FGCO2 anomalies to a climate index, I use this to correlate
# FGCO2 anomalies to some other time series (e.g. pCO2).
# INPUTS #
# INPUT 1 : A string of which EBU to work on
# INPUT 2 : A string of which variable to correlate FGCO2 anomalies to.

# UNIX-style globbing
import glob

# Allow for inputs
import sys

# Numerics
import numpy as np
import pandas as pd
import xarray as xr
from scipy import signal
from scipy import stats
import statsmodels.api as sm

# Visualization
import matplotlib
matplotlib.use('agg')
import matplotlib.pyplot as plt

import seaborn as sns
sns.set(color_codes=True)

def detrend_climate(x):
    return signal.detrend(x)

def smooth_series(x, len):
    return pd.rolling_mean(x, len)

def seaborn_jointplot(carbonData, climateData, ensNum):
    df = pd.DataFrame({'PDO':climateData,
                       'FG_CO2':carbonData})
    fig = plt.figure(figsize=(6,6))
    with sns.axes_style("white"):
        sns.jointplot(x='PDO', y='FG_CO2', data=df,
                      kind='reg', space=0, color='k')
        plt.savefig('smoothed_jointplot_PDO_' + ensNum + '.png', dpi=1000,
                    transparent=True)
        plt.close(fig)

def linear_regression(df, idx, x, y):
    # df is where you will store the output.
    slope, intercept, r_value, p_value, std_err = stats.linregress(x, y)
    df['Slope'][idx] = slope
    df['R Value'][idx] = r_value
    df['R Squared'][idx] = r_value**2
    df['P-Value'][idx] = p_value
    return df

def drop_ensemble_dim(ds, x):
    ds[x] = (('nlat', 'nlon'), ds[x][0])
    return ds

def chavez_bounds(x):
    if x == "CalCS":
        lat1 = 34
        lat2 = 44
    elif x == "CanCS":
        lat1 = 12
        lat2 = 22
    elif x == "BenCS":
        lat1 = -28
        lat2 = -18
    elif x == "HumCS":
        lat1 = -16
        lat2 = -6
    else:
        raise ValueError('\n' + 'Must Select from the following EBUS strings:'
                         + '\n' + 'CalCS' + '\n' + 'CanCS' + '\n' + 'BenCS' +
                         '\n' + 'HumCS')
    return lat1, lat2

    def filter_ds(ds, EBU, VAR, offshore=800):
        ds = drop_ensemble_dim(ds, 'DXT')
        ds = drop_ensemble_dim(ds, 'TAREA')
        ds = drop_ensemble_dim(ds, 'REGION_MASK')
        ds = drop_ensemble_dim(ds, 'TLAT')
        if EBU != "HumCS":
            ds = drop_ensemble_dim(ds, 'TLONG')
        del ds['DYT']
        del ds['ANGLET']
        # Convert DXT to kilometers
        ds['DXT'] = ds['DXT'] / 100 / 1000
        # Find bounds for given EBU (10 degree latitude)
        lat1, lat2 = chavez_bounds(EBU)
        # Filter out latitude to given bounds
        ds = ds.where(ds['TLAT'] >= lat1).where(ds['TLAT'] <= lat2)
        # Create a masked array for DXT since it doesn't follow the same NaN
        # structure as the co2/region_mask output.
        data = ds[VAR][0,0]
        data = np.ma.array(data, mask=np.isnan(data))
        # Apply mask to DXT and replace in dataset
        dxt_dat = ds['DXT']
        dxt_dat = np.ma.array(dxt_dat, mask=np.isnan(data))
        ds['DXT'] = (('nlat','nlon'), dxt_dat)
        # Remove rows that don't have a coastline in them (helps for
        # dist2coast)
        regmask = ds['REGION_MASK']
        counter = 0
        for row in regmask:
            conditional = 0 in row.values
            if conditional == False:
                ds['DXT'][counter, :] = np.nan
            counter += 1
        # Now create a cumulative sum of DXTs. Have to use a masked array so
        # there isn't any issue with summing across NaNs.
        x = ds['DXT'].values
        x_masked = np.ma.array(x, mask=np.isnan(x))
        dxt_cum = np.cumsum(x_masked[:, ::-1], axis=1)[:, ::-1]
        ds['DXT_Cum'] = (('nlat','nlon'), dxt_cum)
        # Filter to offshore value
        ds = ds.where(ds['DXT_Cum'] <= offshore)
        return ds

def main():
    EBU = sys.argv[1]
    VAR = sys.argv[2]
    print("Operating on : {}".format(EBU))

    # + + + FGCO2
    fileDir = '/glade/p/work/rbrady/EBUS_BGC_Variability/FG_CO2/' + EBU = '/'
    ds = xr.open_mfdataset(fileDir + '*.nc', concat_dim='ensemble')
    ds = filter_ds(ds, EBU, 'FG_CO2')
    fgco2_residuals = ds['FG_CO2'] - ds['FG_CO2'].mean(dim='ensemble')
    fgco2_residuals = ((fgco2_residuals * fgco2_residuals['TAREA'])
                       .sum(dim='nlat').sum(dim='nlon'))/fgco2_residuals['TAREA'].sum()

    # + + + OTHER VARIABLE
    fileDir = '/glade/p/work/rbrady/EBUS_BGC_Variability/' + VAR + '/' + EBU + '/'
    ds = xr.open_mfdataset(fileDir + '*.nc', concat_dim='ensemble')
    ds = filter_ds(ds, EBU, VAR)
    var_residuals = ds[VAR] - ds[VAR].mean(dim='ensemble')
    var_residuals = ((var_residuals * var_residuals['TAREA'])
                     .sum(dim='nlat').sum(dim='nlon'))/var_residuals['TAREA'].sum()

    # + - + - + - STATISTICAL ANALYSIS + - + - + -
    # Create a DataFrame to store correlation analysis on different climate
    # indices.
    index = np.arange(0, 34, 1)
    columns = ['Slope', 'R Value', 'R Squared', 'P-Value']
    df_corr = pd.DataFrame(index=index, columns=columns)
    for idx in np.arange(0, 34, 1):
        # Apply annual filter to the FG_CO2 data and only match up with same
        # length time series from CVDP package.
        ts1 = ds_residuals[idx].values
        # Apply 12-month rolling mean to the FG_CO2 data.
        ts1 = smooth_series(ts1, 12)
        # Cut off the NaNs on the front end.
        ts1 = ts1[11::]
        # Only compare the same length time series.
        ts2 = ds_cvdp['nino34'][idx, 11::].values
        ts3 = ds_cvdp['pdo'][idx, 11::].values
        ts4 = ds_cvdp['amo'][idx, 11::].values
        ts5 = ds_cvdp['nao'][idx, 11::].values
        ts6 = ds_cvdp['sam'][idx, 11::].values
        print "Working on simulation " + str(idx+1) + " of 34..."
        # +++ Create Seaborn stats plots
        # ensNum = str(idx)
        # seaborn_jointplot(ts1, ts3, ensNum)  

        # +++ Run Linear regressions.
        df_enso = linear_regression(df_enso, idx, ts2, ts1)
        df_pdo = linear_regression(df_pdo, idx, ts3, ts1)
        df_amo = linear_regression(df_amo, idx, ts4, ts1)
        df_nao = linear_regression(df_nao, idx, ts5, ts1)
        df_sam = linear_regression(df_sam, idx, ts6, ts1)
    df_enso.to_csv('smoothed_fgco2_vs_enso_' + EBU)
    df_pdo.to_csv('smoothed_fgco2_vs_pdo_' + EBU)
    df_amo.to_csv('smoothed_fgco2_vs_amo_' + EBU)
    df_nao.to_csv('smoothed_fgco2_vs_nao_' + EBU)
    df_sam.to_csv('smoothed_fgco2_vs_sam_' + EBU)

if __name__ == '__main__':
    main()
