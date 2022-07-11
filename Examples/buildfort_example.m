function buildfort(runid)

addpath(genpath('OceanMesh2D'))
%%
% grid_version = 'v3f';
% runid = '001a';
% model_dir = fullfile('/home/ibbisin0/users/honegger/modeling/adcirc/newport',grid_version,'control');

fns.fort14 = 'fort.14';
%% Read grid
m = msh(fns.fort14);
nnodes = size(m.p,1);

%% Define params
dt              = 1;
ts              = '01-Oct-2010 00:00';
te              = '02-Oct-2010 00:00';
rundur          = days(datetime(te)-datetime(ts));
constituents    = 'major8';
tidal_database  = 'h_tpxo9.v5a.nc';


DTSWAN = 600; % SECONDS
SWAN_OUTPUT_FILENAME = "'swanout.mat'"; % We still can't get netcdf output working for swan
GEOID_TO_MSL = 1.124;

%% Build initial fort15 structure
m = Make_f15(m,ts,te,dt,...
    'const',constituents,...
    'tidal_database',tidal_database,...
    'sta_database',{'CO-OPS',1});

%% Populate additional fields
% m.f15.rundes                = "USACE Newport v3e"; % Set during Make_f15.m
m.f15.runid                 = strcat('run',runid);
m.f15.nfover                = 1;
m.f15.nabout                = 0;
m.f15.nscreen               = 600;
m.f15.ihot                  = 0;
m.f15.ics                   = 2;
m.f15.im                    = 0;
m.f15.nolibf                = 1;
m.f15.nolifa                = 2;
m.f15.nolica                = 0;
m.f15.nolicat               = 0;
m                           = Calc_tau0(m);
m                           = Calc_f13(m,'Ge','assign',GEOID_TO_MSL*ones(nnodes,1));
m                           = Calc_f13(m,'Ev','assign',3.5*ones(nnodes,1));
m                           = Calc_f13(m,'Mn','assign',0.02*ones(nnodes,1));
m.f15.ncor                  = 1;
% m.f15.ntip                  = 1; % Set during Make_f15.m
m.f15.nws                   = 306; % To be changed with actual met forcing
m.f15.windgrid              = [2 2 50 -130 20 20]; 
m.f15.wtiminc               = 10*86400;
m.f15.rstiminc 		        = DTSWAN;
m.f15.nramp                 = 1;
m.f15.gravity               = 9.81;
% m.f15.tau0                  = -3; % Set during Calc_tau0.m
% m.f15.dtdp                  = 1; % Set during Make_f15.m
% m.f15.statim                = 0; % Set during Make_f15.m
% m.f15.reftim                = 0; % Set during Make_f15.m
% m.f15.rndy                  = 20; % Set during Make_f15.m
m.f15.dramp                 = 1;
m.f15.a00b00c00             = [0.35 0.30 0.35]; % This is the default
m.f15.h0                    = [0.02 0 0 0.02]; % Wet/dry params
% m.f15.slam                  = [-124.07 44.564]; % Set during Make_f15.m
m.f15.taucf                 = 0.0025; % Or this can be set during Calc_f13.m
m.f15.elsm                  = 50; % Or this can be set during Calc_f13.m
m.f15.cori                  = 0;

% m.f15.ntif                  = 8; % Set during Make_f15.m
% m.f15.tipotag               = struct([]); % Tidal potential parameters % Set during make_f15.m

%% Boundary forcing: Tides
%%% Tidal forcing
% m.f15.nbfr                  = 8; % Set during Make_f15.m
% m.f15.bountag               = struct([]); % Tidal forcing timing params % Set during make_f15.m;
% m.f15.opealpha              = struct([]); % Tidal forcing amplitude/phase % Set during make_f15.m;

