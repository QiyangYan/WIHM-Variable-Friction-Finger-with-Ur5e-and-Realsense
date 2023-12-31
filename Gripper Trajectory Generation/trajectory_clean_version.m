%% DESCRIPTION
% this version gives the correct graph for angle change of the rotation, but the
% alpha1 and alpha2 is not right for the second stage, cause different
% a and b need to be defined after the 90 degree rotation. 

% the logic of code of this one is better than trajectory.m.


%% clean
clear all
clc


%% User INPUT

% start pose
start_pose = [0, 4];

% goal pose, assume x = 0 all the time
goal_angle = 180; 
if goal_angle > 180 && goal_angle <= 360
    goal_angle = goal_angle - 360; % rotate anticlockwise
elseif goal_angle > 360
    disp("Invalid angle input. Enter an angle that's within [-180, 360]")
end
goal_pose = [0, 7, deg2rad(goal_angle-45)];
% positive is clockwise
% [0,90] -> [-45,45]负值由右往左转得到, 正值由左往右转得到
% [0,-90] -> 由左往右 [270, 360]会按anticlockwise rotate来
% [90,180] -> 转两周
% [-90,-180] -> 转两周


%% Parameters (unit: cm, degree)

% pad width, assume together for now
pad_thick = 0;


% object infor
L = 2; % square side length
square_diagonal = L * sqrt(2);

% finger width
W = 2; % finger_width = finger_width + 2 * rubber_width
FL = 10; % finger_length

% base seperation
d = L+W; % base_seperate
base_left = [-d/2, 0];
base_right = [d/2, 0];
base_d = base_right(1) - base_left(1);

alpha1_LIMIT = deg2rad([20 160]); % NEED to find more reasonable figure
alpha2_LIMIT = deg2rad([20 160]);


%% Plot start and end point
scatter(start_pose(1), start_pose(2), 100, 'filled');
hold on;
scatter(goal_pose(1), goal_pose(2), 100, 'filled');
hold on;


%% Check if rotation needed
disp("Rotation Check")
fprintf("Rotate %d degree.\n",goal_angle)

rotate_small = mod(abs(goal_angle),90);
% disp(rotate_small);
rotate_90 = (abs(goal_angle)-rotate_small)/90;
% disp(rotate_90);

if goal_pose(3) >= 0
    rotation = [];
    rotation(1:rotate_90) = 90;
    rotation(rotate_90+1) = rotate_small;
else
    rotation = [];
    rotation(1:rotate_90) = -90;
    rotation(rotate_90+1) = -rotate_small;
end 

end_goal_pose = goal_pose;

for i = 1:1:rotate_90+1

    if rotation(2) > 0 && i == 1
        goal_pose = [goal_pose(1),goal_pose(2)*2/3,deg2rad(rotation(i)-45)];
    else 
        goal_pose = end_goal_pose;
    end

    if rotation(i) > 0 && rotation(i) <= 90 % 0 to 90
        
        plotStartPos(start_pose, L, W, base_left, base_right);
        disp("SSSR, Clockwise Rotation") 
        [alpha1_rotate, alpha2_rotate, centre1] = get_R2L_Rotate_StartPos(square_diagonal, goal_pose, d, W, L, base_left, base_right);
        slide_goal_pose = [centre1, goal_pose(3)];
        % disp("Rotation Check Complete")
        get_alpha_for_slide(slide_goal_pose, start_pose, base_left, base_right, base_d, FL)

        
    elseif rotation(i) < 0 && rotation(i) >= -90 % 0 to -90
        
        disp("SSSR, Anticlockwise Rotation")
        [alpha1_rotate, alpha2_rotate, centre1] = get_L2R_Rotate_StartPos(square_diagonal, goal_pose, d, W, L, base_left, base_right);
        slide_goal_pose = [centre1, goal_pose(3)];
        % disp("Rotation Check Complete1")
        get_alpha_for_slide(slide_goal_pose, start_pose, base_left, base_right, base_d, FL)

    elseif rotation(i) == 0 % no rotation
        
        plotStartPos(start_pose, L, W, base_left, base_right);
        disp("SSS")
        disp("No rotation")
        get_alpha_for_slide(goal_pose, start_pose, base_left, base_right, base_d, FL)

    else 
        disp("Error")
        
    end

    start_pose = goal_pose(1:2);

    if rotate_90 == 1 && rotate_small == 0
        break;
    elseif rotate_90 == 2 && i == 2
        break;
    end

