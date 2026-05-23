%% EV Drive Cycle Results Analysis
% Run this script after simulation completes in Simulink

clc;

%% Extract simulation outputs
t = out.tout;
net_power = out.net_power_out.Data;

% Match lengths
min_len = min(length(t), length(net_power));
t = t(1:min_len);
net_power = net_power(1:min_len);

% Separate motor and regen power
P_motor = max(net_power, 0);     % positive = consuming from battery
P_regen = max(-net_power, 0);    % negative = returning to battery

%% Energy Calculations
E_consumed  = trapz(t, P_motor) / 3600;   % Wh
E_recovered = trapz(t, P_regen) / 3600;   % Wh
E_net       = E_consumed - E_recovered;    % Wh

%% Distance and Efficiency
min_len2    = min(length(t), length(speed_ms));
distance_km = trapz(t(1:min_len2), speed_ms(1:min_len2)) / 1000;
efficiency  = E_net / distance_km;         % Wh/km
regen_pct   = (E_recovered / E_consumed) * 100;

%% Range Estimate
battery_Wh = 50 * 360;                    % 50Ah x 360V = 18000 Wh
range_km   = battery_Wh / efficiency;

%% SoC Calculation
battery_J      = battery_Wh * 3600;
energy_used_J  = cumtrapz(t, net_power);
SoC_corrected  = 1 - (energy_used_J / battery_J);
SoC_corrected  = max(min(SoC_corrected, 1), 0);

%% Print Results
fprintf('========================================\n');
fprintf('   HWFET EV Drive Cycle Simulation\n');
fprintf('========================================\n');
fprintf('Distance Simulated  : %.2f km\n',  distance_km);
fprintf('Energy Consumed     : %.1f Wh\n',  E_consumed);
fprintf('Energy Recovered    : %.1f Wh\n',  E_recovered);
fprintf('Regen Recovery      : %.1f%%\n',   regen_pct);
fprintf('Efficiency          : %.1f Wh/km\n', efficiency);
fprintf('Estimated Range     : %.0f km\n',  range_km);
fprintf('SoC Start           : 100%%\n');
fprintf('SoC End             : %.1f%%\n',   SoC_corrected(end)*100);
fprintf('SoC Drop            : %.1f%%\n',   (1-SoC_corrected(end))*100);
fprintf('========================================\n');

%% Plot 1 — Drive Cycle Speed Profile
figure(1); clf;
plot(t(1:min_len2), speed_ms(1:min_len2)*3.6, 'b', 'LineWidth', 1.5);
title('HWFET Drive Cycle Speed Profile');
xlabel('Time (s)'); ylabel('Speed (km/h)');
xlim([0 765]); grid on;
saveas(gcf, 'results/speed_profile.png');

%% Plot 2 — Battery SoC
figure(2); clf;
plot(t, SoC_corrected, 'r', 'LineWidth', 1.5);
title('Battery State of Charge - HWFET Cycle');
xlabel('Time (s)'); ylabel('SoC (0 to 1)');
xlim([0 765]); ylim([0.97 1.0]);
grid on;
saveas(gcf, 'results/SoC_profile.png');

%% Plot 3 — Motor vs Regen Power
figure(3); clf;
plot(t, P_motor/1000, 'g', 'LineWidth', 1.5); hold on;
plot(t, P_regen/1000, 'b', 'LineWidth', 1.5);
legend('Motor Power (kW)', 'Regen Power (kW)');
title('Motor and Regenerative Braking Power');
xlabel('Time (s)'); ylabel('Power (kW)');
xlim([0 765]); grid on;
saveas(gcf, 'results/power_profile.png');

%% Plot 4 — Energy Summary Bar Chart
figure(4); clf;
bar([E_consumed, E_recovered, E_net], 0.5, ...
    'FaceColor', [0.2 0.6 0.8]);
set(gca, 'XTickLabel', {'Consumed (Wh)', 'Recovered (Wh)', 'Net (Wh)'});
title('Energy Summary - HWFET Cycle');
ylabel('Energy (Wh)');
grid on;
saveas(gcf, 'results/energy_summary.png');

fprintf('All plots saved to /results folder.\n');