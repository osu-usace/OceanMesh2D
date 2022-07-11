function writefort26(f26dat,f26out)
%% This script writes the SWAN control file (by default, INPUT but for ADCIRC coupling is called fort.26)
%% In addition, the swaninit file is written with only a few modifications according to the user

fid = fopen(f26out,'w');

fprintf(fid,'$*************************HEADING************************\n');
% PROJ
fprintf(fid,'PROJ ');
if isfield(f26dat.proj,'name')
    fprintf(fid,'''%s'' ',f26dat.proj.name);
end
fprintf(fid,'''%s''\n',f26dat.proj.nr);
for i = 1:length(f26dat.proj.titles)
    fprintf(fid,'''%s''\n',f26dat.proj.titles{i});
end
fprintf(fid,'$\n');

fprintf(fid,'$********************MODEL INPUT*************************\n');
% SET
for i = 1:length(f26dat.set.Attr)
    fprintf(fid,'SET %s %s\n',f26dat.set.Attr(i).AttrName,f26dat.set.Attr(i).Val);
end
fprintf(fid,'$\n');
% MODE
for i = 1:length(f26dat.mode.Attr)
    fprintf(fid,'MODE %s\n',f26dat.mode.Attr(i).AttrName);
end
fprintf(fid,'$\n');
% COORD
for i = 1:length(f26dat.coord.Attr)
    fprintf(fid,'COORDINATES %s %s\n',f26dat.coord.Attr(i).AttrName,f26dat.coord.Attr(i).Val);
end
fprintf(fid,'$\n');
% CGRID
fprintf(fid,'CGRID UNSTRUCTURED CIRCLE');
fprintf(fid,' MDC=%s',f26dat.cgrid.mdc);
if isfield(f26dat.cgrid,'flow') && ~isempty(f26dat.cgrid.flow)
    fprintf(fid,' FLOW=%s',f26dat.cgrid.flow);
end
if isfield(f26dat.cgrid,'fhigh') && ~isempty(f26dat.cgrid.fhigh)
    fprintf(fid,' FHIGH=%s',f26dat.cgrid.fhigh);
end
if isfield(f26dat.cgrid,'msc') && ~isempty(f26dat.cgrid.msc)
    fprintf(fid,' MSC=%s',f26dat.cgrid.msc);
end
fprintf(fid,'\n');
% Read grid
fprintf(fid,'READ UNSTRUCTURED\n');
%
fprintf(fid,'$\n');

for i = 1:length(f26dat.inpgrid.Attr)
    fprintf(fid,'INPGRID %s UNSTRUCTURED EXCEPTION %s NONSTAT %s %s SEC %s\n',...
        f26dat.inpgrid.Attr(i).AttrName,f26dat.inpgrid.Attr(i).ExcVal,...
        f26dat.inpgrid.startdatetime,f26dat.inpgrid.dtswan,f26dat.inpgrid.enddatetime);
    fprintf(fid,'READGRID %s\n',f26dat.inpgrid.Attr(i).ReadInpName);
end
fprintf(fid,'$\n');

%%% BOUNDARY AND INITIAL CONDITIONS
for i = 1:length(f26dat.boundinit.Attr)
    fprintf(fid,'%s',f26dat.boundinit.Attr(i).AttrName);
    if isfield(f26dat.boundinit.Attr(i),'Val') && ~isempty(f26dat.boundinit.Attr(i).Val)
        for k = 1:length(f26dat.boundinit.Attr(i).Val)
            fprintf(fid,' %s',f26dat.boundinit.Attr(i).Val{k});
        end
    else
        for j = 1:length(f26dat.boundinit.Attr(i).Attr)
            fprintf(fid,' %s',f26dat.boundinit.Attr(i).Attr(j).AttrName);
            for k = 1:length(f26dat.boundinit.Attr(i).Attr(j).Val)
                fprintf(fid,' %s',f26dat.boundinit.Attr(i).Attr(j).Val{k});
            end
        end
    end
    fprintf(fid,'\n');
end
fprintf(fid,'$\n');

%%% PHYSICS PARAMETERIZATIONS
for i = 1:length(f26dat.params.Attr)
    fprintf(fid,'%s',f26dat.params.Attr(i).AttrName);
    if isfield(f26dat.params.Attr(i),'Val') && ~isempty(f26dat.params.Attr(i).Val)
        for k = 1:length(f26dat.params.Attr(i).Val)
            fprintf(fid,' %s',f26dat.params.Attr(i).Val{k});
        end
    else
        for j = 1:length(f26dat.params.Attr(i).Attr)
            fprintf(fid,' %s',f26dat.params.Attr(i).Attr(j).AttrName);
            for k = 1:length(f26dat.params.Attr(i).Attr(j).Val)
                fprintf(fid,' %s',f26dat.params.Attr(i).Attr(j).Val{k});
            end
        end
    end
    fprintf(fid,'\n');
end
fprintf(fid,'$\n');

%%% NUMERICS
for i = 1:length(f26dat.numerics.Attr)
    fprintf(fid,'%s',f26dat.numerics.Attr(i).AttrName);
    for j = 1:length(f26dat.numerics.Attr(i).Attr)
        fprintf(fid,' %s',f26dat.numerics.Attr(i).Attr(j).AttrName);
        for k = 1:length(f26dat.numerics.Attr(i).Attr(j).Val)
            fprintf(fid,' %s',f26dat.numerics.Attr(i).Attr(j).Val{k});
        end
    end
    fprintf(fid,'\n');
end
fprintf(fid,'$\n');

fprintf(fid,'$********************MODEL OUTPUT*************************\n');
%%% OUTPUT
for i = 1:length(f26dat.output.Attr)
    fprintf(fid,'%s',f26dat.output.Attr(i).AttrName);
    if isfield(f26dat.output.Attr(i),'Val') && ~isempty(f26dat.output.Attr(i).Val)
        for k = 1:length(f26dat.output.Attr(i).Val)
            fprintf(fid,' %s',f26dat.output.Attr(i).Val{k});
        end
    else
        for j = 1:length(f26dat.output.Attr(i).Attr)
            fprintf(fid,' %s',f26dat.output.Attr(i).Attr(j).AttrName);
            for k = 1:length(f26dat.output.Attr(i).Attr(j).Val)
                fprintf(fid,' %s',f26dat.output.Attr(i).Attr(j).Val{k});
            end
        end
    end
    fprintf(fid,'\n');
end
fprintf(fid,'$\n');

fprintf(fid,'$********************MODEL RUN*************************\n');
fprintf(fid,'COMPUTE %s %s SEC %s\n',f26dat.compute.startdatetime,f26dat.compute.dtswan,f26dat.compute.enddatetime);

fprintf(fid,'$\n');
fprintf(fid,'STOP\n');

fprintf(fid,'$\n');
fclose(fid);

%% SWANINIT
% Hardcode some aspects of the swaninit such as version number, comment character, tab character, etc.
f26dat.swaninit.initfile_version 		= 4;
f26dat.swaninit.institute  			= f26dat.swaninit.institute; % Put this here for reference (same order as written file below)
f26dat.swaninit.command_file_reference_number 	= 3;
f26dat.swaninit.input_filename			= f26dat.swaninit.input_filename; % Put this here for reference (same order as written file below)
f26dat.swaninit.print_file_reference_number 	= 4;
f26dat.swaninit.print_filename			= f26dat.swaninit.print_filename; % Put this here for reference (same order as written file below)
f26dat.swaninit.test_file_reference_number 	= 4;
f26dat.swaninit.test_file_name 			= '';
f26dat.swaninit.screen_reference_number 	= 6;
f26dat.swaninit.highest_file_reference_number 	= 99;
f26dat.swaninit.comment_identifier 		= '$';
f26dat.swaninit.tab_character 			= char(9); % TAB character
f26dat.swaninit.dir_sep_char_to_be_replaced 	= '\'; 
f26dat.swaninit.dir_sep_char_replacement 	= '/';
f26dat.swaninit.default_time_coding_option 	= 1;

fieldWidth  					= 40; % comment line must be on column 41

[~,fname,~] 					= fileparts(f26out);
fid         					= fopen([fname '.swaninit'],'w');
try
	fprintf(fid,'%-*d version of initialisation file\n',		fieldWidth,f26dat.swaninit.initfile_version)
	fprintf(fid,'%-*s name of institute\n',				fieldWidth,f26dat.swaninit.institute);
	fprintf(fid,'%-*d command file ref.number\n',			fieldWidth,f26dat.swaninit.command_file_reference_number);
	fprintf(fid,'%-*s command file name\n',				fieldWidth,f26dat.swaninit.input_filename);
	fprintf(fid,'%-*d print file ref. number\n',			fieldWidth,f26dat.swaninit.print_file_reference_number);
	fprintf(fid,'%-*s print file name\n',				fieldWidth,f26dat.swaninit.print_filename);
	fprintf(fid,'%-*d test file ref. number\n',			fieldWidth,f26dat.swaninit.test_file_reference_number);
	fprintf(fid,'%-*s test file name\n',				fieldWidth,f26dat.swaninit.test_file_name);
	fprintf(fid,'%-*d screen ref. number\n',			fieldWidth,f26dat.swaninit.screen_reference_number);
	fprintf(fid,'%-*d highest file ref. number\n',			fieldWidth,f26dat.swaninit.highest_file_reference_number);
	fprintf(fid,'%-*s comment identifier\n',			fieldWidth,f26dat.swaninit.comment_identifier);
	fprintf(fid,'%-*s TAB character\n',				fieldWidth,f26dat.swaninit.tab_character);
	fprintf(fid,'%-*s dir sep char in input file\n', 		fieldWidth,f26dat.swaninit.dir_sep_char_to_be_replaced);
	fprintf(fid,'%-*s dir sep char replacing previous one\n',	fieldWidth,f26dat.swaninit.dir_sep_char_replacement);
	fprintf(fid,'%-*d default time coding option\n', 		fieldWidth,f26dat.swaninit.default_time_coding_option);
catch ME
    fclose(fid);
    rethrow(ME)
end
fclose(fid);

% Keep hardcoded spacing below for reference (it doesn't work but has all the necessary information)
%fprintf(fid,'4                             version of initialisation file\n');
%fprintf(fid,'%s                            name of institute\n',f26dat.swaninit.institute);
%fprintf(fid,'3                             command file ref.number\n');
%fprintf(fid,'%s                            command file name\n',f26dat.swaninit.input_filename);
%fprintf(fid,'4                             print file ref. number\n');
%fprintf(fid,'%s                            print file name\n',f26dat.swaninit.print_filename);
%fprintf(fid,'4                             test file ref. number\n');
%fprintf(fid,'                              test file name\n');
%fprintf(fid,'6                             screen ref. number\n');
%fprintf(fid,'99                            highest file ref. number\n');
%fprintf(fid,'$                             comment identifier\n');
%fprintf(fid,'\t                            TAB character\n');
%fprintf(fid,'\\                            dir sep char in input file\n');
%fprintf(fid,'/                             dir sep char replacing previous one\n');
%fprintf(fid,'1                             default time coding option\n');
