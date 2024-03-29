import sys
import numpy as np
import h5py

simulation_directory = str(sys.argv[1])
print("Creating Zeldovich Pancake ICs in directory " + simulation_directory)

""" initial condition parameters """
FilePath = simulation_directory + '/IC.hdf5'
FloatType = np.float32
IntType = np.int32

# Constants and input parameters
z_i = 100.0
z_c = 1.0
rho_0 = 2.7e-8
H_0 = 100.0
T_i = 100.0
lambda_ = 64000.0

# Derived constants
k = 2 * np.pi / lambda_

Boxsize = FloatType(lambda_)
CellsPerDimension = IntType(64)
NumberOfCells = CellsPerDimension * CellsPerDimension * CellsPerDimension

## spacing
dx = Boxsize / FloatType(CellsPerDimension)
## position of first and last cell
pos_first, pos_last = 0.5 * dx, Boxsize - 0.5 * dx

""" set up grid: cartesian 3d grid """
## spacing
dx = Boxsize / FloatType(CellsPerDimension)
## position of first and last cell
pos_first, pos_last = 0.5 * dx, Boxsize - 0.5 * dx

## set up evenly spaced grid, and all arrays
Grid1d = np.linspace(pos_first, pos_last, CellsPerDimension, dtype=FloatType)
xx, yy, zz = np.meshgrid(Grid1d, Grid1d, Grid1d)
Pos = np.zeros([NumberOfCells, 3], dtype=FloatType)
Vel_peculiar = np.zeros([NumberOfCells, 3], dtype=FloatType)
Vel_comoving = np.zeros([NumberOfCells, 3], dtype=FloatType)
T = np.zeros([NumberOfCells], dtype=FloatType)
SmoothingLength = np.zeros([NumberOfCells], dtype=FloatType)
ZeroData = np.zeros([NumberOfCells], dtype=FloatType) # Just an array of zeroes
Rho = np.zeros([NumberOfCells], dtype=FloatType)
Pos[:,0] = xx.reshape(NumberOfCells)
Pos[:,1] = yy.reshape(NumberOfCells)
Pos[:,2] = zz.reshape(NumberOfCells)

# Calculate Temperature and density
Rho[:] = rho_0 / (1 - (1 + z_c) / (1 + z_i) * np.cos(k * Pos[:,0]))
T[:] = T_i * (((1 + z_i) / (1 + z_i)) * (Rho[:] / rho_0))**(2 / 3) / 122

# Calculate peculiar and then comoving velocities
Vel_peculiar[:,0] = -H_0 * (1 + z_c) / np.sqrt(1 + z_i) * (np.sin(k * Pos[:,0]) / k) * 2000 / 1400
Vel_peculiar[:,1] = 0.0
Vel_peculiar[:,2] = 0.0
Vel_comoving = Vel_peculiar / (1 + z_i) # Convert peculiar to comoving velocity

# set up final grid in x
Pos[:,0] = Pos[:,0] - (1 + z_c) / (1 + z_i) * (np.sin(k * Pos[:,0]) / k)

# Calculate mass and internal energy
Mass = Rho * (Boxsize / CellsPerDimension)**3
SmoothingLength[:] = Boxsize / CellsPerDimension * (ZeroData[:] + 1)* 1.97 # Last term is the "nudging factor"
gamma = 5.0 / 3.0
Uthermal = T / (gamma - 1.0)

# Write hdf5 file
IC = h5py.File(simulation_directory + '/IC.hdf5', 'w')

# Create hdf5 groups
header = IC.create_group("Header")
part0 = IC.create_group("PartType0")

