%SETUP_5AXONS_MYELIN_RELAX Define setup structure for SpinDoctor.
%
%   The setup structure may contain the following substructures:
%
%       geometry:
%           Geometry parameters. Can contain parameters for specific cell types
%           (spheres, cylinders). Determines whether to include inner and ECS
%           compartments), and finite element mesh parameters.
%   
%       pde:
%           Domain parameters. Contains PDE parameters (material properties)
%       	defined for the domains "IN", "OUT", "ECS" and their boundaries
%   
%       gradient:
%           Gradient sequence parameters. It determines the three properties
%           `directions`, `amplitudes` and `sequences`. Available sequences are:
%               PGSE(delta, Delta)
%               DoublePGSE(delta, Delta)
%               CosOGSE(delta, Delta, nperiod)
%               SinOGSE(delta, Delta, nperiod)
%               CustomSequence(delta, Delta, @timeprofile)
%
%   The precense of any of the following substructures triggers the corresponding experiment:
%
%       btpde:      Solve Bloch-Torrey PDE with P1-FEM
%
%       hadc:       Solve the equation for the homogenized apparent
%                   diffusion coefficient using P1-FEM
%
%       mf:         Compute the matrix formalism signal
%
%       analytical: Compute analytical signal one analyticaled sphere or
%                   cylinder using truncated radial matrix formalism



%% Meshfile
setup.name = "mesh_files/cylinders/5axons_myelin_relax";

%% Geometry configuration
setup.geometry.cell_shape = "cylinder";               % Cell shape: "sphere", "cylinder" or "neuron"
setup.geometry.ncell = 5;                             % Number of cells
setup.geometry.rmin = 3;                              % Minimum radius of cells
setup.geometry.rmax = 4;                              % Minimum radius of cells
setup.geometry.dmin = 0.1;                            % Minimum distance between cells (times mean(rmin,rmax))
setup.geometry.dmax = 0.2;                            % Maximum distance between cells (times mean(rmin,rmax))
setup.geometry.height = 10;                           % Cylinder height (ignored if not cylinder)
setup.geometry.deformation = [0; 0];                  % Domain deformation; [a_bend, a_twist]
setup.geometry.include_in = true;                     % Ratio Rin/R, within range [0,0.99]
setup.geometry.in_ratio = 0.5;                        % Ratio Rin/R, within range [0,0.99]
setup.geometry.ecs_shape = "tight_wrap";              % Shape of ECS: "no_ecs", "box", "convex_hull", or "tight_wrap".
setup.geometry.ecs_ratio = 0.3;                       % ECS gap; percentage in side length
% setup.geometry.refinement  = 0.5;                   % Tetgen refinement parameter (comment for automatic) (comment for automatic)

%% PDE parameters
setup.pde.diffusivity_in = 0.002;               % Diffusion coefficient IN
setup.pde.diffusivity_out = 0.002;              % Diffusion coefficient OUT
setup.pde.diffusivity_ecs = 0.002;              % Diffusion coefficient ECS
setup.pde.relaxation_in = Inf;                  % T2-relaxation IN. No relaxation: Inf
setup.pde.relaxation_out = 20e+03;              % T2-relaxation OUT. No relaxation: Inf
setup.pde.relaxation_ecs = 80e+03;              % T2-relaxtion ECS. No relaxation: Inf
setup.pde.initial_density_in = 1.0;             % Initial density in IN
setup.pde.initial_density_out = 1.0;            % Initial density in OUT
setup.pde.initial_density_ecs = 1.0;            % Initial density in ECS
setup.pde.permeability_in_out = 1e-03;          % Permeability IN-OUT interface
setup.pde.permeability_out_ecs = 1e-03;         % Permeability OUT-ECS interface
setup.pde.permeability_in = 0;                  % Permeability IN boundary
setup.pde.permeability_out = 0;                 % Permeability OUT boundary
setup.pde.permeability_ecs = 0;                 % Permeability ECS boundary

%% Gradient sequences
setup.gradient.ndirection = 1;                          % Number of gradient directions to simulate
setup.gradient.flat_dirs = false;                       % Choose between 3d or 2d distributed gradient directions
setup.gradient.remove_opposite = false;                 % Choose whether to not compute opposite directions
setup.gradient.direction = [1.0; 1.0; 1.0];             % Gradient direction; [g1; g2; g3] (ignored if ndirection>1)
setup.gradient.values = [2 10] * 1e-05;                 % g-, q-, or b-values [1 x namplitude]
setup.gradient.values_type = "q";                       % Type of values; "g", "q" or "b"
setup.gradient.sequences{1} = PGSE(5000, 5000);         % Gradient sequences {1 x nsequence}
setup.gradient.sequences{2} = PGSE(5000, 10000);        % Gradient sequences {1 x nsequence}
setup.gradient.sequences{3} = PGSE(10000, 20000);       % Gradient sequences {1 x nsequence}

%% BTPDE experiment parameters (comment block to skip experiment)
setup.btpde.ode_solver = @ode15s;          % ODE solver for BTPDE
setup.btpde.reltol = 1e-4;                 % Relative tolerance for ODE solver
setup.btpde.abstol = 1e-6;                 % Absolute tolerance for ODE solver

%% HADC experiment parameters (comment block to skip experiment)
setup.hadc.ode_solver = @ode15s;           % ODE solver for HADC
setup.hadc.reltol = 1e-4;                  % Relative tolerance for ODE solver
setup.hadc.abstol = 1e-4;                  % Absolute tolerance for ODE solver

%% MF experiment parameters (comment block to skip experiment)
setup.mf.length_scale = 3;                 % Minimum length scale of eigenfunctions
setup.mf.neig_max = Inf;                   % Requested number of eigenvalues
setup.mf.ninterval = 10;                   % Number of intervals to discretize time profile in MF (if not PGSE)

%% analytical experiment parameters (comment block to skip experiment)
% setup.analytical.length_scale = 1;       % Minimum length scale of eigenfunctions
% setup.analytical.eigstep = 1e-8;         % Minimum distance between eigenvalues

%% Custom time profile for magnetic field gradient pulse
% The function should be defined on the interval [0, Delta+delta].
% Here we manually define the PGSE sequence, as an example.
function f = timeprofile(t, delta, Delta)
f = (t < delta) - (Delta <= t);
end