function [stack, data] = get_features_GPL_CMJ(a, fs, plt)
g = 9.80665;

a_filt = bwfilt(a, 6, fs, 50, 'low');
%a_filt = bwfilt(a_filt1, 6, fs, 0.1, 'high');

% -- VMD Parameters -- %
alpha = 100;        % Mid Bandwidth Constrain  
tau = 0;            % Noise-tolerance (no strict fidelity enforcement)  
K = 3;              % 3 IMFs  
DC = 0;             % DC part not imposed  
init = 0;           % Initialize omegas uniformly  
tol = 1e-6;        % Tolerance parameter

[u, u_hat, omega] = vmdLegacy(a, alpha, tau, K, DC, init, tol);

[u0, u_hat0, info] = vmd(a, ...
                         NumIMFs = K, ...
                         InitializeMethod = 'grid'); 


cf = omega(end,:) * fs/2;
f3 = cf(1); f2 = cf(2); f1 = cf(3);

% t_0
% 2. Unweighting Phase 
thr_t0 = 8 * std(a_filt(1 : fs/2));
for k = 1 : length(a) - 1
    if ( -a_filt(k) > thr_t0 )
        t_0 = k - round(0.03 * fs);
        break
    end
end

% Compute Velocity from "onset"
t = linspace(0, (length(a) - t_0) / fs, length(a) - t_0);
vt = cumtrapz(t, a(t_0 : end - 1));
% fill v with zeros to match a shape
v = [zeros(t_0,1); vt];

% The end of (U) occurs when, after the Onset, the BW > 0 <==> a > 0 <==>
% <==> v is at local minimum

%%for ss = t_0 + 30 : length(v) - 1
%%    if v(ss) > v(ss+1)
%%      t_UB = ss + 30 - 1;
%%      break
%%    endif
%%end

% Add condition avoiding drift-related errors. It could happen that, when the 
% integral drifts towards the end due to numerical errors/subject not landing 
% on the FP properly, that the maximum velocity is reached way too late. 
% The idea is to bound the computation of maximum to the minimum velocity value,
% which occurs briefly after the landing instant.

[~, stop_smpl] = min(v);
[~, vM] = max(v( 1 : stop_smpl ));
[~, vm] = min(v( t_0 : vM));
t_UB = vm + t_0 - 1;
if isempty(t_UB)
    if 2*stop_smpl <length(v)
    [~, t_UB] = min(v( t_0 : 2*stop_smpl));
    t_UB=t_UB+t_0-1;
    else
    [~, t_UB] = min(v( t_0 : end-stop_smpl));
    t_UB=t_UB+t_0-1;
    end
end 
flag_negv=false;
if round(v(vM),2) == v(t_0)
    [~, maxA] = max(a);
    [~, minA] = min(a(1:maxA));
    flag_negv=true;
    for i=minA:maxA
        if a(i)>0
            t_UB=i;
            break;
        end
    end
end        
% 3. Breaking Phase
% Find the first sample such that v > 0
for k = t_UB : length(a)
    if v(k) > 0.001
        t_BP = k;
        break
    end
end

if flag_negv
    for i=maxA:length(a)
        if a(i)< -g
            t_BP=maxA;
            t_TO=i;
            break;
        end
    end
end


% 4. Propulsion Phase
% From BP to "end", find the first k : a[k] < -g
flag = false;
if flag_negv == false
for k = t_BP : length(a)
    if a(k) <= -g
        t_TO = k;
        flag = true;
        break
    end
end

if flag == false
   [~, vm] = max(v);
   [~, am] = min(a(vm:vm+30))
   t_TO = vm + am - 1;
   flag = true;
end
end
% Power
cnt = 1;
for k = t_0 : t_TO
    P_tmp(cnt,1) = (a(k) + g) * v(k);
    cnt = cnt + 1;
end
P = [zeros(t_0,1); P_tmp];

% Height
h = .5 * v(t_TO)^2 / g;

