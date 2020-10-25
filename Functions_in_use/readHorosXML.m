function data_struct = readHorosXML(pname, fname)
%
% XML annotation reader for Horos DICOM viewer software
% 
% by Oliver D. Kripfgans
% 2020 University of Michigan
%
% This is the first version
% There are bugs expected
% 
% The program organization is not textbook level
% The data should essentially be read by a hierarchical reader which this
% here is not.  But the present implementation may work for the current
% needs
%
%

% read Horos XML files re. ROIs and other annotations

% caseNo = 2;
% 
% switch caseNo
%     
%     case 1
%         fname = 'mult_roi.xml';
%         pname = '/Volumes/Simulation/2019 SUNSTAR Pig Study Infection/scripts/typestream/ROI/';
% 
% %     case 2
% %         fname = 'ROI_1month.xml';
% %         pname = '/Volumes/GoogleDrive/My Drive/DENTAL/2019 SUNSTAR Pig Study Infection/scripts/typestream/Tavelli/';
% 
% end


this_fid = fopen([pname, fname], 'rt');

if this_fid>2
    
    this_data = fread(this_fid, inf, '*char')';
    
    fclose(this_fid);
    
    
    %
    % %     this_data
    %     dictLevel = 1;
    %     % seek to 'dict'
    %     searchTerm = '<dict>';
    %     spointer = min(strfind(this_data,searchTerm));                                  %     this_text = this_data(spointer +(0:(numel(searchTerm)-1)))
    %
    %     % seek to 'key'
    %     searchTerm = '<key>';
    %     relPointer = min(strfind(this_data(spointer:end),searchTerm))-2;        %     this_text = this_data(relPointer+spointer +(0:(numel(searchTerm)-1)))
    %     searchTerm = [searchTerm(1), '/', searchTerm(2:end)];
    %     relPointer2 = min(strfind(this_data(spointer:end),searchTerm))-2;       %     this_text = this_data(relPointer+spointer +(0:(numel(searchTerm)-1)))
    %
    %     currentDict{dictLevel} = this_data(((relPointer+numel(searchTerm)):relPointer2)+spointer);
    %     eval(sprintf('data_struct.%s = [];', currentDict{dictLevel}));
    %
    %     % set search pointer
    %     spointer = spointer+relPointer2+1+numel(searchTerm);
    %
    %     % find first <array> item
    %     searchTerm = '<array>';
    %     relPointer = min(strfind(this_data(spointer:end),searchTerm))-1;        %     this_text = this_data(relPointer+spointer +(0:(numel(searchTerm)-1)))
    %
    %     this_data(((relPointer+numel(searchTerm)):relPointer2)+spointer)
    %
    % %     currentDict{dictLevel} =
    
    
    %
    %
    % FIRST find matching DICT tags
    %
    %
    searchTerm = '<dict>';
    dictOpen = strfind(this_data(1:end),searchTerm);
    searchTerm = '</dict>';
    dictClose = strfind(this_data(1:end),searchTerm);
    
    temp = dictOpen;
    dictOpen2Close = zeros(1, numel(dictOpen));
    for forClosure = 1:numel(dictClose) % the first one is for the overall data
        this_my_open = find(temp<dictClose(forClosure),1,'last');
        this_my_open = find(dictOpen==temp(this_my_open), 1, 'first');
        dictOpen2Close(forClosure) = this_my_open;
        temp = temp(temp~=dictOpen(this_my_open));
    end
    
    [level_rank_order, level_rank_index] = sort([dictOpen, dictClose]);
    
    level_rank_source = [ones(1, numel(dictOpen)), -ones(1, numel(dictOpen))];
    level_rank_source = level_rank_source(level_rank_index);
    
    level_rank = cumsum(level_rank_source);
    
    level_rank(level_rank_source==-1) = level_rank(level_rank_source==-1) + 1;
    
    openPos = level_rank_order(level_rank_source==1);
    openLevel = level_rank(level_rank_source==1);
    closePos = level_rank_order(level_rank_source==-1);
    %     closeLevel = level_rank(level_rank_source==-1);
    
    dictOpen2CloseReverse = 1:numel(closePos);
    dictOpen2CloseReverse(dictOpen2Close) = 1:numel(closePos);
    
    dictCloseReverse = dictClose(dictOpen2CloseReverse);
    
    
    keyFrameNumber = cumsum(openLevel==2);
    keyFrameNumberItem = (openLevel==3).*keyFrameNumber;
    keyFrameNumber = (openLevel==2).*keyFrameNumber;
    
    
    %
    %
    % SECOND find matching ARRAY tags
    %
    %
    
    searchTerm = '<array>';
    arrayOpen = strfind(this_data(1:end),searchTerm);
    searchTerm = '</array>';
    arrayClose = strfind(this_data(1:end),searchTerm);
    
    temp = arrayOpen;
    arrayOpen2Close = zeros(1, numel(arrayOpen));
    for forClosure = 1:numel(arrayClose) % the first one is for the overall data
        this_my_open = find(temp<arrayClose(forClosure),1,'last');
        this_my_open = find(arrayOpen==temp(this_my_open), 1, 'first');
        arrayOpen2Close(forClosure) = this_my_open;
        temp = temp(temp~=arrayOpen(this_my_open));
    end
    
