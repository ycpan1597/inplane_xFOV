function pos_vec = process_absolute_position(abs_pos)
    abs_pos = strsplit(abs_pos, ' ');
    abs_pos = cellfun(@(c) str2double(c), abs_pos); % convert all position from text to double
    
    pos_vec = zeros(length(abs_pos), 1);
    for i = 1:length(abs_pos)
        pos_vec(i) = abs_pos(i) - abs_pos(1);
    end
end

