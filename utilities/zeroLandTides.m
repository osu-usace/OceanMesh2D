function obj = zeroLandTides(obj,minDepth)
%% obj = zeroLandTides(obj,minDepth)
% This function takes in a mesh object and minimum depth (minDepth)
% and forces the tidal forcing to be zero at open boundary
% nodes where the depth is less than the minimum depth.

% Get boundary depths
bop = obj.b(obj.op.nbdv);

% Generate mask for depths less than threshold
idz = bop =< minDepth;

% zero the tidal amplitudes for depths less than threshold
for i = 1:length(obj.f15.opealpha)
    obj.f15.opealpha(idz,1) = 0;
end

