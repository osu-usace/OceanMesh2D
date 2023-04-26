function obj = taperTidalGradients(obj,L)
% obj = taperTidalGradients(obj,L)
% Input a msh class obj with open boundary locations, tidal
% constituents, and a pre-generated f15 field, as well as an along-arc
% length scale, and taper the tidal amplitude/phase gradients as they 
% approach the beginning and end of the open boundaries using a quadratic.
% This is intended to replace the need for radiation boundary conditions 
% near land.
%
% Put the result into the f15 struct of the msh obj.    
% 
%                                                                       
% Created by David Honegger 25 April 2023
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
[~,idStart]         = min(abs(distStart-L));

distEnd             = flipud([0;cumsum(flipud(dists))]);
[~,idEnd]         = min(abs(distEnd-L));

%% Loop through constituents and apply taper, overwriting previously written opealpha entries

for iconst = 1:length(obj.f15.opealpha)
    val     = obj.f15.opealpha(iconst).val;
    dvaldx  = diff(val,1,1)./diff(distStart);

    sval = val;
    sval(1:idStart,:) = val(idStart,:) + dvaldx(idStart,:)/2/L.*(distStart(1:idStart).^2-L^2);

    dvaldx  = diff(val,1,1)./diff(distEnd);
    sval(idEnd:end,:) = val(idEnd,:)   + dvaldx(idEnd,:)/2/L  .*(distEnd(idEnd:end).^2  -L^2);

    
    obj.f15.opealpha(iconst).val = sval;
end