%% Boundary forcing: River flux
% Provide time series of total river discharge
Qalsea                      = 100; % cms
Qyaquina                    = Qalsea/2; % cms, say it's half
% Generate hourly time vector from beginning to (past) end of run
Qdt                         = 3600; % seconds
Qts                         = ts;
Qte                         = te;
Qtime                       = datetime(Qts):seconds(Qdt):datetime(Qte);
if Qtime(end)<datetime(Qte) % Make sure forcing extends beyond runtime
    Qtime = [Qtime Qtime(end)+seconds(Qdt)];
end
Q{1} = Qalsea*ones(size(Qtime));
Q{2} = Qyaquina*ones(size(Qtime));
% Write discharge time series
fid = fopen('buildfort_river.dat','wt');
for i = 1:length(Qtime)
    fprintf(fid,'%d,%d,%d,%d,%d,%d,%.2f,%.2f\n',year(Qtime(i)),month(Qtime(i)),day(Qtime(i)),hour(Qtime(i)),minute(Qtime(i)),second(Qtime(i)),Q{1}(i),Q{2}(i));
end
fclose(fid);

m                           = Make_f20_volume_flow(m,'buildfort_river.dat',Qts,Qte,Qdt);

%%
m.f15.anginn                = 90;

%% Output
m.f15.oute                  = [3 0 rundur 60];
m.f15.elvstaloc             = [-124.044419 44.625704;-124.071990 44.613911]; % Can add to this, but initialized in Make_f15.m; <== Here I tweak South Beach to be in water and I add adcp between jetties
m.f15.elvstaname            = {'South Beach ID:9435380','2010 ADCP'};
m.f15.nstae                 = size(m.f15.elvstaloc,1);

m.f15.outv                  = [3 0 rundur 60];
m.f15.velstaloc             = [-124.071990 44.613911]; % Can add to this, but initialized in Make_f15.m; <== Here I add adcp between jetties
m.f15.velstaname            = {'2010 ADCP'};
m.f15.nstav                 = size(m.f15.velstaloc,1);

m.f15.outm                  = [0 0 rundur 1800];
m.f15.metstaloc             = [];
m.f15.nstam                 = size(m.f15.metstaloc,1);

m.f15.outge                 = [3 0 rundur 3600];
m.f15.outgv                 = [3 0 rundur 3600];
m.f15.outgm                 = [3 0 rundur 3600];

% m.f15.nfreq                 = 8; % Set during Make_f15.m
m.f15.outhar                = [3 0 rundur 0];
% m.f15.harfreq               = [];% Set during Make_f15.m <== Structure
m.f15.outhar_flag           = [0 0 0 0];

m.f15.nhstar                = [0 0];
m.f15.ititer                = [1 0 1e-10 25];

% m.f15.extraline(1).msg      = m.f15.rundes; % Set by Make_f15.m
m.f15.extraline(2).msg      = 'Oregon State University';
m.f15.extraline(3).msg      = 'none';
m.f15.extraline(4).msg      = 'History: None';
m.f15.extraline(5).msg      = 'none';
m.f15.extraline(6).msg      = 'Comments: None';
m.f15.extraline(7).msg      = 'Host: CIL';
m.f15.extraline(8).msg      = 'Metric, NAVD88 to MSL';
m.f15.extraline(9).msg      = 'david.honegger@oregonstate.edu';
% m.f15.extraline(10).msg      = '2010-10-10 00:00:00 UTC'; % Set by Make_f15.m
m.f15.nextraline            = length(m.f15.extraline);

%% Populate SWAN input file information (fort.26 and swaninit)
%%%% => Many of these lines could be put in a default-fort.26 script (for
%%%% the future)
NDIRS = 36;
FREQMIN = 0.031384;
FREQMAX = 0.547632;
NFREQ = 30;

