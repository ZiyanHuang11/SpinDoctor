classdef DoublePGSE < Sequence
    %DOUBLEPGSE Double Pulsed Gradient Spin Echo sequence.
    %   This sequence consists of two PGSE sequences without a pause between
    %   them. Each of the two PGSE sequences consists of two opposite pulses of
    %   duration delta, separated by a pause of duration Delta - delta.
    %   An initial pause and a fixed echo time can be set through optional
    %   Sequence parameters. Adding specified pauses at each end is not
    %   supported.
    
    properties
        tpause
    end
    
    methods
        function obj = DoublePGSE(delta, Delta, varargin)
            %DoublePGSE Construct an instance of the DoublePGSE class.
            % varargin = tpause, optional arguments for indvidual PGSE
            %   `tpause` is the pause between the two PGSE sequences.
            if nargin ==2
                tpause = 0;
                varargin = {0};
            else 
                tpause = varargin{1};   
            end
            assert(tpause >= 0);
            obj.tpause = tpause;
            if length(varargin) == 1
                  obj.t1 = 0;  
                  obj.TE = obj.echotime;
            elseif length(varargin) == 2
                obj.TE = varargin{2};
                obj.t1 = 0;
            elseif length(varargin) == 3
                if isnumeric(varargin{3})
                    obj.t1 = varargin{2};
                    obj.TE = obj.echotime;
                elseif varargin{3} == "Symmetric" || varargin{3} == "symmetric" 
                    obj.TE = varargin{2};
                    obj.t1 = (obj.TE - 2 * (Delta + delta) - obj.tpause)/2;
                else
                    error("Error: invalid input into Sequence")
                end
            else
                error("Error: invalid input into Sequence")
            end
            
        end
        
        function TE = echotime(obj)
            %ECHOTIME Get the echo time of the DoublePGSE sequence.
            %   The echo time is twice the normal echo time.
            TE = obj.t1 + 2 * obj.Delta + 2 * obj.delta + obj.tpause;
        end
        
        function f = call(obj, t)
            %CALL Call the DoublePGSE time profile at time t.
            %   The function is vectorized.
            d = obj.delta;
            D = obj.Delta;
            p = obj.tpause;
            t = t-obj.t1;
            f = (0 <= t & t < d) ...
                - (D <= t & t < D + d) ...
                + (p + D + d <= t & t < p + D + 2 * d) ...
                - (p + 2 * D + d <= t & t <= p + 2 * D + 2 * d);
        end
        
        function F = integral(obj, t)
            %INTEGRAL Compute the integral of the time profile from 0 to t.
            %   For the DoublePGSE sequence, an analytical expression is
            %   available.
            d = obj.delta;
            D = obj.Delta;
            p = obj.tpause;
            t = t-obj.t1;
            F = (0 <= t & t < d) .* t ...
                + (d <= t & t < D + d) .* d ...
                - (D <= t & t < D + d) .* (t - D) ...
                + (p + D + d <= t & t < p + D + 2 * d) .* (t - (p + D + d)) ...
                + (p + D + 2 * d <= t & t <= p + 2 * D + 2 * d) .* d ...
                - (p + 2 * D + d <= t & t <= p + 2 * D + 2 * d) .* (t - (p + 2 * D + d));
        end
        
        function int = integral_F2(obj)
            %INTEGRAL_F2 Compute the temporal integration of F^2 (F = integral(obj, t)).
            %   An analytical expression is available for the DoublePGSE sequence.
            int = 2 * obj.delta^2 * (obj.Delta - obj.delta / 3);
        end
        
        function t = diffusion_time(obj)
            %DIFFUSION_TIME Get diffusion time of the DoublePGSE sequence.
            t = 2 * (obj.Delta - obj.delta / 3);
        end
        
        function t = diffusion_time_sta(obj)
            %DIFFUSION_TIME_STA Get STA diffusion time of the DoublePGSE sequence.
            d = obj.delta;
            D = obj.Delta;
            tm = obj.delta + obj.tpause;
            out = (2 / 35) * ( ...
                        + (2*D + tm + d)^(7 / 2) ...
                        + (2*D + tm - d)^(7 / 2) ...
                        + (tm + d)^(7 / 2) ...
                        + (tm - d)^(7 / 2) ...
                        - 2 * (2*D + tm)^(7 / 2) ...
                        - 2 * (D + tm + d)^(7 / 2) ...
                        - 2 * (D + tm - d)^(7 / 2) ...
                        + 2 * (D + d)^(7 / 2) ...
                        + 2 * (D - d)^(7 / 2) ...
                        - 2 * tm^(7 / 2) ...
                        + 4 * (D + tm)^(7 / 2) ...
                        - 4 * D^(7 / 2) ...
                        - 4 * d^(7 / 2) ...
                    ) / (d^2 * (D - d/3));
            t = out^2;
        end
        
        function jn = J(obj, lambda)
            %J Compute the quantity J(lambda) for the sequence
            %   An analytical expression is available for the DoublePGSE sequence
            d = obj.delta;
            D = obj.Delta;
            tm = obj.tpause + obj.delta;
            
            if lambda < 1e-7
                % Use Taylor expansion when lambda is close to 0 
                % to improve numerical stability
                jn = lambda ...
                    - lambda^2 * 3 * D^2 / (3*D - d) ...
                    + lambda^3 * (40*D^3 + 5*D*d^2 - d^3 + 30*D^2*tm) / (20 * (3*D - d)) ...
                    - lambda^4 * (4*D^4 + D^2*d^2 + 6*D^3*tm + 3*D^2*tm^2) / (4 * (3*D - d)) ...
                    + lambda^5 * (336*D^5 + 140*D^3*d^2 + 7*D*d^4 - d^5 + 735*D^4*tm ...
                        + 105*D^2*d^2*tm + 630*D^3*tm^2 + 210*D^2*tm^3) / (840 * (3*D - d));
            else
                jn = - 1 * ( ...
                    + exp(-lambda * (2*D + tm - d)) ...
                    + exp(-lambda * (2*D + tm + d)) ...
                    + exp(-lambda * (tm - d)) ...
                    + exp(-lambda * (tm + d)) ...
                    - 2 * exp(-lambda * (D + tm - d)) ...
                    - 2 * exp(-lambda * (D + tm + d)) ...
                    - 2 * exp(-lambda * (2*D + tm)) ...
                    + 2 * exp(-lambda * (D - d)) ...
                    + 2 * exp(-lambda * (D + d)) ...
                    - 2 * exp(-lambda * tm) ...
                    + 4 ...
                    + 4 * exp(-lambda * (D+tm)) ...
                    - 4 * exp(-lambda * D) ...
                    - 4 * exp(-lambda * d) ...
                    - 4 * lambda * d ) / ...
                    (2 * lambda^2 * d^2 * (D - d/3));
            end
        end

        function [timelist, interval_str, timeprofile_str] = intervals(obj)
            %INTERVALS Get intervals of the sequence.
            %   This function returns a list of important time steps (including
            %   start and stop), a list of strings representing the intervals
            %   between these time steps and a list of strings representing the
            %   behavior of the sequence on each of these intervals.
            d = obj.delta;
            D = obj.Delta;
            p = obj.tpause;
            t1 = obj.t1;
            timelist = [t1, t1+d, t1+D, t1+D+d, t1+p+D+d, t1+p+D+2*d, t1+p+2*D+d, t1+p+2*(D+d)];
            interval_str = ["[t1,t1+delta]", ...
                "[t1+delta, t1+Delta]", ...
                "[t1+Delta, t1+Delta+delta]", ...
                "[t1+Delta+delta, t1+tpause+Delta+delta]", ...
                "[t1+tpause+Delta+delta, t1+tpause+Delta+2*delta]", ...
                "[t1+tpause+Delta+2*delta, t1+tpause+2*Delta+delta]", ...
                "[t1+tpause+2*Delta+delta, t1+tpause+2*(Delta+delta)]"];
            
            timeprofile_str = repmat("f(t) = %d (constant)", 1, 7);
            timeprofile_str = arrayfun(@(s, i) sprintf(s, i), timeprofile_str, ...
                [1 0 -1 0 1 0 -1]);
            % Remove unused intervals
            if d == D
                timelist(7) = [];
                interval_str(6) = [];
                timeprofile_str(6) = [];
            end
            if p == 0
                timelist(5) = [];
                interval_str(4) = [];
                timeprofile_str(4) = [];
            end
            if d == D
                timelist(3) = [];
                interval_str(2) = [];
                timeprofile_str(2) = [];
            end
            if obj.TE > obj.t1 + 2*(obj.Delta+obj.delta) +obj.tpause
                timelist = [timelist, obj.TE];
                interval_str = [interval_str,"[t1+tpause+2*(Delta+delta),TE]"];
                timeprofile_str = [timeprofile_str,"f(t) = 0 (constant)"];
            end
            if obj.t1 > 0
                timelist = [0,timelist];
                interval_str = ["[0,t1]",interval_str];
                timeprofile_str = ["f(t) = 0 (constant)",timeprofile_str];
            end

        end
        
        function s = string(obj, simplified)
            %STRING Convert sequence to string.
            if nargin == 2 && simplified
                s = sprintf("%s_d%g_D%g_tm%g", class(obj), ...
                    obj.delta, obj.Delta, obj.delta+obj.tpause);
            else
                s = sprintf("%s(delta=%g, Delta=%g, tm=%g,TE=%g, t1=%g)", class(obj), ...
                    obj.delta, obj.Delta, obj.delta+obj.tpause,obj.TE,obj.t1);
            end
        end
        
        function s = string(obj, simplified)
            %STRING Convert sequence to string.
            if nargin == 2 && simplified
                s = sprintf("%s_d%g_D%g_tm%g", class(obj), ...
                    obj.delta, obj.Delta, obj.delta+obj.tpause);
            else
                s = sprintf("%s(delta=%g, Delta=%g, tm=%g)", class(obj), ...
                    obj.delta, obj.Delta, obj.delta+obj.tpause);
            end
        end
    end
end