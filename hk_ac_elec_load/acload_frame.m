function frame = acload_frame(data, packetCount)
%ACLOAD_FRAME 将16字节继电器控制数据域封装为完整的上位机控制帧
%
% 用法：
%   frame = acload_frame(data)
%   frame = acload_frame(data, packetCount)
%
% 输入：
%   data        16字节控制数据域（uint8或可转换为uint8的整数向量）
%               顺序为通信组1、组2、组3、组4，每组4字节，小端序。
%   packetCount 可选，包计数0~255；省略时默认为0。
%
% 输出：
%   frame       1×22 uint8完整控制帧：
%               AA 55 50 12 packetCount data(16B) checksum
%
% 校验和：
%   按协议，仅对帧头至包计数（前5字节）求算术和，取低8位。
%
% 注意：
%   data应由 acload_relay 的第二个输出参数生成，例如：
%       [results, data] = acload_relay(1);
%       frame = acload_frame(data(1,:), 0);

if nargin < 1
    error('acload_frame:MissingData', '必须提供16字节控制数据域 data。');
end
if nargin < 2 || isempty(packetCount)
    packetCount = 0;
end
if ~isnumeric(data) || ~isreal(data) || ~isvector(data) || numel(data) ~= 16
    error('acload_frame:InvalidData', ...
        'data必须是包含16个元素的实数数值向量。');
end
if any(~isfinite(double(data(:)))) || ...
        any(double(data(:)) < 0) || any(double(data(:)) > 255) || ...
        any(double(data(:)) ~= fix(double(data(:))))
    error('acload_frame:InvalidDataValue', ...
        'data中的每个元素必须是0~255范围内的整数。');
end
if ~isnumeric(packetCount) || ~isreal(packetCount) || ...
        ~isscalar(packetCount) || ~isfinite(double(packetCount)) || ...
        packetCount < 0 || packetCount > 255 || packetCount ~= fix(packetCount)
    error('acload_frame:InvalidPacketCount', ...
        'packetCount必须是0~255范围内的整数。');
end

data = uint8(reshape(data, 1, 16));
packetCount = uint8(packetCount);

% 固定帧头、帧ID、信息长度和包计数。
header = uint8([hex2dec('55'), hex2dec('AA'), ...
    hex2dec('50'), hex2dec('12'), packetCount]);

% 完整帧前21字节：头部5字节 + 数据域16字节。
frameWithoutChecksum = [header, data];

% 协议定义：校验从帧头至包计数，即只累加前5字节。
checksum = uint8(mod(sum(uint16(header)), 256));

% 总长度22字节。
frame = [frameWithoutChecksum, checksum];

% 打印完整帧数据。
fprintf('\n--- 完整控制帧（%d字节）---\n', numel(frame));
fprintf('  ');
fprintf('%02X ', frame);
fprintf('\n');
fprintf('  帧头: %02X %02X  帧ID: %02X  长度: %02X  包计数: %02X\n', ...
    frame(1), frame(2), frame(3), frame(4), frame(5));
fprintf('  数据域: ');
fprintf('%02X ', frame(6:21));
fprintf('\n');
fprintf('  校验和: %02X\n', frame(22));
end