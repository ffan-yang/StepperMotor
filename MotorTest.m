classdef MotorTest < matlab.apps.AppBase
       %% Properties corresponding to app components
    properties (Access = public)
        UIFigure                    matlab.ui.Figure
        LoadanewtrialLabel          matlab.ui.control.Label
        triallist                   matlab.ui.control.ListBox
    end
    
    properties
        data % movie and data recording data set
    end
    
    methods
        
         function LoadExperimentData(app)
            
                % define the current animal folder
                basedirLabVIEW = '\\157.136.60.15\EqShulz\Fan\DATA_MICE_FAN\DATA_FY3\LABVIEW';
                basedirHIRIS = '\\\\157.136.60.15\EqShulz\Fan\DATA_MICE_FAN\DATA_FY3\HIRIS';
%                basedirROI = 'C:\Users\YangF\Desktop\DATA\ROI';
                % selet the folder
                s = struct(...
                'FreqSample',      {'20211216', 'char'});%,...
                % 'PID',{1, 'char'});
%                 'Session',  {1, 'stepper'}, ...
%                 'Mouse',    {1, 'stepper'});
                   % 'Batch',    {8, 'stepper'}, ... 
                % brick.structedit calls the gui for mouse, session, week, day selection; the above values can then be changed
                % interactively; and the new values will be memorized for next time
                s = brick.structedit(s, 'memorize');  
                
                app.data.params = s;   

                % HIRIS video folder