%     [level_rank_order, level_rank_index] = sort([arrayOpen, arrayClose]);
    
%     level_rank_source = [ones(1, numel(arrayOpen)), -ones(1, numel(arrayOpen))];
%     level_rank_source = level_rank_source(level_rank_index);
    
%     level_rank = cumsum(level_rank_source);
    
%     level_rank(level_rank_source==-1) = level_rank(level_rank_source==-1) + 1;
    
%     openPosArray = level_rank_order(level_rank_source==1);
%     openLevelArray = level_rank(level_rank_source==1);
%     closePosArray = level_rank_order(level_rank_source==-1);
    %     closeLevel = level_rank(level_rank_source==-1);
    
%     arrayOpen2CloseReverse = 1:numel(closePosArray);
%     arrayOpen2CloseReverse(arrayOpen2Close) = 1:numel(closePosArray);
    
%     arrayCloseReverse = arrayClose(arrayOpen2CloseReverse);
    
    
    %     keyFrameNumber = cumsum(openLevel==2);
    %     keyFrameNumberItem = (openLevel==3).*keyFrameNumber;
    %     keyFrameNumber = (openLevel==2).*keyFrameNumber;
    
    %     [openLevel; openPos]'
    
    % create top level entry, i.e. level #1
    %
    this_level = 1;
    this_pos = openPos(openLevel==this_level);
    % find start of label
    this_search = '<key>';
    this_rel = strfind(this_data(this_pos+(0:50)), this_search);
    this_pos = this_pos+this_rel-1+numel(this_search);
    % find end of label
    this_search = '</key>';
    this_rel = strfind(this_data(this_pos+(0:50)), this_search);
    this_end = this_pos+this_rel-2;
    this_label = this_data(this_pos:this_end);
    top_label = this_label;
    % create top level entry
%     clc
    clear data_struct
    eval(sprintf('data_struct.%s = [];', this_label));
    
    % loop over all level #2 entries
    %
    this_level = 2;
    for qwe=find(openLevel==this_level) % 2, 5, 7, 11
        
%         this_pos = openPos(qwe);
        
        % find start of label
        this_search = '<key>';
        this_key_open = strfind(this_data(openPos(qwe):dictCloseReverse(qwe)), this_search);
        % find end of label
        this_search = '</key>';
        this_key_close = strfind(this_data(openPos(qwe):dictCloseReverse(qwe)), this_search);
        
        % go over each <key> at this level
        for sdf=1:numel(this_key_open)
            
            this_key_begin = openPos(qwe)+this_key_open(sdf)-2+numel(this_search);
            this_key_end = openPos(qwe)+this_key_close(sdf)-2;
            
            this_label = this_data(this_key_begin:this_key_end);
            
            temp_sub = this_data(this_key_end:end);
            this_label_type = this_data(  (this_key_end+max(find(temp_sub=='<',2,'first'))) :  (this_key_end+max(find(temp_sub=='>',2,'first'))-2)  );
            
            switch this_label_type
                    
                case 'integer'
                    this_label_value = str2double(this_data(  (this_key_end+max(find(temp_sub=='>',2,'first'))) :  (this_key_end+max(find(temp_sub=='<',3,'first'))-2)  ));
                    eval(sprintf('data_struct.%s(%d).%s = %d;', top_label, keyFrameNumber(qwe), this_label, this_label_value));
%                     fprintf(1, 'KL: %s = %d\n', this_label, this_label_value);
                    
                case 'array'
%                     temp_array_pos = find(openPosArray==(this_key_end+max(find(temp_sub=='<',2,'first'))-1));
                    
                    local_array_label = this_label;
                    local_array_index = 1;

                    % loop over all level #3 entries for this current level
                    %
