function resultingFigure = setFigure(figurenumber, setmode)
%
% setFigure(#figure, mode)
% #figure same as in figure()
% mode:  1 - switch to figure and make active, also create figure if not
%            existing
%        2 - switch to figure, also create figure if not existing
%            don't make active unless it has to be created
%
% © 2013 Oliver D. Kripfgans
% University of Michigan

switch setmode
    case 1
    figure(figurenumber);

    case 2
    try set(0,'CurrentFigure', figurenumber); 
    catch
        figure(figurenumber);
    end
end

resultingFigure = gcf;
