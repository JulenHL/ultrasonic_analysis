function [matlab_data, choice_dat, rat_ID_output] = extract_timing_event(varargin)

%% Event code identifiers

% \  1   = Start session          % Box OUTPUT
% \  2   = NosePoke ON            % Box OUTPUT
% \  3   = Succesful NosePoke     % Rat Event
% \  4   = NoShock Lever Press    % Rat Event
% \  5   = Shock Lever Press      % Rat Event
% \  6   = Rwd Delivered          % Box OUTPUT
% \  7   = End Trial (start ITI)  % Box OUTPUT
% \  8   = End Session            % Box OUTPUT
% \  10  = Shock                  % Box OUTPUT

% Omissions
% \  -1   = NosePoke TimeOut      % Box OUTPUT
% \  -2   = Lever Press TimeOut   % Box OUTPUT
% \  -3   = Short NosePoke        % Box OUTPUT
% \  -4   = NosePoke during ITI   % Box OUTPUT


%% Extraction

global output_log
dat = varargin{1};

% Input parameters
nTrials = 24;
nRats = size(dat,2);
nSess = size(dat,1);

% Pre alloc
trial_numb = NaN(nRats, 1);
choice_dat = cell(nRats, nSess);
matlab_data = cell(1,nRats);
failed_trial = [];

% flags for filenames
rat_ID = ['Rat_1-1';'Rat_3-1';'Rat_1-2';'Rat_3-2';'Rat_1-3';'Rat_3-3';];
rat_ID_output = NaN(nSess,nRats);

for iRat = 1 : nRats
    
    for iSess = 1 : nSess

idx_zeros = dat(iSess,iRat).N == 0;
idx_NaN = isnan(dat(iSess,iRat).N);
idx = logical(idx_zeros+idx_NaN);

curr_rat = str2double(dat(iSess,iRat).subject{1});
rat_ID_output(iSess, curr_rat) = curr_rat ; 

events = dat(iSess,iRat).N;
timing = dat(iSess,iRat).O;

selected_events = events(~idx)';
selected_timing = timing(~idx)';

selected_dat = [selected_events,selected_timing];

  % Check if coding is correct
  % Start session
  if ~isequal(selected_dat(1,1),true)
      output_log = (['First event is not start session for ' dat(iSess,iRat).experiment{1} ', Rat #' rat_ID(str2double(dat(iSess,iRat).subject{1}), 1:end)]);
      disp (output_log)
      write_output  
  end
 
  % End Session
  if ~isequal(selected_dat(end,1),8)
      output_log = (['Last event is not end session for ' dat(iSess,iRat).experiment{1} ', Rat #' rat_ID(str2double(dat(iSess,iRat).subject{1}), 1:end)]);
      disp (output_log)
      write_output  
  end
 
  % Check trial number
  trial_numb(iRat,1) = sum(selected_dat(:,1) == 5) + sum(selected_dat(:,1) == 4); 
  if ~isequal(trial_numb(iRat,1), nTrials)
     output_log = (['Prob with trial numb = ' dat(iSess,iRat).experiment{1} ', Rat #' rat_ID(str2double(dat(iSess,iRat).subject{1}), 1:end) '. Trial # = ' num2str(trial_numb(iRat,1))]);
     disp (output_log)
     write_output          
     
     [~,failed_pos] = ismember(-1 ,selected_dat(:,1));
     trial_pos = sort([find(selected_dat(:,1) == 5);find(selected_dat(:,1) == 4)]);
     failed_trial = sum(trial_pos < failed_pos)+1;
     
     if isequal(sum(ismember(selected_dat(:,1),-1)) > false,true) % NosePoke TimeOut
     output_log = (['Failed NP trial ' dat(iSess,iRat).experiment{1} ', Rat #' rat_ID(str2double(dat(iSess,iRat).subject{1}), 1:end) '. Trial # = ' num2str(failed_trial)]);
     disp (output_log)
     write_output                      
     end   
  end
  
  % Reproduce choice data
  idx_shock = selected_dat(:,1) == 5;
  idx_noshock = selected_dat(:,1) == 4;
  idx_trial = logical(idx_shock + idx_noshock);
  choice_dat{iRat,iSess} = events(idx_trial);
  if ~isempty(failed_trial)
%   choice_dat{iRat,iSess}(1,failed_trial) = NaN; % Insert failed trials
  choice_dat{iRat,iSess} = [choice_dat{iRat,iSess}(1:(failed_trial-1)),NaN(1,length(failed_trial)), choice_dat{iRat,iSess}(1,failed_trial:end)];
  end
  failed_trial = [];
  
  % output the data as excel file
  filename = [rat_ID(str2double(dat(iSess,iRat).subject{1}), 1:end) '_' dat(iSess,iRat).experiment{1}];
  xlswrite(filename, selected_dat)
  
  % output the data as matlabfile
  matlab_data{iSess,curr_rat} = selected_dat;
  
    end
     
end

    function write_output
        
                 %disp(output_log)
                 fid = fopen('output_log.txt','a+');
                 fprintf(fid, ' %s\r\n', output_log);
                 fclose(fid);        
    end

end