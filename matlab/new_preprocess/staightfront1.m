clear
file = load('straight-front1.mat');
total_frames = file.straight_front1.Frames;
for k = 1:file.straight_front1.RigidBodies.Bodies
    if strcmp(file.straight_front1.RigidBodies.Name(k),'lidar')
        lidar_pos_raw = file.straight_front1.RigidBodies.Positions(k,:,:);
        lidar_rot_raw = file.straight_front1.RigidBodies.Rotations(k,:,:);
    else
        tag_pos_raw = file.straight_front1.RigidBodies.Positions(k,:,:);
        tag_rot_raw = file.straight_front1.RigidBodies.Rotations(k,:,:);
    end
end

n = 1;
invalid_num = 0;
for m = 1: total_frames
    lidar_invalid = any(isnan(lidar_pos_raw(:,:,m))) || any(isnan(lidar_rot_raw(:,:,m)));
    tag_invalid = any(isnan(tag_pos_raw(:,:,m))) || any(isnan(tag_rot_raw(:,:,m)));
    if (lidar_invalid || tag_invalid)
        lidar_pos_raw(:,:,m) = zeros(1,3);
        lidar_rot_raw(:,:,m) = zeros(1,9);
        tag_pos_raw(:,:,m) = zeros(1,3);
        tag_rot_raw(:,:,m) = zeros(1,9);
        invalid_num = invalid_num + 1;
    else
        lidar_pos(:,:,n) = lidar_pos_raw(:,:,m);
        lidar_rot(:,:,n) = lidar_rot_raw(:,:,m);
        tag_pos(:,:,n) = tag_pos_raw(:,:,m);
        tag_rot(:,:,n) = tag_rot_raw(:,:,m);
        n = n + 1;
    end
end
valid_frames = n - 1;
x = 1:valid_frames;
y = squeeze(lidar_pos(1,2,:));
figure(1);
scatter(x,y,'filled');
p = 1:valid_frames;
q = squeeze(lidar_pos(1,1,:));
figure(2);
scatter(p,q,'filled');
p = 1:valid_frames;
q = squeeze(lidar_pos(1,3,:));
figure(3);
scatter(p,q,'filled');

mocap_to_lidar_change_of_basis = [0 1 0 0; 1 0 0 0; 0 0 -1 0; 0 0 0 1];
new_basis = mocap_to_lidar_change_of_basis;
%straight_front_1
distance(1,:) = [44,2188];
distance(2,:) = [2900,3252];
distance(3,:) = [4053,4681];
distance(4,:) = [5026,5498];
distance(5,:) = [6935,8542];
distance(6,:) = [8977,9519];
for i = 1:6
    lidar_pos_mean = mean(lidar_pos(1,:,distance(i,1):distance(i,2)),3);
    lidar_rot_mean = mean(lidar_rot(1,:,distance(i,1):distance(i,2)),3);
    tag_pos_mean = mean(tag_pos(1,:,distance(i,1):distance(i,2)),3);
    tag_rot_mean = mean(tag_rot(1,:,distance(i,1):distance(i,2)),3);
    lidar_rotm = reshape(lidar_rot_mean,3,3);
    tag_rotm = reshape(tag_rot_mean,3,3);
    world_H_tag = createSE3(tag_rotm, tag_pos_mean');
    world_H_lidar = createSE3(lidar_rotm, lidar_pos_mean');
    lidar_H_tag =  world_H_lidar \ world_H_tag;
    lidar_H_tag_t = new_basis * lidar_H_tag * inv(new_basis);
    angles = rotm2eul(lidar_H_tag_t(1:3,1:3), 'XYZ');
%     angles = fliplr(angles)';
%     angles    = flipud(new_basis*angles)';
    tag_rotm_lidar(i,:) = angles*180/pi;
%     tag_pos_lidar(i,:) = new_basis*lidar_H_tag(1:3,4)/1000;
    tag_pos_lidar(i,:) = lidar_H_tag_t(1:3,4)/1000;
end
tag_rotm_lidar
tag_pos_lidar
for i = 1:5
    file_name = strcat('lidar_front',int2str(i+1),'.txt');
    x = dlmread(file_name,',',1,0);
    lidar_pose_prediction_L(i,:) = mean(x(:,4:6),1);
    lidar_rot_prediction_L(i,:) = mean(x(:,7:9),1)*180/pi;
end
for i = 1:5
    file_name = strcat('april_front',int2str(i+1),'.txt');
    x = dlmread(file_name,',',1,0);
    april_pose_prediction_L(i,:) = mean(x(:,3:5),1);
    april_rot_prediction_L(i,:) = mean(x(:,6:8),1)*180/pi;
end
lidar_rot_prediction_L
lidar_pose_prediction_L
figure(1);
delta_x_meter = lidar_pose_prediction_L(:,1) - tag_pos_lidar(2:6,1);
plot(tag_pos_lidar(2:6,1),delta_x_meter);
figure(2);
delta_y_meter = lidar_pose_prediction_L(:,2) - tag_pos_lidar(2:6,2);
plot(tag_pos_lidar(2:6,1),delta_y_meter);
figure(3);
delta_z_meter = lidar_pose_prediction_L(:,3) - tag_pos_lidar(2:6,3);
plot(tag_pos_lidar(2:6,1),delta_z_meter);
figure(4);
delta_r_degree = lidar_rot_prediction_L(:,1) - tag_rotm_lidar(2:6,1);
plot(tag_pos_lidar(2:6,1),delta_r_degree);
figure(5);
delta_p_degree = lidar_rot_prediction_L(:,2) - tag_rotm_lidar(2:6,2);
plot(tag_pos_lidar(2:6,1),delta_p_degree);
figure(6);
delta_yaw_degree = lidar_rot_prediction_L(:,3) - tag_rotm_lidar(2:6,3);
plot(tag_pos_lidar(2:6,1),delta_yaw_degree);
Distance_meter = tag_pos_lidar(2:6,1);
T = table(Distance_meter,delta_x_meter,delta_y_meter,delta_z_meter,delta_r_degree,delta_p_degree,delta_yaw_degree)