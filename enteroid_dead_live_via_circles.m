d=dir('*.tif');   %This is to dumnp whole folders into program
imdata=cell(1,size(d,1));
 for k=1:size(d,1)
 imdata{k} = imread(d(k).name); 
 end
%%

small_circ_sensitivity=.88;
med_circ_sensitivity=.96; %These numbers have no units. Small changes make big differences though. Higher equals finding faiter objects. 0.85 is the default for reference.
large_circ_sensitivity=.97;
overlap_cutoff=1; %overlap cut off. A value of 1 says two or more circles overlapping is considered an overlap. A value of 2 means 3 or more and so on.
small_size=[10,30]; %size range of small cells (radius in pixels)
med_size=[31,50];  %size range of medium cells (radius in pixels)
large_size=[51,75];  %size range of large cells (radius in pixels)
fraction_of_images_to_check_by_eye=1; % a value of 1 means you will see all. 0.5 means 50% (on average) of them choosen at random will be displayed

Ratio=[];
plate_ratios=zeros(4,6);  %only useful for 24 well plates 


for w=12:12   %image range to analyze

    
    
I=imdata{w};
I=I(660:1653,845:end);
bw=imcomplement(I);    %invert image
;

imgprep = im2double(bw); 
b = fir1(100,10e-5,'low'); h = b'*b;             %this whole section evens out background and removes negative values
numPad = 40;                                     % This code section was created by Jeffery La. It uses a low pass hamming window filter
imgprepPadded = padarray(imgprep,[numPad numPad],'replicate','both');
g = imfilter(imgprepPadded,h);
imgprepBackground = g((floor(numPad)+1):end-(floor(numPad)),...
    (floor(numPad)+1):end-(floor(numPad)));
imgprep = imgprep - imgprepBackground;
I2=imgprep;
I2(I2<=0)=0;



  I2=im2single(I2);                          %This emphasizes edges for better circle detection using a high contrast filter
 g=imadjust(I2);


[centers1, radii1, metric1] = imfindcircles(g,[small_size(1) small_size(2)],'Sensitivity',small_circ_sensitivity); %circle find for small circles
[centers2, radii2, metric2] = imfindcircles(g,[med_size(1) med_size(2)],'Sensitivity',med_circ_sensitivity); %circle find for medium circles
[centers3, radii3, metric3] = imfindcircles(g,[large_size(1) large_size(2)],'Sensitivity',large_circ_sensitivity); %circle find for large circles
centers=[centers1;centers2;centers3];    %combines all three into one vector
radii=[radii1;radii2;radii3];
metric=[metric1;metric2;metric3];




% 
% S=[1];  %Eliminates Overlapped Circles
% PO=[];
% PD=pdist2(centers(1:size(radii,1),1:2),centers(1:size(radii,1),1:2));
% Rad_mat=zeros(size(radii,1),size(radii,1));
% 
% for y=1:size(radii,1)
% for x=1:size(radii,1)
%     Rad_mat(x,y)=radii(x)+radii(y);
% end
% end
% C=minus(PD,Rad_mat);
% 
% for f=1:size(radii,1)
% 
%     S(1)=size(find(C(:,f)<0),1);
%     
%     if S(1)>overlap_cutoff  
%       po=find(C(:,f)<0);
% R=radii(po);
% PO=[PO;po(find(R<max(R)))];
% 
%     end
%     
% end
% PO=unique(PO);
%     radii(PO)=[0];
% 
% 
% 
% 
% 
% 
% 
% centers(PO,1:2)=[0];
%  radii=nonzeros(radii);
% left_over=size(nonzeros(centers(:,1:2)),1)/2;   
% c=zeros(left_over,2);
% c(:,1)=nonzeros(centers(:,1));
% c(:,2)=nonzeros(centers(:,2));
% centers=c;






I3=I2;       %Uses circles as a mask and find intensity within circle and divides by area
 
 Intensities=[];

 for v=1:size(radii,1)
     
      imageSizeX = size(I3,2);
imageSizeY = size(I3,1);
[columnsInImage rowsInImage] = meshgrid(1:imageSizeX, 1:imageSizeY);
centerX = round(centers(v,1));
centerY = round(centers(v,2));
radius = radii(v);
circlePixels = (rowsInImage - centerY).^2 + (columnsInImage - centerX).^2 <= radius.^2;

multi=I3(circlePixels);
    

Intensities(end+1)=sum(sum(multi))./(pi*radii(v)^2);
 end


 
 

 level = graythresh(Intensities);           %Use Otsu method to discriminate between light and dark which is live and dead

 dead=size(Intensities(Intensities>=level),2);
 live=size(Intensities(Intensities<level),2);
 ratio=live/(dead+live)
Ratio(end+1)=ratio;

 dead_location=find(Intensities>level);
 live_location=find(Intensities<=level);

 
 if rand<=fraction_of_images_to_check_by_eye
figure;  imshowpair(g,I,'Montage'); %Final plot with Blue being live and Red being dead Enteroids
  v1=viscircles(centers(live_location,1:2), radii(live_location),'EdgeColor','b');
  v2=viscircles(centers(dead_location,1:2), radii(dead_location),'EdgeColor','r');
  
  N=num2str(d(w).name);  %uses file name to find well ID number
str = N;
k = strfind(str,'_');
tex=N(k(end)+1:k(end)+3);
  text(100,100,tex,'Color','g')
  
 end
%  
%  
%  
%  
%    N=num2str(d(w).name);  %uses file name to find well ID number
% str = N;
% k = strfind(str,'_');
% tex=N(k(end)+1:k(end)+1);
% 
% if tex=='A'
%     row_num=1
% end
% if tex=='B'
%     row_num=2
% end
% if tex=='C'
%     row_num=3
% end
% if tex=='D'
%     row_num=4
% end
% 
% tex=N(k(end)+3:k(end)+3);
% column_num=str2num(tex);   
% 
% 
% plate_ratios(row_num,column_num)=ratio;
% plate_ratios; % this is an alternative display to Ratio with the matrix being oriented the same way as a 24 well plate
%  
%  
 
end
%plate_ratios
%%

xlswrite('sample_data.xlsx',plate_ratios);  %Save into excel sheet (must have excel file already in current folder
                                            % and purple name be that file's name)
                                            
%%
save('Ratios.mat','Ratio','plate_ratios');  % Save as a matlab workspace variable (only useful for matlab and origin exports)

%%
plate_ratios









