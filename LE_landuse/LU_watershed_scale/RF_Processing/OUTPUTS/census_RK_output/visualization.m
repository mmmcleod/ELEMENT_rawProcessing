clear
clc

files = dir('*csv');

%crop
figure()
title('Scaling with Ramankutty') 
for i=1:length(files)
    thisfileName = files(i).name;
    thisfiletable = readtable(thisfileName);
    subplot(8,4,i)
    
    if sum(isnan(str2double(string((thisfiletable.finalCrop)))))>0
        plot(thisfiletable.finalYear,str2double(string((thisfiletable.finalCrop))),'r')
    else
        plot(thisfiletable.finalYear,str2double(string((thisfiletable.finalCrop))),'k')
    end
    
    xlim([thisfiletable.finalYear(1) thisfiletable.finalYear(end)])
    ylim([0 70])
    title(['CROP ',extractBetween(thisfileName,5,15)])
end

%crop
figure()
title('Scaling with Ramankutty') 
for i=1:length(files)
    thisfileName = files(i).name;
    thisfiletable = readtable(thisfileName);
    subplot(8,4,i)
    
    if sum(isnan(str2double(string((thisfiletable.finalPast)))))>0
        plot(thisfiletable.finalYear,str2double(string((thisfiletable.finalPast))),'r')
    else
        plot(thisfiletable.finalYear,str2double(string((thisfiletable.finalPast))),'k')
    end
    
    xlim([thisfiletable.finalYear(1) thisfiletable.finalYear(end)])
    ylim([0 40])
    title(['PAST ',extractBetween(thisfileName,5,15)])
end

if sum(isnan(str2double(string((thisfiletable.finalCrop)))))>0
    plot(thisfiletable.finalYear,str2double(string((thisfiletable.finalCrop))),'r')
else
    plot(thisfiletable.finalYear,str2double(string((thisfiletable.finalCrop))),'k')
end
