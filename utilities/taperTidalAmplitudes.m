function obj = taperTidalAmplitudes(obj,xShoreLengthScale)
% obj = taperTidalAmplitudes(obj,xShoreLengthScale)
% Input a msh class obj with open boundary locations, tidal
% constituents, and a pre-generated f15 field, as well as a cross-shore 
% length scale, and taper the tidal constituent amplitudes as they approach 
% the beginning and end of the open boundaries. This is intended to replace
% the need for radiation boundary conditions near land
%
% Put the result into the f15 struct of the msh obj.    
% 
%                                                                       
% Created by David Honegger 21 April 2023
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Build tanh taper function
taperFunc   = @(x,L) tanh((pi./L).*x);

%% Project to meters (grab from tidal_datda_to_ob.m)

% Select desired projection (using m_map)
proj = 'UTM';
              
% Specify limits of grid
lat_min = min(obj.p(:,2)) - 1; lat_max = max(obj.p(:,2)) + 1;
lon_min = min(obj.p(:,1)) - 1; lon_max = max(obj.p(:,1)) + 1;

% doing the projection
m_proj(proj,'lon',[ lon_min lon_max],...
            'lat',[ lat_min lat_max])

lon = obj.p(obj.op.nbdv,1);
lat = obj.p(obj.op.nbdv,2);
[x,y] = m_ll2xy(lon,lat);

%% Calculate distances

dx                  = diff(x);
dy                  = diff(y);

% Calculate distances from each end of the boundary arc and combine into a
% single "minimum distance from arc end"
dists               = hypot(dx,dy);
distStart           = [0;cumsum(dists)];
distEnd             = flipud([0;cumsum(flipud(dists))]);
distVec             = min(distStart,distEnd);

%% Calculate scale factor from taper function
scaleFactor = taperFunc(distVec,xShoreLengthScale);

%% Loop through constituents and apply taper, overwriting previously written opealpha entries

for iconst = 1:length(obj.f15.opealpha)
    obj.f15.opealpha(iconst).val(:,1) = obj.f15.opealpha(iconst).val(:,1).*scaleFactor;
end