%                 animal_infor = fullfile(['Week' num2str(s.Week)],...
%                     s.Date,['Session' num2str(s.Session)],['Mouse' num2str(s.Mouse)]);   

                animal_infor = [s.FreqSample];
                hiris_dir = fullfile(basedirHIRIS,animal_infor);
                app.data.hiris_dir = hiris_dir;
                if ~exist(hiris_dir, 'dir')
                    error('hiris_folder "%s" does not exist', hiris_dir)
                end            
                % Labview tdms data folder
                labview_dir = fullfile(basedirLabVIEW,animal_infor);
                if ~exist(labview_dir, 'dir')
                    error('labview_folder "%s" does not exist', labview_dir)
                end
                % file path 
                AI_file = fullfile(labview_dir,'AI.tdms');
                STAMP_file = fullfile(labview_dir,'TimeStamps.tdms');
                training_file =  fullfile(labview_dir,'trainingPara.txt');
                %ROI_file = fullfile(basedirROI,[animal_infor,'.txt']);
                hiris_file = fullfile(hiris_dir,'movie.avi');
                
                %app.data.hiris_dir = hiris_dir;
                app.data.labview_dir = labview_dir;
                app.data.AI_file = AI_file;
                app.data.STAMP_file = STAMP_file;
                app.data.hiris_file = hiris_file;
               % app.data.ROI_file = ROI_file;
                % LoadLabviewData and Name coorespond chennels
                disp('Load Labview data...')
                AI_TDMS = TDMS_readTDMSFile(AI_file);
                ai_tdms = squeeze(cat(3,AI_TDMS.data{3:end})); 
                delay = 0;
                   
                app.data.delay = delay;
                labview_daley = delay*10000;
                ai_tdms (1:labview_daley,:)=[];
                app.data.ai_tdms = ai_tdms;
                app.data.labview_names = {'TimeClock_hiris','Task_trigger', 'TimeClock_basler','Lickport_servo', ...
                     'licking_detection', 'Valve_opening','ROI1','ROI2','stepper_direction','stepper_pulse',...
                     'Calcium light','Calcium imaging','VSD light','VSD imaging','MiCam_stim1'};
                
                % Load time stamps and NAME
                 disp('Load Labview time stamp...')
                 STAMP_TDMS = TDMS_readTDMSFile(STAMP_file);
                 stamp_tdms = squeeze(cat(3,STAMP_TDMS.data{3:end})); 
                 % clean redual zeros in stamps tdms data
                 stamp_cell = num2cell(stamp_tdms,[3 5]);
                 stamp_cell = cellfun(@(x) x(x~=0), stamp_cell,'UniformOutput',false);
                 stamp_names = {'rewardStart','BigtouchStamps', 'trialFinish', ...
                                    'roi1Touch', 'OmissionTrial','roi1Detach',...
                                    'roi2Touch','rewardFinish','StandardRecoedingIndex'};
                 % cell to structure
                 timeStamps = cell2struct(stamp_cell, stamp_names, 2);
                 app.data.timeStamps = timeStamps;

                 % load experiment paramter
                 training = textread(training_file);
                 requestTONum = training(2);
                 app.data.requestTONum = requestTONum;
                 Omi_oupas = training(12);
                 app.data.Omi_oupas = (Omi_oupas==1);
                 % LoadRecordingMovie
                 
                 video = VideoReader(hiris_file);
                 app.data.n_hiris = video.NumFrames;
                 app.data.n_labview = size( ai_tdms ,1);
                 disp 'Number of frames in this video =  '
                 disp(app.data.n_hiris)
                 disp 'Labview data length =  '
                 disp(app.data.n_labview)
                 
                 app.data.video = video;
                % Sampling frequencies
                app.data.fs_hiris = 500;
                app.data.fs_labview = 10e3;
               
                 % Save app in the base workspace
                assignin('base','app',app)
         end
        
         function FindTrials(app)
               disp 'Searching for trials...'
               % calibrate time stamps frmm labview with delay and relative
               % trigger latency and seems no latency

               % cut trials by the time stamps saved
               delay = app.data.delay;
               clock_fre = 1000;
               app.data.clock_fre = clock_fre; 
               timeStamps = app.data.timeStamps;
               rewardStart =  cat(1,timeStamps.rewardStart) - delay*clock_fre;
               rewardFinish =  cat(1,timeStamps.rewardFinish) - delay*clock_fre;
               trialFinish =  cat(1,timeStamps.trialFinish) - delay*clock_fre;
               trials_time_zero = trialFinish/clock_fre+0.1;
               time_rewardStart = rewardStart/clock_fre;
               time_rewardFinish = rewardFinish/clock_fre;
               app.data.trials_time_zero = trials_time_zero;
               app.data.time_rewardStart = time_rewardStart;
               app.data.time_rewardFinish = time_rewardFinish;
               
               trials_offset = [0;trials_time_zero(1:end-1)];
               app.data.trials_offset = trials_offset;
               trials_duration = trials_time_zero - trials_offset;
               app.data.trials_duration = trials_duration;  
               ntrial = length(trialFinish);
               app.data.ntrial = ntrial;

               disp(['Number of trials in this session: ' num2str(ntrial)])

                % cut the session into trials by when the reward finish
                essais = cell(1, ntrial);
                for i = 1:ntrial  
                    if trials_time_zero(i)*app.data.fs_labview < app.data.n_labview
                        idx = trials_offset(i)*app.data.fs_labview+1:trials_time_zero(i)*app.data.fs_labview;
                    else
                        idx = trials_offset(i)*app.data.fs_labview+1:app.data.n_labview;
                    end
                    idx = int64(idx);
                    essais{i} = app.data.ai_tdms(idx, :); 
                end
                app.data.essais = essais;
                
               % Trial sequence (standard or omission trial)
                Trial_list = cell(ntrial,1);
                Trial_list(:)= {'Standard_Trial'};
                % Omission Trial
                if app.data.Omi_oupas == 1
                    Omission_List = cat(1, app.data.timeStamps.OmissionTrial);
                    Omission_List(Omission_List>ntrial)=[];
                else
                    Omission_List = [];
                end
                Trial_list(Omission_List) = {'Omission_Trial'};
                NumTrial =num2cell([1:1:ntrial].');
                NumTrial = cellfun(@num2str,NumTrial,'un',0);
           
                Trial_name = cellfun(@(x,y) [x y],Trial_list,NumTrial,'un',0);
                app.data.Trial_name = Trial_name;   

                % save app in the base workspace
                set(app.triallist, 'Items', app.data.Trial_name)
                disp (['Total number of omissions in this session: ' num2str(length(Omission_List))])
                disp (['The index of omission trials are: ' num2str(Omission_List.')]);
                assignin('base','app',app)  
         end
         
         function LoadProecessedDATA(app)
             % load tracked whisker (x,y) cooradinates
              recompute_struct_file = load([app.data.hiris_dir '\recompute_struct.mat']);
              recompute_struct = recompute_struct_file.recompute_struct;
              app.data.recompute_struct = recompute_struct;
             % load the angle and curvature information 
%              smoothed_struct_file = load([app.data.hiris_dir '\smoothed_struct.mat']);
%              smoothed_struct = smoothed_struct_file.smoothed_struct;
             % smooth the parameters
%               angle = cat(1,recompute_struct(:).angle);
%               app.data.smoothed_struct(:,1) = smooth_Data_gau(angle,3);
%               curvature = cat(1,recompute_struct(:).curvature);
%               app.data.smoothed_struct(:,2) = smooth_Data_gau(curvature,3);
%               follicle_x = cat(1,recompute_struct(:).folliclex);
%               app.data.smoothed_struct(:,3) = smooth_Data_gau(follicle_x,3);
%               follicle_y = 608 - cat(1,recompute_struct(:).follicley);
%               app.data.smoothed_struct(:,4)= smooth_Data_gau(follicle_y,3);
%               
% %              % load the xline results
%                ylineExtract_file = load([app.data.hiris_dir '\ylineextract.mat']);
%                point_y = 608 - ylineExtract_file.ylineExtract.point_y; 
%                point_x = ylineExtract_file.ylineExtract.point_x; 
% %              % find the frame number that the background light became
% %              % suddenly brighter
%                smooth_point_y = smooth_Data_gau(point_y',3);
%                smooth_point_x = smooth_Data_gau(point_x',3);
% %              y1 = app.data.Traj_struct.y1;
% %              suden = sum(isnan(y1));
%                app.data.smoothed_struct(:,5)= smooth_Data_gau(smooth_point_y,3);
%                app.data.smoothed_struct(:,6)= smooth_Data_gau(smooth_point_x,3);
%                
%                % the unsmoothed data
%                app.data.unsmoothed_struct(:,1) = angle;
%                app.data.unsmoothed_struct(:,2) = curvature;
%                app.data.unsmoothed_struct(:,3) = follicle_x;
%                app.data.unsmoothed_struct(:,4) = follicle_y;
%                app.data.unsmoothed_struct(:,5) = point_y;
%                app.data.unsmoothed_struct(:,6) = point_x;             
               
%              disp([num2str(suden) ' frames suddenly became very bright during experiment'])
%              disp(['In percentage: ' num2str(suden/app.data.n_hiris*100) '%'])
         end
         function DisplayROIShape(app)
             % load .shp file
             fileID = fopen(app.data.ROI_file,'r');
             ROI_shape = textscan(fileID,'%s %s','Delimiter',',');
             fclose(fileID);
             app.data.ROI.x0_roi1 = str2num(ROI_shape{1, 2}{2});
             app.data.ROI.y0_roi1 = str2num(ROI_shape{1, 2}{3});
             app.data.ROI.x0_roi2 = str2num(ROI_shape{1, 2}{6});
             app.data.ROI.y0_roi2 = str2num(ROI_shape{1, 2}{7});
             app.data.ROI.obj1.point1_x = str2num(ROI_shape{1, 2}{10});
             app.data.ROI.obj1.point1_y = str2num(ROI_shape{1, 2}{11});
             % plot object2
             app.data.ROI.obj2.point1_x = str2num(ROI_shape{1, 2}{13});
             app.data.ROI.obj2.point1_y = str2num(ROI_shape{1, 2}{14});
             
             app.data.ROI.diameter_roi = str2num(ROI_shape{1, 2}{4})/2;
             % ROI shape from Xplr
             % plot the the front ROI after move
%              app.data.ROI.x0_roi11 = str2num(ROI_shape{1, 2}{16});
%              app.data.ROI.y0_roi11 = str2num(ROI_shape{1, 2}{17});


            s.shape = 'circle';
            s.width__or__diameter = app.data.ROI.diameter_roi;
            s.height__if__applicable = app.data.ROI.diameter_roi;
            w = s.width__or__diameter;
            h = s.height__if__applicable;

            r = s.width__or__diameter / 2;
            pos_roi1 = [app.data.ROI.x0_roi1/2,app.data.ROI.y0_roi1/2];
            shape_roi1 = xplr.SelectionND('ellipse2D', ...
                        {pos_roi1, [r 0], 1});
                    %roi 2
            pos_roi2 = [app.data.ROI.x0_roi2/2,app.data.ROI.y0_roi2/2];
            shape_roi2 = xplr.SelectionND('ellipse2D', ...
                        {pos_roi2, [r 0], 1});
%             pos_roi11 = [app.data.ROI.x0_roi11/2,app.data.ROI.y0_roi11/2];
%             shape_roi11 = xplr.SelectionND('ellipse2D', ...
%                         {pos_roi11, [r 0], 1});
            F = app.data.view.hiris.D.navigation.selection_filter;        
            F.update_selection('new', shape_roi1)         
            F.update_selection('new', shape_roi2)
%             F.update_selection('new', shape_roi11)
         end
                  
         
         function CreateMovieWhisker(app)

            % Load Hiris data corresponding to the selected trial
            fs_hiris = app.data.fs_hiris;
            disp 'Load the Hiris movie corresponding to the selected trial'
            ktrial = app.data.ktrial;
            v = app.data.video;
            FrameOffset = ceil(app.data.trials_offset(ktrial)*fs_hiris)+1;
            LastFrame = ceil(app.data.trials_time_zero(ktrial)*fs_hiris);
            app.data.FrameOffset = FrameOffset;
            app.data.LastFrame = LastFrame;
            
            Nb_of_frames_video = LastFrame - FrameOffset+1;
            app.data.Nb_of_frames_video = Nb_of_frames_video;

            xbin = 2; % spatial binning to avoid memory crash!
            rect = [1 1 608 600];
            app.data.hiris_subregion = [rect(1)+[0, rect(3)-1], rect(2)+[0, rect(4)-1]]; % store rectangle as xmin, xmax, ymin, ymax
            app.data.hiris_subregion_size = rect(3:4);
            hiris = zeros([floor(app.data.hiris_subregion_size/xbin) Nb_of_frames_video],'uint8');
            sub_x = app.data.hiris_subregion(1):app.data.hiris_subregion(2);
            sub_y = app.data.hiris_subregion(3):app.data.hiris_subregion(4);
            disp(['Number of frames: ' num2str(Nb_of_frames_video) ' (' num2str(FrameOffset) ' -> ' num2str(Nb_of_frames_video+FrameOffset-1) ')'])
            block_size = 500; % read video by blocks of 1 second
            nblock = ceil(Nb_of_frames_video / block_size);
            brick.progress('read 1-second movie block', nblock)
            
            for j = 1 : nblock
                brick.progress(j)
                idx = 1+(j-1)*block_size:min(j*block_size,Nb_of_frames_video);
                Block = read(v, FrameOffset + idx([1 end]));
                Block = squeeze(Block(sub_y,sub_x,1,:)); % Keep only 1 channel of grayscale video, and only data from subregion
                Block = permute(Block, [2 1 3]); % Invert x and y
                Block = brick.bin(Block, xbin);     % Apply spatial binning
                hiris(:, :, idx) = Block;
            end
            app.data.hiris = hiris;
%             
%             movie_whisker = zeros(app.data.video.Width,app.data.video.Height,Nb_of_frames_video,'uint8');
%             [nx, ny, ~] = size(hiris);  
%             % whisker coordinates gathered for all frames
%             x = {app.data.recompute_struct(FrameOffset+1:LastFrame+1).posx};
%             y = {app.data.recompute_struct(FrameOffset+1:LastFrame+1).posy};
%             used_for_angle = x;
%             frames = x;          
%             start_point = 30;
%             end_point = 50;                
%             for i = 1:Nb_of_frames_video
%                 frames{i}(:) = i; 
%                 used_for_angle{i} = false(length(x{i}), 1); 
%                 if ~isscalar(x{i})
%                     used_for_angle{i}([start_point end_point]) = true;
%                 end
%             end
%             pos = cat(2, cat(1, x{:}), cat(1, y{:})); % npoints_over_all_frames * x/y
%             frames = cat(1, frames{:});
%             used_for_angle = cat(1, used_for_angle{:});
%             % whisker coordinates when we put point 0,0 at top-left corner
%             pos = pos - 0.5;
%             % whisker coordinates when we put point 0,0 at top-left
%             % corner of the movie subregion
%             pos = brick.subtract(pos, (rect(1:2) - 1));
%             % whisker coordinates when we put point 0,0 at top-left
%             % corner of the movie subregion and apply the spatial binning
%             pos = pos / xbin;
%             % whisker coordinates when we put point 1,1 on the center
%             % of the cropped and binned image
%             pos = round(pos + 0.5);
%             % check points that fall out of the cropped image
%             x = squeeze(pos(:, 1));  % vector of all x positions for whisker points in all frames
%             y = squeeze(pos(:, 2));
%             ok = (x>=1 & x<=size(hiris,1) & y>=1 & y<=size(hiris,2));
%             x = x(ok);
%             y = y(ok);
%             frames = frames(ok); 
%             used_for_angle = used_for_angle(ok); 
%             % whisker coordinates converted to movie global ("linear") indices
%             idx = sub2ind([nx, ny, Nb_of_frames_video], x, y, frames);
% 
%             % imprint whisker tracking points into the movie in white
%             app.data.hiris(idx) = 150;
%             app.data.hiris(idx(used_for_angle)) = 255; % a full white for points used for angle calculation
         end        
         
         function ShowTrialWhisker(app, ~)
            % Temporal information
            fs_labview = app.data.fs_labview;
            fs_hiris = app.data.fs_hiris;
            N_labview = size(app.data.essais{app.data.ktrial}, 1);
            disp(['Number of Labview Data: ' num2str(N_labview)]);
            labview_t0 = app.data.trials_offset(app.data.ktrial);
            app.data.labview_t0 = labview_t0;
            N_hiris = app.data.Nb_of_frames_video;
            hiris_t0 = app.data.trials_offset(app.data.ktrial);
            app.data.hiris_t0 = hiris_t0;

            % Display all data in linked windows Structure to store XPLOR window handles
            if ~isfield(app.data, 'view')
                xplor.close_all_windows()
                app.data.view = struct();
            end

            % HIRIS camera movie
            % specify header info as 'label', 'unit', scale, start
            movie = app.data.hiris;
            movie_info = {{'x' 'px' 1 1}, {'y' 'px' 1 1}, {'time' 's' 1/fs_hiris hiris_t0}};
            if ~isfield(app.data.view, 'hiris') || ~isvalid(app.data.view.hiris)
                V = xplor(movie, ...
                    'name', 'HIRIS movie', ...
                    'header', movie_info, ...
                    'colormap', gray, ...
                    'view&ROI', {'x' 'y'}, ...
                    'controls', 'off');
                app.data.view.hiris = V;
                % commands below are not official and might not work in the future
                V.D.navigation.selection_2d_shape = 'rect';
                % V.D.navigation.selection_at_most_one = true;
            else
                time_header = xplr.Header('time', N_hiris, 's', 1/fs_hiris, hiris_t0);
                V = app.data.view.hiris;
                V.data.update_data('all', 3, [], movie, time_header)
                V.C.dim_action('filter', 'time')
            end  
                    
            % LabVIEW recording 
            ktrial = app.data.ktrial;
            labview_names = app.data.labview_names;
            labview_data = app.data.essais{ktrial};

            if ~isfield(app.data.view, 'LabVIEW_signals') || ~isvalid(app.data.view.LabVIEW_signals)
                info = { ...
                    {'time' 's' 1/fs_labview labview_t0}, ...
                    {'variables' labview_names} ...
                    };
                V = xplor(labview_data, ...
                    'name', 'LabVIEW', ...
                    'header', info, ...
                    'view&ROI', 'time', ...
                    'controls', 'off');
                app.data.view.LabVIEW_signals = V;
                % commands below are not official and might not work in the future
%                 V.D.labels.label_move('variables ROI', 'y')
%                 V.D.clipping.set_independent_dim('variables ROI')
%                 V.D.clipping.adjust_to_view = false;
            else
                time_header = xplr.Header('time', N_labview, 's', 1/fs_labview, labview_t0);
                app.data.view.LabVIEW_signals.data.update_data('all', 1, [], labview_data, time_header)
            end
%             
%             % processed data (smoothed angle/curvature,yline trace and yline results)
%             Whisking_names = {'Whisking Angle','Whisking Curvature','follicleX','follicleY','Whisker PositonX','Whisker PositonY'};%,'Whisker trajectory','TD by xline'};
%             % show the data corresponding to current trial
%             Whisking_data_smoothed = app.data.smoothed_struct(app.data.FrameOffset:app.data.LastFrame,:);
%             if ~isfield(app.data.view, 'Whisking_signals_Smoothed') || ~isvalid(app.data.view.Whisking_signals_Smoothed)
%                 info = { ...
%                     {'time' 's' 1/fs_hiris hiris_t0}, ...
%                     {'variables' Whisking_names} ...
%                     };
%                 V = xplor(Whisking_data_smoothed, ...
%                     'name', 'Whisking smooth', ...
%                     'header', info, ...
%                     'view&ROI', 'time', ...
%                     'controls', 'off');
%                 app.data.view.Whisking_signals_Smoothed = V;
%             else
%                 time_header = xplr.Header('time', N_hiris, 's', 1/fs_hiris, hiris_t0);
%                 app.data.view.Whisking_signals_Smoothed.data.update_data('all', 1, [], Whisking_data_smoothed, time_header)
%             end
%             
%             Whisking_data_raw = app.data.unsmoothed_struct(app.data.FrameOffset:app.data.LastFrame,:);
%             if ~isfield(app.data.view, 'Whisking_signals_Unsmoothed') || ~isvalid(app.data.view.Whisking_signals_Unsmoothed)
%                 info = { ...
%                     {'time' 's' 1/fs_hiris hiris_t0}, ...
%                     {'variables' Whisking_names} ...
%                     };
%                 V = xplor(Whisking_data_raw, ...
%                     'name', 'Whisking raw', ...
%                     'header', info, ...
%                     'view&ROI', 'time', ...
%                     'controls', 'off');
%                 app.data.view.Whisking_signals_Unsmoothed = V;
%             else
%                 time_header = xplr.Header('time', N_hiris, 's', 1/fs_hiris, hiris_t0);
%                 app.data.view.Whisking_signals_Unsmoothed.data.update_data('all', 1, [], Whisking_data_raw, time_header)
%             end
            
            
            
         end        
         function TriallistValueChanged(app, ~)
            % Change trial
            itemname = app.triallist.Value;
            itemname = regexp(itemname, '[0-9]*', 'match');
            itemname = itemname{1};
            ktrial = str2double(itemname);
            app.data.ktrial = ktrial;
            disp (['Selected trial: ' num2str(ktrial)])
            CreateMovieWhisker(app)
            ShowTrialWhisker(app)
          end
               
    end
        
     
   % Methods of construction of the class and the gui
    
    methods (Access = private)
        
          % Code that executes after component creation
         function startupFcn(app)      
             LoadExperimentData(app)
             FindTrials(app)    
             % LoadProecessedDATA(app)
             % Load the first trial
             TriallistValueChanged(app)
             % DisplayROIShape(app)
        end
        
    end
    
       % App initialization and construction
        methods (Access = private)
            
            % Create UIFigure and components
            function createComponents(app)
                
                % Create UIFigure
                app.UIFigure = uifigure;
                app.UIFigure.Position = [100 30 200 451];
                app.UIFigure.Name = 'UI Figure';
                
                % Create LoadanewtrialLabel
                app.LoadanewtrialLabel = uilabel(app.UIFigure);
                app.LoadanewtrialLabel.HorizontalAlignment = 'center';
                app.LoadanewtrialLabel.FontWeight = 'bold';
                app.LoadanewtrialLabel.Position = [55 418 97 15];
                app.LoadanewtrialLabel.Text = 'Load a new trial';
                
                % Create triallist
                app.triallist = uilistbox(app.UIFigure);
                app.triallist.ValueChangedFcn = createCallbackFcn(app, @TriallistValueChanged, true);
                app.triallist.Position = [30 21 138 394];
                
            end
        end
        
        methods (Access = public)
            
            % Construct app
            function app = MotorTest
                
                % Create and configure components
                createComponents(app)
                
                % Register the app with App Designer
                registerApp(app, app.UIFigure)
                
                % Execute the startup function
                runStartupFcn(app, @startupFcn)
                
                if nargout == 0
                    clear app
                end
            end
            
            % Code that executes before app deletion
            function delete(app)
                
                % Delete UIFigure when app is deleted
                delete(app.UIFigure)
            end
        end
        
end


   