function obj = Make_f22(obj,windfld,presfld)
% Build wind and pressure grid information into the f15 structure


% Should check to see that grids are the same!

dt = diff(windfld.dateTime);% Should check that dt is uniform
obj.f15.wtiminc = seconds(dt(1));

% Grid information needed for fort15
obj.f22.U = windfld.U;
obj.f22.V = windfld.V;
obj.f22.P = presfld.P;