display(['t_0 = ' num2str(t_0) ...
         '; t_UB = ' num2str(t_UB) ...
         '; t_BP = ' num2str(t_BP) ...
         '; t_TO = ' num2str(t_TO)]);


%% Jump Features
% -- A -- %
A = (t_UB - t_0) / fs;

% -- b -- %
b = min(a(t_0 : t_BP));

% -- C -- %
[~, a_min] = min(a(t_0 : t_BP));
[~, a_max] = max(a(t_0 : t_TO));
C = (a_max - a_min) / fs;

% -- D -- %
% for k = t_UB : t_TO
%     if a(k) < 0
%         F_0 = k - 1;
%         break
%     end
% end
% D = (F_0 - t_UB) / fs;
for k = t_TO : -1 : t_UB
    if a(k) >= 0
        F_0 = k + 1;
        break
    end
end
D = (F_0 - t_UB) / fs;


% -- e -- %
e = max(a(t_0 : t_TO));

% -- F -- %
F = (t_TO - a_max) / fs;

% -- G -- %
G = (t_TO - t_0) / fs;

% -- H -- %
H = (t_BP - a_min) / fs;

% -- i -- %
tilt = diff(a(a_min : a_max + 1));
[~, tilt_max] = max(tilt);
i = a(t_0 + a_min + tilt_max);

% -- J -- %
[~, v_min] = min(v(1 : t_BP));
J = (t_BP - v_min) / fs;

% -- k -- %
k1 = a(t_BP);

% -- l -- %
l = min(P(t_UB : t_BP));

% -- M -- %
flag = false;
for k = t_BP + 3 : length(P)
    if P(k) < 0
        P_0 = k-1;
        flag = true;
        break
    end
end
% Correct for too much wiphlash
if flag == false
    P_0 = length(P);
end
M = (P_0 - t_BP) / fs;

% -- n -- %
n = max(P);

% -- O -- %
[~, P_max] = max(P);
O = (t_TO - P_max) / fs;

% -- p -- %
p = (e - b) / C;

% -- q -- %
time = linspace(0, (F_0 - t_UB) / fs, (F_0 - t_UB));
shape = trapz(time, a(t_UB : F_0 - 1));
q = shape / (D * e);

% -- r -- %
r = b / e; 

% -- s -- %
[~, v_max] = max(v);
s = min(v(1 : v_max));

% -- z -- %
z = mean(P(t_0 : t_BP));

% -- u -- %
u = mean(P(t_BP : t_TO));

% -- W -- %
[~, P_min] = min(P(1 : P_max));
W = (P_max - P_min) / fs;


% Table
header = {'h', 'A', 'b', 'C', 'D', 'e', 'F', 'G', 'H', 'i', 'J', 'k', 'l', 'M',...
    'n', 'O', 'p', 'q', 'r', 's', 'u', 'W', 'z', 'f3', 'f2', 'f1'};

stack = [round(100* h), A, b, C, D, e, F, G, H, i, J, k1, l, M, ...
    n, O, p, q, r, s, u, W, z, f3, f2, f1];

% T = array2table(stack, 'VariableNames', header);
data.a_glob=a;
data.vert_v= v;
data.t_0=t_0;
data.t_UB=t_UB;
data.t_BP=t_BP;
data.t_TO= t_TO;
data.features=array2table(stack, 'VariableNames', header);

if plt == 1
    figure
    plot(a); hold; 
    plot(t_0, a(t_0), '*r');
    plot(t_UB, a(t_UB), '*r'); 
    plot(t_BP, a(t_BP), '*r');
    plot(t_TO, a(t_TO), '*r');
    title('Transition timings - acc');

    figure
    plot(v); hold; 
    plot(t_0, v(t_0), '*r');
    plot(t_UB, v(t_UB), '*r'); 
    plot(t_BP, v(t_BP), '*r');
    plot(t_TO, v(t_TO), '*r');
    title('Transition timings - vel');
end
end