end


%% plotting setting
xlim([-10 10]);      % set x-axis limits
ylim([-5 10]);      % set y-axis limits
axis equal;
grid on;


%% Basic functions
function [] = plotArch (radius, origin, start_angle, end_angle)
    % Generate a set of angles to plot the circle
    theta = linspace(start_angle, end_angle, 100);
    
    % Calculate the x and y coordinates of the circle
    x = origin(1) + radius * cos(theta);
    y = origin(2) + radius * sin(theta);
    
    % Plot the circle
    plot(x, y, 'k', 'LineWidth', 2);
end

function angle = findalpha2(coord, base_right)
    x = coord(1);
    y = coord(2);
    angle = abs(atan( y / (base_right(1) - x) ));
    if x < base_right(1)
        angle = pi - angle; 
    end
end

function angle = findalpha1(coord, base_left)
    x = coord(1);
    y = coord(2);
    angle = atan( y / (base_left(1) - x) );
    if x > base_left(1)
        angle = pi + angle; 
    end
end

function [center, distance_to_base, angle_to_base] = getCentreInfor (square_four_points, base_right, base_left)
    % Define the coordinates of the four vertices of the square
    A = square_four_points(1,:); % Replace x1 and y1 with the x and y coordinates of vertex A
    B = square_four_points(2,:); % Replace x2 and y2 with the x and y coordinates of vertex B
    C = square_four_points(3,:); % Replace x3 and y3 with the x and y coordinates of vertex C
    D = square_four_points(4,:); % Replace x4 and y4 with the x and y coordinates of vertex D
    
    % Compute the midpoint of each pair of opposite vertices
    M_AB = (A + B) / 2;
    M_BC = (B + C) / 2;
    M_CD = (C + D) / 2;
    M_DA = (D + A) / 2;
    
    % Calculate the average of the four center points
    center = (M_AB + M_BC + M_CD + M_DA) / 4;
    
    centre_to_baseR = sqrt((base_right(1)-center(1))^2 + (center(2))^2);
    centre_to_baseL = sqrt((base_left(1)-center(1))^2 + (center(2))^2);

    angle_to_baseR = atan( center(2) / (base_right(1)-center(1)) );
    angle_to_baseL = atan( center(2) / (base_left(1)-center(1)) );

    distance_to_base = [centre_to_baseL; centre_to_baseR];
    angle_to_base = [angle_to_baseL, angle_to_baseR];
end

function [] = plotStartPos(start_pose, L, W, base_left, base_right)
    %start pos process
    % a_start = [start_pose(1)-square_diagonal/2*cos(start_pose(3)) start_pose(2)+square_diagonal/2*sin(goal_pose(3))];
    % b_start = [start_pose(1)+square_diagonal/2*cos(start_pose(3)) start_pose(2)-square_diagonal/2*sin(goal_pose(3))];

    a_start = [start_pose(1)-L/2,start_pose(2)-L/2];
    b_start = [start_pose(1)+L/2,start_pose(2)+L/2]; 

    alpha1_start = findalpha1(start_pose,base_left);
    alpha2_start = findalpha2(start_pose,base_right);
    
    b_length_start = sqrt((W/2)^2 + b_start(2)^2);
    a_length_start = sqrt((W/2)^2 + a_start(2)^2);
    
    left_offset = atan((W/2)/a_start(2));
    right_offset = atan((W/2)/b_start(2));

    motor_angle_start = [alpha1_start-left_offset, alpha2_start-right_offset];
    
    %plot start pos square
    
    square_coord_start = [a_start;
        b_start(1),a_start(2);
        b_start;
        a_start(1), b_start(2);
        a_start;
        b_start;
        ];
    
    plot(square_coord_start(:,1), square_coord_start(:,2), 'g', 'LineWidth', 0.5);
    hold on;


    Left_touch_line = [base_left; a_start];
    plot(Left_touch_line(:,1), Left_touch_line(:,2),'r', 'LineWidth', 0.5);
    hold on;

    Right_touch_line = [base_right; b_start];
    plot(Right_touch_line(:,1), Right_touch_line(:,2),'r', 'LineWidth', 0.5)
    hold on;

    [centre_start, distance_to_base_start, angle_to_base_start] = getCentreInfor(square_coord_start(1:4,:), base_right, base_left);
    hold on;

    triangle_start = [
        b_start;
        centre_start;
        a_start(1), b_start(2)
        ];
    plot(triangle_start(:,1), triangle_start(:,2), 'k', 'LineWidth', 0.5);
    hold on;
