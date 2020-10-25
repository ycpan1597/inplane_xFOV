% compile measurements from all slices together to make a composite bland-altman plot:
close all
width_meas_dir = '/Users/preston/MATLAB-Drive/Width_measurements';
dic = [205; 210; 215; 220];
US_all = [];
CT_all = [];
cd(width_meas_dir);
for i = 1:length(dic)
    US_cur = load(sprintf('%d_US_estimates.mat', dic(i)));
    CT_cur = load(sprintf('%d_CT_estimates.mat', dic(i)));
    US_all = [US_all; US_cur.US_estimates];
    CT_all = [CT_all; CT_cur.CT_estimates];
end
cd ..

[rpc1, fig1] = BlandAltman(US_all(:, 1), CT_all(:, 1), {'US', 'CT', 'mm'}, 'Comparison between US and CT (across all slices - 1st set)', {'Bone width'}, 'baInfo', {'SD' , 'RPC(%)'});
[rpc2, fig2] = BlandAltman(US_all(:, 2), CT_all(:, 2), {'US', 'CT', 'mm'}, 'Comparison between US and CT (across all slices - 2nd set)', {'Bone width'}, 'baInfo', {'SD' , 'RPC(%)'});
[rpc3, fig3] = BlandAltman(US_all(:, 1), US_all(:, 2), {'US_1', 'US_2', 'mm'}, 'Comparison between 1st and 2nd US across all slices (By Preston)', {'Bone width'}, 'baInfo', {'SD' , 'RPC(%)'});
[rpc4, fig4] = BlandAltman(CT_all(:, 1), CT_all(:, 2), {'CT_1', 'CT_2', 'mm'}, 'Comparison between 1st and 2nd CT across all slices (By Preston)', {'Bone width'}, 'baInfo', {'SD' , 'RPC(%)'});

% combine replicates together to double the sample size
[rpc5, fig5] = BlandAltman([US_all(:, 1); US_all(:, 2)], [CT_all(:, 1); CT_all(:, 2)], {'US', 'CT', 'mm'}, 'Comparison between US and CT (both sets combined)', {'Bone width'}, 'baInfo', {'SD' , 'RPC(%)'});

fig1.Position=[0.0475, 0.0759, 0.6, 0.4];
fig2.Position=[0.0475, 0.0759, 0.6, 0.4];
fig3.Position=[0.0475, 0.0759, 0.6, 0.4];
fig4.Position=[0.0475, 0.0759, 0.6, 0.4];
fig5.Position=[0.0475, 0.0759, 0.6, 0.4];

file_type = 'png'; % or svg
plot_directory = './Bland_Altman_Plots';
saveas(fig1, fullfile(plot_directory, sprintf('Composite_CT_US_1.%s', file_type)));
saveas(fig2, fullfile(plot_directory, sprintf('Composite_CT_US_2.%s', file_type)));
saveas(fig3, fullfile(plot_directory, sprintf('Composite_US_US.%s', file_type)));
saveas(fig4, fullfile(plot_directory, sprintf('Composite_CT_CT.%s', file_type)));