%Initialize
% m.f26 = struct('proj','set','mode','coord','cgrid','inpgrid','params','numerics','output','compute');
m.f26.proj.name                                 = m.title(1:16);
m.f26.proj.nr                                   = runid;
m.f26.proj.titles                               = {m.title,'David Honegger','Oregon State University'};
m.f26.set.Attr(1).AttrName                      = 'LEVEL';
m.f26.set.Attr(1).Val                           = sprintf('%.2f',GEOID_TO_MSL);
m.f26.set.Attr(2).AttrName                      = 'DEPMIN';
m.f26.set.Attr(2).Val                           = sprintf('%.2f',m.f15.h0(1)); % wet/dry minimum value -- read from fort.15
% m.f26.set.Attr(3).AttrName                      = 'INRHOG';
% m.f26.set.Attr(3).Val                           = sprintf('%d',1); % This tells output to be true energy and not variance
m.f26.mode.Attr(1).AttrName                     = 'NONSTATIONARY';
m.f26.coord.Attr(1).AttrName                    = 'SPHERICAL';
m.f26.coord.Attr(1).Val                         = 'CCM'; % This is the projection that ADCIRC uses
m.f26.cgrid.mdc                                 = sprintf('%d',NDIRS); % number of directional bins (36 => 10 degrees)
m.f26.cgrid.flow                                = sprintf('%.6f',FREQMIN);  % lowest frequency bin
m.f26.cgrid.msc                                 = sprintf('%d',NFREQ); % number of frequency bins minus one (30 => 31 frequencies). See user manual to calculate upper frequency

% Coupling inputs
m.f26.inpgrid.startdatetime                     = sprintf('%s',datestr(datenum(ts),'yyyymmdd.HHMMSS'));
m.f26.inpgrid.dtswan                            = sprintf('%d',DTSWAN);
m.f26.inpgrid.enddatetime                       = sprintf('%s',datestr(datenum(te),'yyyymmdd.HHMMSS'));
m.f26.inpgrid.Attr(1).AttrName                  = 'WLEV';
m.f26.inpgrid.Attr(1).ExcVal                    = sprintf('%.2f',m.f15.h0(1)); % wet/dry minimum value -- read from fort.15
m.f26.inpgrid.Attr(1).ReadInpName               = 'ADCWL';
m.f26.inpgrid.Attr(2).AttrName                  = 'CUR';
m.f26.inpgrid.Attr(2).ExcVal                    = sprintf('%.1f',0);
m.f26.inpgrid.Attr(2).ReadInpName               = 'ADCCUR';
m.f26.inpgrid.Attr(3).AttrName  		= 'WIND';
m.f26.inpgrid.Attr(3).ExcVal    		= sprintf('%.1f',0);
m.f26.inpgrid.Attr(3).ReadInpName 		= 'ADCWIND';
% % % % m.f26.inpgrid.Attr(4).AttrName  = 'FRIC';
% % % % m.f26.inpgrid.Attr(4).ExcVal    = sprintf('%.1f',0);
% % % % m.f26.inpgrid.Attr(4).ReadInpName = 'ADCFRIC';

% Boundary and initial conditions
%%% JONSWAP SHAPE - DEFAULT
m.f26.boundinit.Attr(1).AttrName                = 'BOUND SHAPESEPEC'; % Keep defaults
m.f26.boundinit.Attr(1).Attr(1).AttrName        = 'JONSWAP';
m.f26.boundinit.Attr(1).Attr(1).Val             = {'GAMMA=3.3'};
m.f26.boundinit.Attr(1).Attr(2).AttrName        = 'PEAK';
m.f26.boundinit.Attr(1).Attr(2).Val             = {};
m.f26.boundinit.Attr(1).Attr(3).AttrName        = 'DSPR';
m.f26.boundinit.Attr(1).Attr(3).Val             = {'POWER'};
%%% CONSTANT JONSWAP
m.f26.boundinit.Attr(2).AttrName                = 'BOUNDSPEC';
m.f26.boundinit.Attr(2).Attr(1).AttrName        = 'SIDE';
m.f26.boundinit.Attr(2).Attr(1).Val             = {'1','CCW'};
m.f26.boundinit.Attr(2).Attr(2).AttrName        = 'CONSTANT';
m.f26.boundinit.Attr(2).Attr(2).Val             = {'PAR','HS=1','PER=12','DIR=-30','DD=2'};
%%% INITIAL FIELD IS ZERO
m.f26.boundinit.Attr(3).AttrName                = 'INIT';
m.f26.boundinit.Attr(3).Val                     = {'ZERO'};

