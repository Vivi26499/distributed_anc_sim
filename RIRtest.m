clear; clc;
mgr1 = acoustics.old.RIRManager();
mgr1.Fs = 24000;
mgr1.Room = [10 10 10];
mgr1.Algorithm = "image-source";
mgr1.ImageSourceOrder = 0;
mgr1.MaterialAbsorption = .5;
mgr1.MaterialScattering = 0.07;

% 主扬声器
mgr1.addPrimarySpeaker(101, [5 5 5]);

% 次扬声器
mgr1.addSecondarySpeaker(201, [6 5 5]);
mgr1.addSecondarySpeaker(202, [3 5 5]);

% 误差麦克风
mgr1.addErrorMicrophone(301, [7 5 5]);
mgr1.addErrorMicrophone(302, [4 5 5]);

mgr1.build(true);  % 批量生成 RIR

mgr2 = acoustics.RIRManager();
mgr2.Fs = 24000;
mgr2.Room = [10 10 10];
mgr2.Algorithm = "image-source";
mgr2.ImageSourceOrder = 0;
mgr2.MaterialAbsorption = .5;
mgr2.MaterialScattering = 0.07;

% 主扬声器
mgr2.addPrimarySpeaker(101, [5 5 5]);

% 次扬声器
mgr2.addSecondarySpeaker(201, [6 5 5]);
mgr2.addSecondarySpeaker(202, [3 5 5]);

% 误差麦克风
mgr2.addErrorMicrophone(301, [7 5 5]);
mgr2.addErrorMicrophone(302, [4 5 5]);

mgr2.build(true);  % 批量生成 RIR

rir1 = mgr2.getSecondaryRIR(201, 301);
rir2 = mgr2.getSecondaryRIR(202, 302);

viz.plot_rir(rir1, mgr2.Fs, 'Secondary RIR from Speaker 202 to Mic 302');
viz.plot_rir(rir2, mgr2.Fs, 'Secondary RIR from Speaker 201 to Mic 301');