end


%% rotate from positive x-axis to any other place that's on the left side of 
% the finger
function [alpha1_rotate, alpha2_rotate, centre1,motor_angle1] = get_R2L_Rotate_StartPos(square_diagonal, goal_pose, d, W, L, base_left, base_right)
    
    a_goal = [goal_pose(1)-square_diagonal/2*cos(goal_pose(3)) goal_pose(2)+square_diagonal/2*sin(goal_pose(3))];
    b_goal = [goal_pose(1)+square_diagonal/2*cos(goal_pose(3)) goal_pose(2)-square_diagonal/2*sin(goal_pose(3))];
    
    % length and angle of the line connect actuator centre and touch point
    a_length_goal = sqrt((a_goal(1)+d/2)^2+a_goal(2)^2);
    b_length_goal = sqrt((b_goal(1)-d/2)^2+b_goal(2)^2);

    left_angle = findalpha1(a_goal, base_left);
    right_angle = findalpha2(b_goal, base_right);
      
    % offset due to thickness of gripper
    left_angle_offset = asin( (W/2) /a_length_goal);
    right_angle_offset = asin( (W/2) /b_length_goal);    
    
    theta1 = asin((W/2)/b_length_goal);
    theta2 = theta1 + pi/4;
    l1 = sqrt( (square_diagonal)^2 + (b_length_goal)^2 - (cos(theta2)*2*square_diagonal*b_length_goal) );
    theta3 = acos( ((d)^2 + (a_length_goal)^2 - (l1)^2) / (2*d*a_length_goal));
    alpha1_rotate = pi - theta3;
    left_motor_angle1 = alpha1_rotate - left_angle_offset;
    
    theta4 = acos( ((l1)^2+(square_diagonal)^2-(b_length_goal)^2) / (2*l1*square_diagonal) );
    theta5 = acos( ((a_length_goal)^2 + (l1)^2 - (d)^2) / (2*a_length_goal*l1));
    right_motor_angle1 = pi - (2*pi - theta3 - theta4 - theta5 - pi/4);
    alpha2_rotate = right_motor_angle1 + right_angle_offset;
    
    motor_angle1 = [left_motor_angle1, right_motor_angle1];
    
    %a1 = [base_left(1) + a_length*cos(theta3), base_left(2) + a_length*sin(theta3)];
    a1 = [base_left(1) - a_length_goal*cos(alpha1_rotate), base_left(2) + a_length_goal*sin(alpha1_rotate)];
    b1 = [base_right(1) + b_length_goal*cos(alpha2_rotate), base_right(2) + b_length_goal*sin(alpha2_rotate)];
    b_low1 = [b1(1)-L*cos(right_motor_angle1), b1(2)-L*sin(right_motor_angle1)];
    
    % b_low_length_rotate = sqrt((b_low1(1)-base_right(1))^2+b_low1(2)^2);
    % a1_length_rotate = sqrt((a1(1)-base_left(1))^2+a1(2)^2);
    % 
    % a1_baseR_radius = sqrt((base_right(1)-a1(1))^2 + (a1(2))^2);
    % a1_baseR_degree = atan((a1(2))/(base_right(1)-a1(1)));
    
    % Square
    square_coord_rotate = [a1;
        b1(1)-L*cos(right_motor_angle1), b1(2)-L*sin(right_motor_angle1);
        b1;
        b1(1)-L*sin(right_motor_angle1), b1(2)+L*cos(right_motor_angle1);
        a1;
        b1;
        ];
    
    square_coord_goal = [a_goal; 
    a_goal(1) + L*sin((pi/4)-goal_pose(3)), a_goal(2) - L*cos((pi/4)-goal_pose(3));
    b_goal;
    b_goal(1) - L*sin((pi/4)-goal_pose(3)), b_goal(2) + L*cos((pi/4)-goal_pose(3));
    a_goal;
    b_goal;
    ];
    
    plot(square_coord_rotate(:,1), square_coord_rotate(:,2), 'b-', 'LineWidth', 0.5);
    hold on;
    plot(square_coord_goal(:,1), square_coord_goal(:,2), 'b-', 'LineWidth', 0.5);
    hold on;

    % touch lines
    Left_touch_line = [base_left; a1];
    plot(Left_touch_line(:,1), Left_touch_line(:,2),'r', 'LineWidth', 0.5);
    hold on;

    Right_touch_line = [base_right; b1];
    plot(Right_touch_line(:,1), Right_touch_line(:,2),'r', 'LineWidth', 0.5)
    hold on;
    
    Left_touch_line = [base_left;
    base_left(1) - a_length_goal*cos(left_angle), base_left(2) + a_length_goal*sin(left_angle)];
    plot(Left_touch_line(:,1), Left_touch_line(:,2),'r', 'LineWidth', 0.5)
    hold on;
    
    Right_touch_line = [base_right;
        base_right(1) + b_length_goal*cos(right_angle), base_right(2) + b_length_goal*sin(right_angle)];
    plot(Right_touch_line(:,1), Right_touch_line(:,2),'r', 'LineWidth', 0.5)
    hold on;

    % get centre
    [centre1, distance_to_base1, angle_to_base1] = getCentreInfor(square_coord_rotate(1:4,:), base_right, base_left);
    scatter(centre1(1), centre1(2), 100, 'filled');
    hold on;

    [centre_goal, distance_to_base_goal, angle_to_base_goal] = getCentreInfor(square_coord_goal(1:4,:), base_right, base_left);
    scatter(centre1(1), centre1(2), 100, 'filled');
    hold on;
    
    % direction 
    triangle = [b1;
        centre1;
        b1(1)-L*sin(right_motor_angle1), b1(2)+L*cos(right_motor_angle1)
        ];
    plot(triangle(:,1), triangle(:,2), 'k', 'LineWidth', 0.5);
    hold on;

    triangle_goal = [b_goal;
        centre_goal
        b_goal(1) - L*sin((pi/4)-goal_pose(3)), b_goal(2) + L*cos((pi/4)-goal_pose(3));
        ];
    plot(triangle_goal(:,1), triangle_goal(:,2), 'k', 'LineWidth', 0.5);
    hold on;
