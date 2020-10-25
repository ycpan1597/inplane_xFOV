x = [0, 5, 5, 0];
y = [0, 0, 4, 0];
points = [x; y; ones(1, numel(x))];

rigid = @(theta, tx, ty) [cosd(theta) -sind(theta) tx; 
                          sind(theta) cosd(theta) ty; 
                          0 0 1];

scatter(0, 0, 50, 'DisplayName', 'Origin'); hold on                      
plot(points(1, :), points(2, :), '.-', 'Markersize', 10, 'DisplayName', 'Original');

theta = 30;
tx = 2;
ty = 1;

T1 = rigid(theta, tx, ty);
tformed_points = T1 * points;
plot(tformed_points(1, :), tformed_points(2, :), '.-', 'Markersize', 10, 'DisplayName', sprintf('theta = %d, tx = %d, ty = %d', theta, tx, ty));

xlim([-4, 10])
ylim([-4, 10])

theta_2 = 30;
tx_2 = 1;
ty_2 = 1;
T2 = rigid(theta_2, tx_2, ty_2);
tformed_points = T2*T1*points;
plot(tformed_points(1, :), tformed_points(2, :), '.-', 'Markersize', 10, 'DisplayName', sprintf('theta = %d, tx = %d, ty = %d', theta_2, tx_2, ty_2));
plot([points(1, 1), tformed_points(1, 1)], [points(2, 1), tformed_points(2, 1)], 'DisplayName', sprintf('distance = %.2f', norm(points(:, 1) - tformed_points(:, 1)))); hold off;
legend()

set(findall(gcf,'-property','FontSize'),'FontSize',18)