# Header entries
header.attrs.create("BoxSize", lambda_)
header.attrs.create("ComovingIntegrationOn", 1)
header.attrs.create("Effective_Kernel_NeighborNumber", 32)
header.attrs.create("Fixed_ForceSoftening_Keplerian_Kernel_Extent", np.array([280, 0, 0, 0, 0, 0], dtype=np.float64))
header.attrs.create("Flag_Cooling", 0)
header.attrs.create("Flag_DoublePrecision", 0)
header.attrs.create("Flag_Feedback", 0)
header.attrs.create("Flag_IC_Info", 3)
header.attrs.create("Flag_Metals", 0)
header.attrs.create("Flag_Sfr", 0)
header.attrs.create("Flag_StellarAge", 0)
header.attrs.create("GIZMO_version", 2022)
header.attrs.create("Gravitational_Constant_In_Code_Inits", 43007.1)
header.attrs.create("HubbleParam", 1)
header.attrs.create("Kernel_Function_ID", 3)
header.attrs.create("MassTable", np.array([0, 0, 0, 0, 0, 0], dtype=np.float64))
header.attrs.create("Maximum_Mass_For_Cell_Split", 85.8911)
header.attrs.create("Minimum_Mass_For_Cell_Merge", 8.6866)
header.attrs.create("NumFilesPerSnapshot", 1)
header.attrs.create("NumPart_ThisFile", np.array([NumberOfCells, 0, 0, 0, 0, 0], dtype=np.int32))
header.attrs.create("NumPart_Total", np.array([NumberOfCells, 0, 0, 0, 0, 0], dtype=np.uint32))
header.attrs.create("NumPart_Total_HighWord", np.array([0, 0, 0, 0, 0, 0], dtype=np.uint32))
header.attrs.create("Omega_Baryon", 1)
header.attrs.create("Omega_Lambda", 0)
header.attrs.create("Omega_Matter", 1)
header.attrs.create("Omega_Radiation", 0)
header.attrs.create("Redshift", 100)
header.attrs.create("Time", 0.00990099)
header.attrs.create("UnitLength_In_CGS", 3.08568e+21)
header.attrs.create("UnitMass_In_CGS", 1.989e+43)
header.attrs.create("UnitVelocity_In_CGS", 100000)

#NumPart = np.array([NumberOfCells, 0, 0, 0, 0, 0], dtype=IntType)
#header.attrs.create("NumPart_ThisFile", NumPart)
#header.attrs.create("NumPart_Total", NumPart)
#header.attrs.create("NumPart_Total_HighWord", np.zeros(6, dtype=IntType))
#header.attrs.create("MassTable", np.zeros(6, dtype=IntType))
#header.attrs.create("Time", 0.00990099)
#header.attrs.create("Redshift", z_i)
#header.attrs.create("BoxSize", Boxsize)
#header.attrs.create("NumFilesPerSnapshot", 1)
#header.attrs.create("Omega0", 0)
#header.attrs.create("OmegaB", 1)
#header.attrs.create("OmegaLambda", 0.0)
#header.attrs.create("HubbleParam", 1.0)
#header.attrs.create("Flag_Sfr", 0)
#header.attrs.create("Flag_Cooling", 0)
#header.attrs.create("Flag_StellarAge", 0)
#header.attrs.create("Flag_Metals", 0)
#header.attrs.create("Flag_Feedback", 0)

if Pos.dtype == np.float64:
    header.attrs.create("Flag_DoublePrecision", 1)
else:
    header.attrs.create("Flag_DoublePrecision", 0)

# Copy datasets
part0.create_dataset("ParticleIDs", data=np.arange(1, NumberOfCells + 1))
part0.create_dataset("Coordinates", data=Pos)
part0.create_dataset("Masses", data=Mass)
part0.create_dataset("Density", data=Rho)
part0.create_dataset("Velocities", data=Vel_comoving)
part0.create_dataset("InternalEnergy", data=Uthermal)
part0.create_dataset("SmoothingLength", data=SmoothingLength)
# Required zero datasets
part0.create_dataset("ParticleIDGenerationNumber", data=ZeroData)
part0.create_dataset("ParticleChildIDsNumber", data=ZeroData)

# Close file
IC.close()

