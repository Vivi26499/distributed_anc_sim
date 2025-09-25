clear; clc;
mgr1 = acoustics.old.RIRManager();
mgr1.Fs = 24000;
mgr1.Room = [10 10 10];
mgr1.Algorithm = "image-source";
mgr1.ImageSourceOrder = 0;
mgr1.MaterialAbsorption = .5;
mgr1.MaterialScattering = 0.07;

% 主扬声器
mgr1.addPrimarySpeaker(1, [1 5 5]);
mgr1.addPrimarySpeaker(2, [9 5 5]);

% 次扬声器
mgr1.addSecondarySpeaker(1, [7 5 5]);
mgr1.addSecondarySpeaker(2, [3 5 5]);
mgr1.addSecondarySpeaker(3, [5 7 5]);
mgr1.addSecondarySpeaker(4, [5 3 5]);

% 误差麦克风
mgr1.addErrorMicrophone(1, [6 5 5]);
mgr1.addErrorMicrophone(2, [4 5 5]);
mgr1.addErrorMicrophone(3, [5 6 5]);
mgr1.addErrorMicrophone(4, [5 4 5]);

mgr1.build(true);  % 批量生成 RIR

mgr2 = acoustics.RIRManager();
mgr2.Fs = 24000;
mgr2.Room = [10 10 10];
mgr2.Algorithm = "image-source";
mgr2.ImageSourceOrder = 0;
mgr2.MaterialAbsorption = .5;
mgr2.MaterialScattering = 0.07;

% 主扬声器
mgr2.addPrimarySpeaker(1, [1 5 5]);

% 次扬声器
mgr2.addSecondarySpeaker(1, [7 5 5]);
mgr2.addSecondarySpeaker(2, [3 5 5]);
mgr2.addSecondarySpeaker(3, [5 7 5]);
mgr2.addSecondarySpeaker(4, [5 3 5]);

% 误差麦克风
mgr2.addErrorMicrophone(1, [6 5 5]);
mgr2.addErrorMicrophone(2, [4 5 5]);
mgr2.addErrorMicrophone(3, [5 6 5]);
mgr2.addErrorMicrophone(4, [5 4 5]);

mgr2.build(true);  % 批量生成 RIR

isEqual = isequal(mgr1.getPrimaryRIR(1,1), mgr2.getPrimaryRIR(1,1));
fprintf('Primary RIRs are equal: %d\n', isEqual);

isEqual = isequal(mgr1.getSecondaryRIR(1,3), mgr2.getSecondaryRIR(1,3));
fprintf('Secondary RIRs are equal: %d\n', isEqual);