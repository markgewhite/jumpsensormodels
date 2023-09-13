function a_glob = do_align_v2(acc, gyr, fs, auto)
        
        AHRS = MadgwickAHRS();
        AHRS.Beta = 0.001; AHRS.SamplePeriod = 1 / fs;
        
        % -- Correct for WRF alignemnt -- %
        time = linspace(0, length(acc) / fs, length(acc));
        quaternion = zeros(length(time), 4);
        
        for t = 1 : length(time)
            AHRS.UpdateIMU(gyr(t,:), acc(t,:));
            quaternion(t, :) = AHRS.Quaternion;
        end
        
        quaternion_star = quaternConj(quaternion);
        a_q = [zeros(length(acc),1), acc];
        a_temp = quaternProd(quaternion, a_q);
        a_glob = quaternProd(a_temp, quaternion_star);
        
        if auto == 1
            
            offset = mean(a_glob(1:fs,2:end));
            a_glob = a_glob(:,2:end) - offset;

        elseif auto == 0
            
            figure;
            plot(a_glob(:, 2:end));
            title('Select the static window in which the offset is computed')
            [x, ~] = ginput(2);
            close
            x = round(x);

            offset = mean(a_glob(x(1) : x(2), 2 : end));
            a_glob = a_glob(:, 2 : end) - offset;

        else
            display('You should enter either 1 or 0.')
        end
        
end