% Parameterizations
iatt = 0;
%%% GEN3 physics
iatt = iatt + 1;
m.f26.params.Attr(iatt).AttrName                = 'GEN3';
m.f26.params.Attr(iatt).Attr(1).AttrName        = 'ST6';
m.f26.params.Attr(iatt).Attr(1).Val             = {'2.8E-6','3.5E-5','4.0','4.0'}; % correspond to U10PROXY=32
% m.f26.params.Attr(1).Attr(1).Val = {'4.7E-7','6.6E-6','4.0','4.0'}; % correspond to U10PROXY=28
m.f26.params.Attr(iatt).Attr(2).AttrName        = 'UP';
m.f26.params.Attr(iatt).Attr(2).Val             = {};
m.f26.params.Attr(iatt).Attr(3).AttrName        = 'HWANG';
m.f26.params.Attr(iatt).Attr(3).Val             = {};
m.f26.params.Attr(iatt).Attr(4).AttrName        = 'VECTAU';
m.f26.params.Attr(iatt).Attr(4).Val             = {};
m.f26.params.Attr(iatt).Attr(5).AttrName        = 'U10PROXY';
m.f26.params.Attr(iatt).Attr(5).Val             = {'32'}; % keep default 32
m.f26.params.Attr(iatt).Attr(6).AttrName        = 'DEBIAS';
m.f26.params.Attr(iatt).Attr(6).Val             = {'1'}; % Only change from one if model/data wind stress comparisons can be made
m.f26.params.Attr(iatt).Attr(7).AttrName        = 'AGROW';
m.f26.params.Attr(iatt).Attr(7).Val             = {'0.0015'}; % keep default
%%% SWELL DISSIPATION
iatt = iatt + 1;
m.f26.params.Attr(iatt).AttrName                = 'SSWELL';
m.f26.params.Attr(iatt).Attr(1).AttrName        = 'ARDHUIN'; % keep default
m.f26.params.Attr(iatt).Attr(1).Val             = {'1.2'}; % keep default
%%% WHITECAPPING
iatt = iatt + 1;
m.f26.params.Attr(iatt).AttrName                = 'WCAP';
m.f26.params.Attr(iatt).Attr(1).AttrName        = 'KOMEN';
m.f26.params.Attr(iatt).Attr(1).Val             = {'2.36E-5','3.02E-3','2.0','1.0','1.0'}; % keep defaults
%%% BREAKING
iatt = iatt + 1;
m.f26.params.Attr(iatt).AttrName                = 'BREAKING';
m.f26.params.Attr(iatt).Attr(1).AttrName        = 'CONSTANT';
m.f26.params.Attr(iatt).Attr(1).Val             = {'1.0','0.73'}; % keep defaults
%%% FRICTION -- JONSWAP IS DEFAULT
iatt = iatt + 1;
m.f26.params.Attr(iatt).AttrName                = 'FRICTION';
m.f26.params.Attr(iatt).Attr(1).AttrName        = 'JONSWAP';
m.f26.params.Attr(iatt).Attr(1).Val             = {'  '}; % keep default
% % % % m.f26.params.Attr(iatt).Attr(1).AttrName = 'MADSEN'; % NOTE THAT FOR MADSEN, FRICTION MAY VARY OVER THE DOMAIN -- USE INPGRID FRICTION FOR THIS
% % % % m.f26.params.Attr(iatt).Attr(1).Val = {'0.05'}; % keep default
%%% TRIADS
% % % % iatt = iatt + 1;
% % % % m.f26.params.Attr(iatt).AttrName = 'TRIAD';
% % % % m.f26.params.Attr(iatt).Val = {'1.0','0.05','2.5','0.95','0.0','0.2','0.01'};
%%% REMOVE DEFAULT PHYSICS
% % % % iatt = iatt + 1;
% % % % m.f26.params.Attr(iatt).AttrName = 'OFF';
% % % % m.f26.params.Attr(iatt).Val = {};
% Numerics
iatt = 0;
%%% PROPAGATION SCHEME
iatt = iatt + 1;
m.f26.numerics.Attr(iatt).AttrName              = 'PROP';
m.f26.numerics.Attr(iatt).Attr(1).AttrName      = 'BSBT'; % S&L is default for nonstationary -- note that this line should be removed to keep the default
m.f26.numerics.Attr(iatt).Attr(1).Val           = {};
%%% NUMERIC
iatt = iatt + 1;
m.f26.numerics.Attr(iatt).AttrName              = 'NUMERIC';
m.f26.numerics.Attr(iatt).Attr(1).AttrName      = 'STOPC';
m.f26.numerics.Attr(iatt).Attr(1).Val           = {'DABS=0.005','DREL=0.01','CURVAT=0.005','NPNTS=95','NONSTAT','MXITNS=20'};
% Output
iatt = 0;
%%% DEFINE QUANTITY PROPERTIES
iatt = iatt + 1;
m.f26.output.Attr(iatt).AttrName                = 'QUANTITY';
m.f26.output.Attr(iatt).Attr(1).AttrName        = "HS DIR TM01 TMM10";
m.f26.output.Attr(iatt).Attr(1).Val             = {sprintf('FMIN=%.6f',FREQMIN),sprintf('FMAX=%.6f',FREQMAX)};

