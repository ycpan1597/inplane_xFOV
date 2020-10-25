with = load('xforms_with_padding_short.mat');
without = load('xforms_without_padding_short.mat');

% with = load('xforms_with_padding.mat');
% without = load('xforms_without_padding.mat');

with = with.attr;
without = without.attr;

%%
diff_norm = zeros(numel(with.differences), 1);
figure(1); clf;
axis([0, 10, 0, 10])
for i = 1:numel(diff_norm)
    diff_norm(i) = norm(with.all_xforms{i}.T - without.all_xforms{i}.T, 'fro') / norm(without.all_xforms{i}.T, 'fro');
end

plot(diff_norm)
xlabel('Frame number')
ylabel('Normalized difference in pairwise registration matrix')
set(findall(gcf,'-property','FontSize'),'FontSize',16)

figure(2); clf
plot(with.angs); hold on
plot(without.angs); hold off
xlabel('Frame number')
ylabel('Cumulative angular displacement in deg')
legend('With padding', 'Without padding')
set(findall(gcf,'-property','FontSize'),'FontSize',16)

figure(3); clf
plot(with.cur_angs); hold on; 
plot(without.cur_angs); hold off;
xlabel('Frame number')
ylabel('Pairwise angular displacement in deg')
legend('With padding', 'Without padding')
set(findall(gcf,'-property','FontSize'),'FontSize',16)
