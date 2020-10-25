function output_vector = pad_position_vector_with_zeros(abs_pos, slice_thickness)
    % Need to take slice_thickness into consideration to ensure that we
    % have the flexibility to make stacks of different elevational
    % resolution
    full_range = min(abs_pos): slice_thickness: max(abs_pos); % This is in mm
    output_vector = zeros(length(full_range), 1);
    start_idx = 1;
    for i = 1:length(full_range)
        if ismember(full_range(i), abs_pos)
            output_vector(i) = start_idx;
            start_idx = start_idx + 1; 
        else
            output_vector(i) = 0;
        end
    end
end