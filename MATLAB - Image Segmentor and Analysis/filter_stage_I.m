function [BW_image] = filter_stage_I (crackMap)
    % First step Filter [for orphan/flakey pixela and bridging close neighbors]
    BW2 = bwmorph(crackMap,'close','inf');
    BW2 = bwmorph(BW2,'bridge','inf');
    BW2 = bwmorph(BW2,'spur','inf');
    BW_image = bwmorph(BW2,'clean','inf');
end