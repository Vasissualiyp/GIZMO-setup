import numpy as np
from scipy.stats import norm
from scipy.special import erf

def write_snapshot_times_to_file(snapshot_times, filename):
    """
    Write snapshot times to a file.

    Parameters:
    snapshot_times (numpy.ndarray): Array of snapshot times
    filename (str): Name of the file to write to
    """
    with open(filename, 'w') as f:
        for t in snapshot_times:
            f.write(str(t) + "\n")

def generate_geometric_snapshot_times(t1, t2, n):
    """
    Generate snapshot times using a geometric sequence.
    
    Parameters:
    t1 (float): Start time
    t2 (float): End time
    n (int): Number of snapshots
    
    Returns:
    numpy.ndarray: Array of snapshot times
    """
    return np.logspace(np.log10(t1), np.log10(t2), n)

def erf_weighting(focusz, minz, maxz, std_dev, n):
    max_shifted = maxz-minz
    focus_shifted = focusz-minz
    focus_fraction = focus_shifted / max_shifted
    x = np.linspace(0,1, n)
    erf_distribution = (erf((x - focus_fraction)/std_dev) + 1)/2
    print(erf_distribution)
    erf_distribution = erf_distribution * max_shifted + minz
    return erf_distribution

def generate_gaussian_redshift_snapshot_times(z1, z2, z_center, std_dev, n):
    """
    Generate snapshot times based on a Gaussian redshift-centered distribution.
    
    Parameters:
    z1 (float): Initial redshift
    z2 (float): Final redshift
    z_center (float): Redshift at which the Gaussian is centered
    std_dev (float): Standard deviation of the Gaussian
    n (int): Number of snapshots
    
    Returns:
    numpy.ndarray: Array of snapshot times in terms of scale factor (a = 1/(1+z))
    """
    # Generate an array of redshifts linearly spaced between z1 and z2
    #z_values = np.linspace(z1, z2, 10 * n)  # Oversampling for better Gaussian fit
    #
    ## Generate Gaussian weights for each redshift
    #gaussian_weights = norm.pdf(z_values, loc=z_center, scale=std_dev)
    #
    ## Normalize the Gaussian weights
    #gaussian_weights /= np.sum(gaussian_weights)
    #
    ## Sample from the weighted redshifts
    #sampled_z = np.random.choice(z_values, size=n, p=gaussian_weights)
    
    # Sort the sampled redshifts
    sampled_z = erf_weighting(z_center, z2, z1, std_dev, n )
    print(f'Sampled redshifts: {sampled_z}')
    
    # Convert redshift to scale factor
    a_values = 1 / (1 + sampled_z)
    
    return a_values
def generate_high_precision_redshift_snapshot_times(z1, z2, z_hr_start, z_hr_end, n, n_hr):
    """
    Generate snapshot times with high precision in a specified redshift region.
    
    Parameters:
    z1 (float): Initial redshift
    z2 (float): Final redshift
    z_hr_start (float): Start redshift of the high-precision region
    z_hr_end (float): End redshift of the high-precision region
    n (int): Number of snapshots in the normal region
    n_hr (int): Number of snapshots in the high-precision region
    
    Returns:
    numpy.ndarray: Array of snapshot times in terms of scale factor (a = 1/(1+z))
    """
    # Generate an array of redshifts linearly spaced between z1 and z2
    z_values = np.linspace(z1, z2, n)
    
    # Remove redshifts that fall within the high-precision range
    z_values = z_values[(z_values < z_hr_start) | (z_values > z_hr_end)]
    
    # Generate an array of redshifts in the high-precision region
    z_values_hr = np.linspace(z_hr_start, z_hr_end, n_hr)
    
    # Combine the normal and high-precision redshift arrays
    combined_z_values = np.concatenate([z_values, z_values_hr])
    
    # Sort the combined redshifts
    combined_z_values = np.sort(combined_z_values)
    
    # Convert redshift to scale factor
    a_values = 1 / (1 + combined_z_values)
    
    return a_values

# Test the new function
z1 = 100
z2 = 0
z_hr_start = 20
z_hr_end = 10
n = 20
n_hr = 10
filename_high_precision = "high_precision_redshift_snapshot_times.txt"

# Generate high-precision redshift snapshot times
high_precision_times = generate_high_precision_redshift_snapshot_times(z1, z2, z_hr_start, z_hr_end, n, n_hr)

# Write to file
write_snapshot_times_to_file(high_precision_times, filename_high_precision)

print(f"High-precision redshift snapshot times have been written to {filename_high_precision}.")
print("Generated scale factors:")
print(high_precision_times)


## Testing the functions
## Geometric snapshot times
##print("Geometric snapshot times:")
##print(generate_geometric_snapshot_times(0.02, 0.03, 10))
#
## Gaussian redshift-centered snapshot times
##print("\nGaussian redshift-centered snapshot times:")
##print(generate_gaussian_redshift_snapshot_times(200, 50, 100, 10, 12))
#
#def write_snapshot_times_to_file(snapshot_times, filename):
#    """
#    Write snapshot times to a file.
#
#    Parameters:
#    snapshot_times (numpy.ndarray): Array of snapshot times
#    filename (str): Name of the file to write to
#    """
#    with open(filename, 'w') as f:
#        for t in snapshot_times:
#            f.write(str(t) + "\n")
#
## Example usage
## Define parameters for geometric snapshot generation
#t1 = 0.02
#t2 = 0.03
#n = 10
#filename_geom = "geometric_snapshot_times.txt"
#
## Generate geometric snapshot times
#geom_times = generate_geometric_snapshot_times(t1, t2, n)
#
## Write to file
#write_snapshot_times_to_file(geom_times, filename_geom)
#
## Define parameters for Gaussian redshift-centered snapshot generation
#z1 = 199
#z2 = 0
#z_center = 100
#std_dev = 0.1
#n = 30
#filename_gauss = "gaussian_redshift_snapshot_times.txt"
#
## Generate Gaussian redshift-centered snapshot times
#gauss_times = generate_gaussian_redshift_snapshot_times(z1, z2, z_center, std_dev, n)
#
## Write to file
#write_snapshot_times_to_file(gauss_times, filename_gauss)
#
##print(f"Geometric snapshot times have been written to {filename_geom}.")
##print(f"Gaussian redshift-centered snapshot times have been written to {filename_gauss}.")
