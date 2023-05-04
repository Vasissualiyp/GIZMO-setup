#include <iostream>
#include <vector>
#include <string>
#include <cmath>
#include <random>
#include <algorithm>
#include <Eigen/Dense>
#include <highfive/H5Easy.hpp>
#include <omp.h> // Added OpenMP include

const double pi = 3.14159265358979323846;

int main(int argc, char *argv[]) {
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " <simulation_directory>" << std::endl;
        return 1;
    }

    std::string simulation_directory = argv[1];
    std::cout << "Creating Zeldovich Pancake ICs in directory " << simulation_directory << std::endl;

    // initial condition parameters
    std::string FilePath = simulation_directory + "/IC.hdf5";
    using FloatType = float;
    using IntType = int32_t;

    // Constants and input parameters
    double z_i = 100.0;
    double z_c = 1.0;
    double rho_0 = 2.7e-8 / 0.972989;
    double H_0 = 100.0;
    double T_i = 100.0;
    double lambda_ = 64000.0;
    double OmegaMatter = 1.0;

    // Derived constants
    size_t idx = 0;
    double k = 2 * pi / lambda_;

    // Simulation Parameters
    FloatType Boxsize = static_cast<FloatType>(lambda_);
    IntType CellsPerDimension = 1024;
    IntType NumberOfCells = CellsPerDimension * CellsPerDimension * CellsPerDimension;

    // ... the rest of the code ...

    // spacing
    FloatType dx = Boxsize / static_cast<FloatType>(CellsPerDimension);
    // position of first and last cell
    FloatType pos_first = 0.5 * dx;
    FloatType pos_last = Boxsize - 0.5 * dx;

    // set up evenly spaced grid and all arrays
    Eigen::VectorXf Grid1d = Eigen::VectorXf::LinSpaced(CellsPerDimension, pos_first, pos_last);
    Eigen::MatrixXf xx(CellsPerDimension, CellsPerDimension);
    Eigen::MatrixXf yy(CellsPerDimension, CellsPerDimension);
    Eigen::MatrixXf zz(CellsPerDimension, CellsPerDimension);

    // Generate the meshgrid
    for (int i = 0; i < CellsPerDimension; ++i) {
        for (int j = 0; j < CellsPerDimension; ++j) {
            xx(i, j) = Grid1d(i);
            yy(i, j) = Grid1d(j);
        }
    }

    zz = Eigen::MatrixXf::Constant(CellsPerDimension, CellsPerDimension, pos_first);

    // Generate the displacement grid
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_real_distribution<> dis(-0.1 * dx, 0.1 * dx);

    Eigen::Array<float, Eigen::Dynamic, Eigen::Dynamic, Eigen::RowMajor> displacements(CellsPerDimension * CellsPerDimension * CellsPerDimension, 3);
    for (size_t i = 0; i < CellsPerDimension; ++i) {
        for (size_t j = 0; j < CellsPerDimension; ++j) {
            for (size_t k = 0; k < CellsPerDimension; ++k) {
                for (size_t l = 0; l < 3; ++l) {
                    displacements(idx, l) = dis(gen);
                }
		++idx;
            }
        }
    }

    Eigen::MatrixXf Pos(NumberOfCells, 3);
    Eigen::MatrixXf Vel_peculiar(NumberOfCells, 3);
    Eigen::MatrixXf Vel_comoving(NumberOfCells, 3);
    Eigen::VectorXf T(NumberOfCells);
    Eigen::VectorXf SmoothingLength(NumberOfCells);
    Eigen::VectorXf ZeroData = Eigen::VectorXf::Zero(NumberOfCells);
    Eigen::VectorXf Rho(NumberOfCells);


    // Generate glass-like initial conditions
    #pragma omp parallel for collapse(3) // Added OpenMP pragma
    for (int i = 0; i < CellsPerDimension; ++i) {
        for (int j = 0; j < CellsPerDimension; ++j) {
            for (int k = 0; k < CellsPerDimension; ++k) {
                int idx = i * CellsPerDimension * CellsPerDimension + j * CellsPerDimension + k;
                Pos(idx, 0) = xx(i, j) + displacements(idx, 0);
                Pos(idx, 1) = yy(i, j) + displacements(idx, 1);
                Pos(idx, 2) = zz(i, j) + displacements(idx, 2);
            }
        }
    }

    // Calculate Temperature and density
    #pragma omp parallel for // Added OpenMP pragma
    for (int i = 0; i < NumberOfCells; ++i) {
        Rho(i) = rho_0 / (1 - (1 + z_c) / (1 + z_i) * std::cos(k * Pos(i, 0)));
        T(i) = T_i * (((1 + z_i) / (1 + z_i)) * (Rho(i) / rho_0)) * (2.0 / 3.0) / 122;
    }

    // set up final grid in x
    for (int i = 0; i < NumberOfCells; ++i) {
        Pos(i, 0) = Pos(i, 0) - (1 + z_c) / (1 + z_i) * (std::sin(k * Pos(i, 0)) / k);
    }

    // Calculate peculiar and then comoving velocities
    #pragma omp parallel for // Added OpenMP pragma
    for (int i = 0; i < NumberOfCells; ++i) {
        Vel_peculiar(i, 0) = -H_0 * (1 + z_c) / std::sqrt(1 + z_i) * (std::sin(k * Pos(i, 0)) / k) * 2000 / 1400;
    }

    #pragma omp parallel for // Added OpenMP pragma
    for (int i = 0; i < NumberOfCells; ++i) {
        Vel_comoving(i, 0) = Vel_peculiar(i, 0) / std::sqrt(1 + z_i);
        Vel_comoving(i, 1) = 0.0;
        Vel_comoving(i, 2) = 0.0;
    }

    // Set smoothing length
    SmoothingLength = Eigen::VectorXf::Constant(NumberOfCells, dx);

    // Write data to the HDF5 file
    H5Easy::File file(FilePath, H5Easy::File::Overwrite);
    H5Easy::dump(file, "/PartType0/Coordinates", Pos);
    H5Easy::dump(file, "/PartType0/Velocities", Vel_comoving);
    H5Easy::dump(file, "/PartType0/InternalEnergy", T);
    H5Easy::dump(file, "/PartType0/Density", Rho);
    H5Easy::dump(file, "/PartType0/SmoothingLength", SmoothingLength);
    H5Easy::dump(file, "/PartType0/Masses", ZeroData);

    std::cout << "Zeldovich Pancake ICs created and saved in " << FilePath << std::endl;

    return 0;
}

