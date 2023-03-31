function obj = taperTidalAmplitudes(obj,xShoreLengthScale)
% obj = taperTidalAmplitudes(obj,xShoreLengthScale)
% Input a msh class obj with open boundary locations, tidal
% constituents, and a pre-generated f15 field, as well as a cross-shore 
% length scale, and taper the tidal constituent amplitudes as they approach 
% the beginning and end of the open boundaries. This is intended to replace
% the need for sponge boundary conditions
%
% Put the result into the f15 struct of the msh obj.    
% 
%                                                                       
% Created by David Honegger March 31 2023
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Build tanh taper function
taperFunc   = @(x,L) tanh((pi./L).*x);

%% Calculate distances
reflat1     = obj.p(obj.op.nbdv(1),2);
dlonlat1    = diff(obj.p(obj.op.nbdv,:));

reflat2     = obj.p(obj.op.nbdv(end),2);

% Convert to meters; simple
dyFunc      = @(dlat,reflat) (111132.92 - 559.82*cosd(2*reflat) + 1.175*cosd(4*reflat) - 0.0023*cosd(6*reflat)) .*dlat;
dxFunc      = @(dlon,reflat) (111412.84*cosd(reflat) - 93.5*cosd(3*reflat) + 0.118*cosd(5*reflat)) .*dlon;

dx1         = dxFunc(dlonlat1(:,1),reflat1);
dy1         = dyFunc(dlonlat1(:,2),reflat1);

dx2         = dxFunc(dlonlat1(:,1),reflat2);
dy2         = dyFunc(dlonlat1(:,2),reflat2);

dist1       = [0;cumsum(hypot(dx1,dy1))];
dist2       = flipud([0;cumsum(flipud(hypot(dx2,dy2)))]);

scaleFactor1 = taperFunc(dist1,xShoreLengthScale);
scaleFactor2 = taperFunc(dist2,xShoreLengthScale);

% Only apply to nodes within the xShore Length scale provided. Assume that
% Open boundary beginning and end are at land
id1         = dist1<=2*xShoreLengthScale;
id2         = dist2<=2*xShoreLengthScale;

scaleFactor = ones(size(id1));
scaleFactor(id1) = scaleFactor1(id1);
scaleFactor(id2) = scaleFactor2(id2);

%% Loop through constituents and apply taper

for iconst = 1:length(obj.f15.opealpha)
    obj.f15.opealpha(iconst).val(:,1) = obj.f15.opealpha(iconst).val(:,1).*scaleFactor;
end