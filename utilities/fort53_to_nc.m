function fort53_to_nc(f14name,f53name)
%% This function takes in the grid and fort.53 constituent file from an 
% ADCIRC run (e.g. ENPAC15) and creates a NetCDF file that is usable in a
% slightly modified version of W. Pringle's tidal_data_to_ob.m
%
% Defaults are set to ENPAC15 (bottom of page here:
% https://adcirc.org/products/adcirc-tidal-databases/)

if ~exist("f14name","var") || isempty(f14name)
    f14name = "wc2015_v1a_chk.grd";
end
if ~exist("f53name","var") || isempty(f53name)
    f53name  = "wc2015-v1a_1200tau1dt1VDatum_fort.53";
end
ncName = strcat(f53name,".nc");
% ncName  = "wc2015-v1a_1200tau1dt1VDatum_fort.53.nc";

%% Read fort.14
toolboxConnect OceanMesh2D
toolboxConnect m_map
m = msh('fname',f14name);

%% Read fort.53 -- not optimized for speed! But only needs to be done once.

fidi = fopen(f53name,'rt');
ll = fgetl(fidi);
nconst = sscanf(ll,'%d');

hafreq  = NaN(nconst,1);
haff    = NaN(nconst,1);
haface  = NaN(nconst,1);
namefr  = strings(nconst,1);
for i = 1:nconst
    ll = fgetl(fidi);
    C = textscan(ll,'%f %f %f %s');
    hafreq(i) = C{1};
    haff(i) = C{2};
    haface(i) = C{3};
    namefr(i) = string(C{4});
end

ll      = fgetl(fidi);
nnod    = sscanf(ll,'%d');

emagt   = NaN(nnod,nconst);
phasede = NaN(nnod,nconst);
for ip = 1:nnod
    ll = fgetl(fidi);
    if sscanf(ll,'%d')~=ip
        disp Loop index does not correspond to the listed node number
        keyboard
    end
    for ifr = 1:nconst
        ll = fgetl(fidi);
        C = sscanf(ll,'%f',2);
        emagt(ip,ifr) = C(1);
        phasede(ip,ifr) = C(2);
    end
end
fclose(fidi);
%% Format to tpxo variables

nc.con      = char(lower(erase(namefr,["(" ")"])));
nc.freq     = hafreq;
nc.nodfac   = haff;
nc.eqarg    = haface;
nc.lon_z    = m.p(:,1);
nc.lat_z    = m.p(:,2);
nc.tri      = m.t;
nc.ha       = emagt;
nc.hp       = phasede;
nc.hRe      = emagt.*cosd(phasede);
nc.hIm      = emagt.*sind(phasede);

%
ncd.nc      = nconst;
ncd.nct     = size(nc.con,2);
ncd.nk      = nnod;
%
nccreate(ncName,"con","Dimensions",{"nct",ncd.nct,"nc",ncd.nc},"DataType","char","Format","netcdf4");
ncwrite(ncName,"con",nc.con')
%
nccreate(ncName,"freq","Dimensions",{"nc"},"Datatype","double");
ncwriteatt(ncName,"freq","long_name","constituent frequency")
ncwriteatt(ncName,"freq","units","rad/s")
ncwrite(ncName,"freq",nc.freq);
%
nccreate(ncName,"nodfac","Dimensions",{"nc"},"Datatype","double");
ncwriteatt(ncName,"nodfac","long_name","constituent nodal factor")
ncwriteatt(ncName,"nodfac","units","unitless")
ncwrite(ncName,"nodfac",nc.nodfac);
%
nccreate(ncName,"eqarg","Dimensions",{"nc"},"Datatype","double");
ncwriteatt(ncName,"eqarg","long_name","constituent equilibrium argument")
ncwriteatt(ncName,"eqarg","units","degrees")
ncwrite(ncName,"eqarg",nc.nodfac);
%
nccreate(ncName,"lon_z","Dimensions",{"nk",ncd.nk},"Datatype","double");
ncwriteatt(ncName,"lon_z","long_name","longitude of nodes")
ncwriteatt(ncName,"lon_z","units","degree_east")
ncwrite(ncName,"lon_z",nc.lon_z);
%
nccreate(ncName,"lat_z","Dimensions",{"nk"},"Datatype","double");
ncwriteatt(ncName,"lat_z","long_name","latitude of nodes")
ncwriteatt(ncName,"lat_z","units","degree_north")
ncwrite(ncName,"lat_z",nc.lat_z);
%
nccreate(ncName,"tri","Dimensions",{"nele",size(nc.tri,1),"nnod",3},"Datatype","double");
ncwriteatt(ncName,"tri","long_name","latitude of nodes")
ncwriteatt(ncName,"tri","units","degree_north")
ncwrite(ncName,"tri",nc.tri);
%
nccreate(ncName,"ha","Dimensions",{"nk","nc"},"Datatype","double");
ncwriteatt(ncName,"ha","long_name","Tidal elevation amplitude")
ncwriteatt(ncName,"ha","units","meter")
ncwrite(ncName,"ha",nc.ha);
%
nccreate(ncName,"hp","Dimensions",{"nk","nc"},"Datatype","double");
ncwriteatt(ncName,"hp","long_name","Tidal elevation phase")
ncwriteatt(ncName,"hp","units","degree GMT")
ncwrite(ncName,"hp",nc.hp);
%
nccreate(ncName,"hRe","Dimensions",{"nk","nc"},"Datatype","double");
ncwriteatt(ncName,"hRe","long_name","Tidal elevation complex amplitude, Real part")
ncwriteatt(ncName,"hRe","units","meter")
ncwrite(ncName,"hRe",nc.hRe);
%
nccreate(ncName,"hIm","Dimensions",{"nk","nc"},"Datatype","double");
ncwriteatt(ncName,"hIm","long_name","Tidal elevation complex amplitude, Imag part")
ncwriteatt(ncName,"hIm","units","meter")
ncwrite(ncName,"hIm",nc.hIm);

