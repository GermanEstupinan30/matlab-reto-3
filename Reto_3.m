%% ALGORITMO DE CONTROL Y CARGAS
% CONTROL AUTOMATIZADO DE RED HIBRIDA CON USO DE BATERIA Y DESCONEXION DE
% CARGAS

clc;
clear;
close all;

%% 1. CONFIGURACION INICIAL Y VECTORES (USADOS EN RETO 2)
horas = 1:24;

% GENERACION SOLAR (KW)
P_solar = [ ...            % Horas 1 a 5
    0 0 0 0 0 ...          % Horas 6 a 12
    3 8 14 19 22 24 25 ... % Horas 13 a 18
    24 21 17 12 6 2 ...    % Horas 19 a 24
    0 0 0 0 0 0];

% GENERACION EOLICA (KW)
P_eolica = [ ...
    7 9 6 8 5 10 12 9 ...
    11 8 13 10 7 12 14 9 ...
    11 8 6 10 13 7 5 9];

% GENERACION HIBRIDA TOTAL (KW)
P_total = P_solar + P_eolica;

% DEMANDA TOTAL DE LA COMUNIDAD (KW)
P_demanda = [ ...
    3 2 3 4 3 ...                 % Horas 1 a 5
    6 7 8 9 8 10 9 8 7 9 10 8 ... % Horas 6 a 17
    15 15 15 15 ...               % Horas 18 a 21
    4 3 2]; 

% PARAMETROS DE LA BATERIA
Capacidad_bat = 100; % Capacidad total en kWh
SOC = 50; % Carga inicial de seguridad en %

% VECTORES PARA ALMACENAR DATOS DE LA SIMULACION
SOC_historia = zeros(1, 24);
estado_escuela = cell(1, 24);
estado_bombeo = cell(1, 24);
estado_alumbrado = cell(1, 24);

%% 2. BUCLE DE SIMULACION Y LOGICA DE CONTROL (24 HORAS)
fprintf('==================================================================================\n');
fprintf('                           REPORTE DE CONTROL DE LA RED (SIGE)                    \n');
fprintf('==================================================================================\n');
fprintf('Hora | Gen(kW) | Dem(kW) | Balance(kW) | SOC(%%) | Escuela | Bombeo | Alumbrado \n'); 
fprintf('----------------------------------------------------------------------------------\n');

for t = 1:24
    E_gen = P_total(t);
    E_dem = P_demanda(t);
    balance = E_gen - E_dem;

    % EVALUACIÓN DE ESCENARIOS ENERGÉTICOS
    if balance >= 0
        % --- ESCENARIO DE SUPERÁVIT ---
        Excedente = balance;
        % Carga de la batería
        SOC = SOC + (Excedente / Capacidad_bat) * 100;

        % Límite máximo de seguridad de hardware (100%)
        if SOC > 100
            SOC = 100;
        end

        % Todos los servicios nominalmente activos
        escuela = 'ACTIVO';
        bombeo = 'ACTIVO';
        alumbrado = 'ACTIVO';

    else
        % --- ESCENARIO DE DÉFICIT ---
        Faltante = abs(balance);
        % Descarga de la batería
        SOC = SOC - (Faltante / Capacidad_bat) * 100;

        % Límite mínimo absoluto de seguridad (0%)
        if SOC < 0
            SOC = 0;
        end

        % PROTOCOLO DE PRIORIDAD DE CARGAS (LOAD SHEDDING)
        if SOC > 40
            % Ruta Segura: Capacidad suficiente
            escuela = 'ACTIVO';
            bombeo = 'ACTIVO';
            alumbrado = 'ACTIVO';

        elseif SOC > 20 && SOC <= 40
            % Ruta de Alerta: Desconexión de prioridad baja
            escuela = 'ACTIVO';
            bombeo = 'ACTIVO';
            alumbrado = 'SUSPENDIDO';

        else
            % Ruta de Emergencia (SOC <= 20%): Desconexión de prioridad media y baja
            escuela = 'ACTIVO';
            bombeo = 'SUSPENDIDO';
            alumbrado = 'SUSPENDIDO';
        end
    end

    % Guardar historial
    SOC_historia(t) = SOC;
    estado_escuela{t} = escuela;
    estado_bombeo{t} = bombeo;
    estado_alumbrado{t} = alumbrado;

    % Impresión por consola formatada hora a hora
    fprintf(' %02d  |  %5.1f  |  %5.1f  |   %+5.1f     |  %5.1f%% | %-9s | %-9s | %-9s\n', ...
        t, E_gen, E_dem, balance, SOC, escuela, bombeo, alumbrado);
end

fprintf('========================================================================================\n');

%% 3. GRÁFICA COMPLEMENTARIA DE SOC Y ESTADO DE BATERÍA
figure;
plot(horas, SOC_historia, '-ok', 'LineWidth', 2, 'MarkerFaceColor', 'b');
yline(40, '--r', 'Umbral Alerta (40%)', 'LineWidth', 1.5);
yline(20, '--m', 'Umbral Emergencia (20%)', 'LineWidth', 1.5);
title('Evolución del Estado de Carga de Batería (SOC) en 24 Horas');
xlabel('Hora del día');
ylabel('Estado de Carga - SOC (%)');
grid on;
ylim([0 105]);
xticks(1:24);