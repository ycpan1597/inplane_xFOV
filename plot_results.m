fn = '/Volumes/GoogleDrive/My Drive/2016-08-28 ex vivo pig no 1-2-3-4-5/2019-09-18 inplane xFOV/US_vs_CBCT_measurements.xlsx';

% sheets = {'Pig 1R', 'Pig 1L', 'Pig 3R', 'Pig 3L', 'Pig 4R', 'Pig 4L'};
sheets = {'Pig 1R', 'Pig 1L', 'Pig 3R', 'Pig 3L', 'Pig 4R redo', 'Pig 4L redo'};
data = [];

bone_loss_boolean = [];
colors = {'r', 'r', 'm', 'm', 'g', 'g', 'b', 'b'};
% colors = {'r', 'b', 'r', 'b', 'r', 'b'};
% colors = {'r', 'g', 'r', 'g'};
for i = 1:length(sheets)
    m = readmatrix(fn, 'Sheet', sheets{i});
    data = [data; m(:, 2:4)];
    bone_loss_boolean = [bone_loss_boolean; m(:, 6)];
    
    US = m(:, 2);
    CBCT = m(:, 4);
    scatter((US + CBCT)/2, (CBCT - US), 50, colors{i}, 'filled', 'DisplayName', sheets{i}); hold on
%     yline(mean(CBCT - US), strcat(colors{i}, '--'), 'DisplayName', strcat(sheets{i}, ' bias'))
%     scatter((US_with_bone_loss + CBCT_with_bone_loss)/2, (CBCT_with_bone_loss - US_with_bone_loss), 100);
end
hold off;
yline(0, '--', '0 mm')
xlabel('(CBCT + US)/2 (mm)');
ylabel('CBCT - US (mm)');
legend();
set(findall(gcf,'-property','FontSize'),'FontSize',15)
%%
US = data(:, 1);
CBCT = data(:, 3);

US_with_bone_loss = data(bone_loss_boolean == 1, 1);
CBCT_with_bone_loss = data(bone_loss_boolean == 1, 3);
[rpc3, fig3] = BlandAltman(data(:, 1), data(:, 3), {'US_1', 'CT_1', 'mm'}, 'Comparison between 1st US (Pan) and CT (Soki) across all slices', {'Bone width'}, 'baInfo', {'SD' , 'RPC(%)'});

figure(4);
clf;
scatter((US + CBCT)/2, (CBCT - US), 50, 'filled'); hold on
scatter((US_with_bone_loss + CBCT_with_bone_loss)/2, (CBCT_with_bone_loss - US_with_bone_loss), 100);
yline(mean(CBCT - US), '--', sprintf('Mean difference = %.2f mm', mean(CBCT - US)));  hold off
xlabel('(CBCT + US)/2 (mm)');
ylabel('CBCT - US (mm)');
legend({'All slices', 'Slices with bone loss'});
set(findall(gcf,'-property','FontSize'),'FontSize',15)
% [rpc3, fig3] = BlandAltman(data(:, 3), data(:, 4), {'CT_1', 'CT_2', 'mm'}, 'Comparison between 1st and and 2nd CT across all slices (By Preston)', {'Bone width'}, 'baInfo', {'SD' , 'RPC(%)'});
% [rpc3, fig3] = BlandAltman(data(:, 1), data(:, 2), {'US_1', 'US_2', 'mm'}, 'Comparison between 1st and 2nd US across all slices (By Preston)', {'Bone width'}, 'baInfo', {'SD' , 'RPC(%)'});