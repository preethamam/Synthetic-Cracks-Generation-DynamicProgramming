classdef waitbarParfor < handle
	%This class creates a waitbar or message when using for or parfor.
	%Required Input:
	%TotalMessage: N in "i = 1: N".
	%Optional Inputs:
	%'Waitbar': true of false (default). If true, this class creates a
	%               waitbar.
	%'FileName': 'screen' or a char array. If 'screen', print the message
	%               on screen; otherwise, save the message in the file
	%               named 'FileName'.
	%'ReportInterval': 1x1. Report at every i is costly. This number
	%                defines the interval for reporting. 
	%%To use this class, one needs to call the class right before the loop:
	%N = 1000;
	%WaitMessage = waitbarParfor(N);
	%%Call "Send" method in the loop. 
	%for i = 1: N
	%   WaitMessage.Send;
	%   pause(0.5);
	%end
	%%Delete the obj after the loop.
	%WaitMessage.Destroy;
	%Copyright (c) 2019, Yun Pu
	properties (SetAccess = private)
		NumMessage; %Number of messages received from the workers.
		TotalMessage; %Number of total messages.
		Waitbar; %If waitbar is true, create a waitbar; otherwise, save the message in a file.
		FileName; %If FileName = 'screen', the current message does not save in a file.
		StartTime
		UsedTime_1; %Time at last step.
		% WaitbarHandle;
		ReportInterval;
		FileID;
		DataQueueHandle;
		WaitbarID
		WaitbarTag
	end

	methods
		function Obj = waitbarParfor(TotalMessage, varargin)
			Obj.DataQueueHandle = parallel.pool.DataQueue;
			Obj.StartTime = tic;
			Obj.NumMessage = 0;
			Obj.UsedTime_1 = Obj.StartTime;
			Obj.TotalMessage = TotalMessage;
			InParser = inputParser;
			addParameter(InParser,'Waitbar', false, @islogical);
			addParameter(InParser,'FileName', 'screen', @ischar);
			addParameter(InParser,'ReportInterval', ceil(TotalMessage/100), @isnumeric);
			parse(InParser, varargin{:})
			Obj.Waitbar = InParser.Results.Waitbar;
			Obj.FileName = InParser.Results.FileName;
			Obj.ReportInterval = InParser.Results.ReportInterval;
			if Obj.Waitbar
				% Obj.WaitbarHandle = waitbar(0, [num2str(0), '%'], 'Resize', true);
				Obj.WaitbarTag = matlab.lang.makeValidName(['Progress_', char(java.util.UUID.randomUUID())]);
				h = waitbar(0, '0%', 'Resize', true);
				h.Tag = Obj.WaitbarTag;
				setappdata(0, Obj.WaitbarTag, h);	% Store handle globally or in persistent scope
				Obj.WaitbarID = Obj.WaitbarTag;
			end
			switch Obj.FileName
				case 'screen'
				otherwise
					Obj.FileID = fopen(Obj.FileName, 'w');     
			end       
			afterEach(Obj.DataQueueHandle, @Obj.Update);
		end

		function Send(Obj)
			send(Obj.DataQueueHandle, 0);
		end

		function Destroy(Obj)
			if Obj.Waitbar
				% delete(Obj.WaitbarHandle);
				h = getappdata(0, Obj.WaitbarID);
				if ~isempty(h) && isvalid(h)
					delete(h);
					rmappdata(0, Obj.WaitbarID);
				end
			end
			delete(Obj.DataQueueHandle);
			delete(Obj);
		end
	end
   
	methods (Access = private)
		function Obj = Update(Obj, ~)
			Obj.AddOne;
			if mod(Obj.NumMessage, Obj.ReportInterval)
				return
			end
			if Obj.Waitbar             
				Obj.WaitbarUpdate;
			else
				Obj.FileUpdate;
			end
		end

		function WaitbarUpdate(Obj)
			UsedTime_now = toc(Obj.StartTime);
			EstimatedTimeNeeded = (UsedTime_now-Obj.UsedTime_1)/Obj.ReportInterval*(Obj.TotalMessage-Obj.NumMessage);
			% waitbar(Obj.NumMessage/Obj.TotalMessage, Obj.WaitbarHandle, [num2str(Obj.NumMessage/Obj.TotalMessage*100, '%.2f'), '%; ', num2str(UsedTime_now, '%.2f'), 's used and ', num2str(EstimatedTimeNeeded, '%.2f'), 's needed.']);
			h = getappdata(0, Obj.WaitbarID);
			if ~isempty(h) && isvalid(h)
				waitbar(Obj.NumMessage/Obj.TotalMessage, h, sprintf('%1$.2f%% \nElapsed: %2$s. ETA: %3$s.', ...
					Obj.NumMessage/Obj.TotalMessage*100, duration(0,0,UsedTime_now), duration(0,0,EstimatedTimeNeeded)));
			end
			Obj.UsedTime_1 = UsedTime_now;
		end

		function FileUpdate(Obj)
			UsedTime_now = toc(Obj.StartTime);
			EstimatedTimeNeeded = (UsedTime_now-Obj.UsedTime_1)/Obj.ReportInterval*(Obj.TotalMessage-Obj.NumMessage);           
			switch Obj.FileName
				case 'screen'
					fprintf('%.2f%%; Elapsed: %s. ETA: %s.\n', Obj.NumMessage/Obj.TotalMessage*100, ...
						duration(0,0,UsedTime_now), duration(0,0,EstimatedTimeNeeded));
				otherwise
					fprintf(Obj.FileID, '%.2f%%; Elapsed: %s. ETA: %s.\n', Obj.NumMessage/Obj.TotalMessage*100, ...
						duration(0,0,UsedTime_now), duration(0,0,EstimatedTimeNeeded));
			end
			Obj.UsedTime_1 = UsedTime_now;
		end

		function AddOne(Obj)
			Obj.NumMessage = Obj.NumMessage + 1;
		end      
	end
end