end

%% rotate from negative x-axis to any other place that's on the right side of 
% the finger
function [alpha1_rotate, alpha2_rotate, centre1] = get_L2R_Rotate_StartPos(square_diagonal, goal_pose, d, W, L, base_left, base_right)
    angle = -(goal_pose(3)+pi/4) - pi/4;

    a_goal = [goal_pose(1)-square_diagonal/2*cos(angle) goal_pose(2)-square_diagonal/2*sin(angle)];
    b_goal = [goal_pose(1)+square_diagonal/2*cos(angle) goal_pose(2)+square_diagonal/2*sin(angle)];

    % length and angle of the line connect actuator centre and touch point
    a_length_goal = sqrt((a_goal(1)-(-d/2))^2+a_goal(2)^2);
    b_length_goal = sqrt((b_goal(1)-d/2)^2+b_goal(2)^2);
      
    % offset due to thickness of gripper
    left_angle_offset = asin( (W/2) /a_length_goal);
    right_angle_offset = asin( (W/2) /b_length_goal);   
    
    alpha1_goal = findalpha1(a_goal, base_left);
    alpha2_goal = findalpha2(b_goal, base_right);
    

    % Calculate two alphas and motor angle
    theta1 = asin((W/2)/a_length_goal);
    theta2 = theta1 + pi/4;
    l1 = sqrt( (square_diagonal)^2 + (a_length_goal)^2 - (cos(theta2)*2*square_diagonal*a_length_goal) );
    alpha2_rotate = pi - acos( ((d)^2 + (b_length_goal)^2 - (l1)^2) / (2*d*b_length_goal));

    theta4 = acos( ( (l1)^2+(a_length_goal)^2-(square_diagonal)^2 ) / (2*l1*a_length_goal) );
    theta5 = acos( ((d)^2 + (l1)^2 - (b_length_goal)^2) / (2*d*l1));
    alpha1_rotate = pi - theta4 - theta5;

    right_motor_angle = alpha2_rotate - right_angle_offset;
    left_motor_angle = alpha1_rotate - left_angle_offset;
    motor_angle1 = [left_motor_angle, right_motor_angle];
    
    %a1 = [base_left(1) + a_length*cos(theta3), base_left(2) + a_length*sin(theta3)];
    a1 = [base_left(1) - a_length_goal*cos(alpha1_rotate), a_length_goal*sin(alpha1_rotate)];
    b1 = [base_right(1) - b_length_goal*cos(pi-alpha2_rotate), b_length_goal*sin(pi-alpha2_rotate)];
    % b_low1 = [b1(1)-L*cos(right_motor_angle), b1(2)-L*sin(right_motor_angle)];

    % touch lines
    Left_touch_line = [base_left; a1];
    plot(Left_touch_line(:,1), Left_touch_line(:,2),'r', 'LineWidth', 0.5);
    hold on;

    Right_touch_line = [base_right; b1];
    plot(Right_touch_line(:,1), Right_touch_line(:,2),'r', 'LineWidth', 0.5)
    hold on;
    
    Left_touch_line = [base_left;
    base_left(1) - a_length_goal*cos(alpha1_goal), base_left(2) + a_length_goal*sin(alpha1_goal)];
    plot(Left_touch_line(:,1), Left_touch_line(:,2),'r', 'LineWidth', 0.5)
    hold on;

    Right_touch_line = [base_right;
        base_right(1) + b_length_goal*cos(alpha2_goal), base_right(2) + b_length_goal*sin(alpha2_goal)];
    plot(Right_touch_line(:,1), Right_touch_line(:,2),'r', 'LineWidth', 0.5)
    hold on;

    % Square
    square_coord_rotate = [a1;
        a1(1)+L*cos(left_motor_angle), a1(2)-L*sin(left_motor_angle);
        b1;
        b1(1)-L*cos(left_motor_angle), b1(2)+L*sin(left_motor_angle);
        a1;
        b1;
        ];
    
    square_coord_goal = [a_goal; 
        a_goal(1) + L*cos((pi/4)-angle), a_goal(2) - L*sin((pi/4)-angle);
        b_goal;
        b_goal(1) - L*cos((pi/4)-angle), b_goal(2) + L*sin((pi/4)-angle);
        a_goal;
        b_goal;
    ];
    
    plot(square_coord_rotate(:,1), square_coord_rotate(:,2), 'b-', 'LineWidth', 0.5);
    hold on;
    plot(square_coord_goal(:,1), square_coord_goal(:,2), 'b-', 'LineWidth', 0.5);
    hold on;

    % get centre
    [centre1, distance_to_base1, angle_to_base1] = getCentreInfor(square_coord_rotate(1:4,:), base_right, base_left);
    scatter(centre1(1), centre1(2), 100, 'filled');
    hold on;

    [centre_goal, distance_to_base1, angle_to_base1] = getCentreInfor(square_coord_goal(1:4,:), base_right, base_left);
    scatter(centre_goal(1), centre_goal(2), 100, 'filled');
    hold on;
    
    % direction 
    triangle = [
        b1(1)-L*cos(left_motor_angle), b1(2)+L*sin(left_motor_angle);
        centre1;
        a1;
        ];
    plot(triangle(:,1), triangle(:,2), 'r', 'LineWidth', 0.5);
    hold on;

    triangle_goal = [
        b_goal(1) - L*cos((pi/4)-angle), b_goal(2) + L*sin((pi/4)-angle);
        centre_goal;
        a_goal;
        ];
    plot(triangle_goal(:,1), triangle_goal(:,2), 'r', 'LineWidth', 0.5);
    hold on;