%%% DEFINE OUTPUT FORMAT, VARIABLES, AND TIMING
iatt = iatt + 1;
m.f26.output.Attr(iatt).AttrName                = 'BLOCK';
m.f26.output.Attr(iatt).Attr(1).AttrName	= "'COMPGRID'";
m.f26.output.Attr(iatt).Attr(1).Val             = "NOHEAD";
m.f26.output.Attr(iatt).Attr(2).AttrName	= SWAN_OUTPUT_FILENAME;
m.f26.output.Attr(iatt).Attr(2).Val             = {'LAY 3','XP YP DEPTH HS DIR DSPR TPS TM01'};
m.f26.output.Attr(iatt).Attr(3).AttrName	= 'OUTPUT';
m.f26.output.Attr(iatt).Attr(3).Val             = {datestr(ts,'yyyymmdd.HHMMSS'), "1800", "SEC"};

%%% REQUEST INTERMEDIATE RESULTS
iatt = iatt+ 1;
m.f26.output.Attr(iatt).AttrName                = 'TEST';
m.f26.output.Attr(iatt).Val                     = {'1,0'};
% Compute
m.f26.compute.startdatetime                     = sprintf('%s',datestr(datenum(ts),'yyyymmdd.HHMMSS'));
m.f26.compute.dtswan                            = sprintf('%d',DTSWAN);
m.f26.compute.enddatetime                       = sprintf('%s',datestr(datenum(te),'yyyymmdd.HHMMSS'));

% SWANINIT information
m.f26.swaninit.institute                        = 'Oregon State University';
m.f26.swaninit.input_filename                   = 'fort.26';
m.f26.swaninit.print_filename                   = 'swan.print';

% m.f26 = struct;
% m.f15.nws = 0;

%% PATCH -- REMOVE ALL CONTROL LIST VARIABLES
m.f15.controllist = [];
%% Write output files
write(m,'buildfort',{'13','14','15','20','26'});
% writefort26(m.f26,'fort.26')
save("buildfort.mat",'m')