%                     this_sublevel = 3;
                    for asd=find(keyFrameNumberItem==keyFrameNumber(qwe)) % 3 4
                        
                        % find end of this section
                        this_search = '<key>';
                        these_key_open = strfind(this_data(openPos(asd) : dictCloseReverse(asd)), this_search) - 1 + openPos(asd) + 0*numel(this_search);
                        this_search = '</key>';
                        these_key_close = strfind(this_data(openPos(asd) : dictCloseReverse(asd)), this_search) - 2 + openPos(asd) + numel(this_search);
                        
                        for zxc=1:numel(these_key_close)
                            
                            temp_sub = this_data(these_key_open(zxc):these_key_close(zxc));
                            key_label = this_data((min(strfind(temp_sub,'>'))+these_key_open(zxc)):(min(strfind(temp_sub,'</'))-2+these_key_open(zxc)));
                            
%                             fprintf(1, 'L: %s   ', key_label);
                            
                            % read and assign each value
                            %
                            value_base_pos = these_key_close(zxc)+1;
                            this_value_search = '<';
                            this_type_open = find(this_data(value_base_pos : end)==this_value_search, 1, 'first') + these_key_close(zxc) + 1;
                            this_value_search = '>';
                            this_type_close = find(this_data(value_base_pos : end)==this_value_search, 1, 'first') + these_key_close(zxc) - 1;
                            
                            this_type_label = this_data(this_type_open:this_type_close);
                            
                            switch this_type_label
                                case 'array/'
                                
                                case 'array'
                                    this_value_open = this_type_open  + numel(this_type_label) + 1;
                                    this_value_close = this_value_open + min(strfind(this_data(this_value_open:end), ['</' this_type_label])) - 2;
%                                     this_value = this_data(this_value_open : this_value_close);
                                    %                             fprintf(1, 'LT: <%s>  Array: %s   ', this_type_label, this_value);
                                    
                                    % find end of this section
                                    this_search_open = '<string>';
                                    these_array_string_open = strfind(this_data(this_value_open:this_value_close), this_search_open) - 1 + this_value_open + 0*numel(this_search_open);
                                    this_search_close = '</string>';
                                    these_array_string_close = strfind(this_data(this_value_open:this_value_close), this_search_close) - 2 +this_value_open + numel(this_search_close);
%                                     fprintf(1, '\n');
                                    for wer=1:numel(these_array_string_close)
                                        temp_string = this_data((these_array_string_open(wer)+numel(this_search_open)+1):(these_array_string_close(wer)-numel(this_search_open)-2));
                                        %                                 fprintf(1, 'Array(%d): [%s]\n', wer, temp_string);
                                        % store array entry
                                        eval(sprintf('data_struct.%s(%d).%s(%d).%s(%d,:) = [%s];', top_label, keyFrameNumber(qwe), local_array_label, local_array_index, key_label, wer, temp_string));
                                    end
                                    
                                case 'real'
                                    this_value_open = this_type_open  + numel(this_type_label) + 1;
                                    this_value_close = this_value_open + min(strfind(this_data(this_value_open:end), ['</' this_type_label])) - 2;
                                    this_value = this_data(this_value_open : this_value_close);
                                    this_value = str2double(this_value);
                                    eval(sprintf('data_struct.%s(%d).%s(%d).%s = %f;', top_label, keyFrameNumber(qwe), local_array_label, local_array_index, key_label, this_value));
                                    
                                case 'string'
                                    this_value_open = this_type_open  + numel(this_type_label) + 1;
                                    this_value_close = this_value_open + min(strfind(this_data(this_value_open:end), ['</' this_type_label])) - 2;
                                    this_value = this_data(this_value_open : this_value_close);
                                    eval(sprintf('data_struct.%s(%d).%s(%d).%s = ''%s'';', top_label, keyFrameNumber(qwe), local_array_label, local_array_index, key_label, this_value));
                                    
                                case 'integer'
                                    this_value_open = this_type_open  + numel(this_type_label) + 1;
                                    this_value_close = this_value_open + min(strfind(this_data(this_value_open:end), ['</' this_type_label])) - 2;
                                    this_value = this_data(this_value_open : this_value_close);
                                    this_value = str2double(this_value);
                                    eval(sprintf('data_struct.%s(%d).%s(%d).%s = %d;', top_label, keyFrameNumber(qwe), local_array_label, local_array_index, key_label, this_value));
                                    
                                otherwise
                                    fprintf(2, 'LT: Unknown label type  ');
                            end
%                             fprintf(1, '\n');
                        end
                        
                        local_array_index = local_array_index + 1;
    
                    end
                    
                    break
                    
                otherwise
                    fprintf(2, 'LT: Unknown label type');
            end
        end
        
    end
    
else
    
    fprintf(2, 'Cannot open xml file!\n');

    data_struct = [];
    
end





































