end

%% Slide
function [] = get_alpha_for_slide(goal_pose, start_pose, base_left, base_right, base_d, FL)
    r_start = sqrt((start_pose(1)-base_left(1))^2 + start_pose(2)^2);
    r_goal_from_right = sqrt((goal_pose(1)-base_right(1))^2 + goal_pose(2)^2);
    r_goal_from_left = sqrt((goal_pose(1)-base_left(1))^2 + goal_pose(2)^2);

    if r_goal_from_right > FL || r_goal_from_left > FL
        disp(r_goal_from_right)
        disp(r_goal_from_left)
        disp("Invalid Coordinate. Unreachable. Check.")
    
    elseif goal_pose(1:2) == start_pose()
        disp("no movement")
    
    elseif r_goal_from_left == r_start 
        disp("One Slide")
        disp("Control Mode: T,P")
        disp("High Friction Sequence: L")
    
        alpha1_start = findalpha1(start_pose,base_left);
        alpha1_end = findalpha1(goal_pose,base_left);
    
        plotArch (r_start,base_left,pi-alpha1_start,pi-alpha1_end);
        hold on;
    
    elseif r_goal_from_right < (base_d + r_start)
        disp("Two Slides")
        disp("Control Mode: T,P")
        disp("High Friction Sequence: L, R")
    
        r_goal = r_goal_from_right;
    
        alpha1_start = findalpha1(start_pose,base_left);
        alpha2_end = findalpha2(goal_pose,base_right);
    
        alpha1_mid = pi - acos( (-r_goal^2 + r_start^2 + base_d^2) / (2*r_start*base_d) );
        alpha2_mid = pi - acos((r_goal^2 + base_d^2 - r_start^2) / (2*base_d*r_goal));
    
        plotArch (r_start,base_left,pi-alpha1_start,pi-alpha1_mid);
        hold on;
        plotArch (r_goal,base_right,alpha2_end,alpha2_mid);
        hold on;
    
    elseif r_goal_from_right > (base_d + r_start) && goal_pose(1) < 0
        % if three slides AND rotate_start_pos is on the negative x-axis
        % choose this way of slide
    
        disp("Three Slides")
        disp("Control Mode: T,P")
        disp("High Friction Sequence: L, R, L")
    
        r_goal = r_goal_from_left;
    
        %alpha1 = findShortRoute(r_start, r_goal, base_d, base_left,start_pose,goal_pose);
    
        a = 1; % need to know how to obtain the best a value
        b = sqrt(r_start^2-a^2);
        r_mid = sqrt( (a+base_d)^2 + (b)^2 );
    
        alpha1_start = findalpha1(start_pose,base_left);
        alpha1_end = findalpha1(goal_pose,base_left);
    
        alpha1_mid1 = pi - acos( (r_start^2 + base_d^2 - r_mid^2) / (2*r_start*base_d) );
        alpha2_mid1 = pi - acos( (-r_start^2 + base_d^2 + r_mid^2) / (2*r_mid*base_d) );
    
        alpha1_mid2 = pi - acos( (-r_mid^2 + base_d^2 + r_goal^2) / (2*r_goal*base_d) );
        alpha2_mid2 = pi - acos( (r_mid^2 + base_d^2 - r_goal^2) / (2*r_mid*base_d) );
    
        plotArch (r_start,base_left,pi-alpha1_start,pi-alpha1_mid1);
        hold on;
        plotArch (r_mid,base_right,alpha2_mid2,alpha2_mid1);
        hold on;
        plotArch (r_goal,base_left,pi-alpha1_end,pi-alpha1_mid2);
        hold on;
    
    else 
        disp("Error")
    end
end


function [isok] = checkLimit(alpha1, alpha2, alpha1_LIMIT, alpha2_LIMIT)
    if alpha1 > alpha1_LIMIT(1) || alpha2 > alpha2_LIMIT(1) || alpha1 < alpha1_LIMIT(2) || alpha2 < alpha2_LIMIT(2)
        isok = 0;
    end   
    isok = 1;
end