function img_elastic = elastic_def_multiplicator(inputImage, geotrans_type, maxDistortAlpha, totNumberCracksElasticDef,showfig_points)

img_elastic = zeros([size(inputImage),totNumberCracksElasticDef]);

parfor j = 1:totNumberCracksElasticDef

    % Inputs combination
    % Valid parameters for elastic deformation of synthetic cracks
    % affine | alpha_geotrans [30 70] | SIGMA = 5 | alpha = [15 35]
    % projective | alpha_geotrans [30 70] | SIGMA = 5 | alpha = [15 35]
    % piecewise_linear | alpha_geotrans [80 100] | SIGMA = 5 | alpha = [15 35]
    % polynomial | Degree 2 | alpha_geotrans [5 10] | SIGMA = 5 | alpha = [15 35]
    % polynomial | Degree 3 | alpha_geotrans [2 4] | SIGMA = 5 | alpha = [15 35]
    % polynomial | Degree 4 | alpha_geotrans [1] | SIGMA = 5 | alpha = [15 35]    
    % local_weighted_mean: TOO MUCH DISTORTION (exploding pixels) NOT RECOMMEND TO USE THIS FOR SYNTHETIC CRACKS

    geotrans_idx = randi([1,length(geotrans_type)],1);
    switch geotrans_idx
        case 1
            alpha_geotrans = randi([30,70],1);  % Geometric transformation scale factor
            SIGMA = 5;  % Standard deviation of Gaussian convolution
            if maxDistortAlpha == 0
                alpha = randi([15,35],1); % Scaling factor 
            else
                alpha = randi([50,90],1); % Scaling factor 
            end
            poly_degree = [];
        case 2
            alpha_geotrans = randi([30,70],1);  % Geometric transformation scale factor
            SIGMA = 5;  % Standard deviation of Gaussian convolution
            if maxDistortAlpha == 0
                alpha = randi([15,35],1); % Scaling factor 
            else
                alpha = randi([50,90],1); % Scaling factor 
            end
            poly_degree = [];
        case 3
            alpha_geotrans = randi([40,60],1);  % Geometric transformation scale factor
            SIGMA = 5;  % Standard deviation of Gaussian convolution
            if maxDistortAlpha == 0
                alpha = randi([15,35],1); % Scaling factor 
            else
                alpha = randi([50,90],1); % Scaling factor 
            end
            poly_degree = [];
        case 4
            polydegree_idx = randi([2,4],1);
            if polydegree_idx == 2
                alpha_geotrans = randi([5,10],1);  % Geometric transformation scale factor
                poly_degree = 2;      % Degree: 2|3|4
                SIGMA = 5;  % Standard deviation of Gaussian convolution
                if maxDistortAlpha == 0
                    alpha = randi([15,35],1); % Scaling factor 
                else
                    alpha = randi([50,90],1); % Scaling factor 
                end 
            elseif polydegree_idx == 3
                alpha_geotrans = randi([2,4],1);  % Geometric transformation scale factor
                poly_degree = 3;      % Degree: 2|3|4
                SIGMA = 5;  % Standard deviation of Gaussian convolution
                if maxDistortAlpha == 0
                    alpha = randi([15,35],1); % Scaling factor 
                else
                    alpha = randi([50,90],1); % Scaling factor 
                end
            elseif polydegree_idx == 4
                alpha_geotrans = 1;  % Geometric transformation scale factor
                poly_degree = 4;      % Degree: 2|3|4
                SIGMA = 5;  % Standard deviation of Gaussian convolution
                if maxDistortAlpha == 0
                    alpha = randi([15,35],1); % Scaling factor 
                else
                    alpha = randi([50,90],1); % Scaling factor 
                end
            end                    
        case 5
            alpha_geotrans = randi([60,70],1);  % Geometric transformation scale factor
            SIGMA = 5;  % Standard deviation of Gaussian convolution
            if maxDistortAlpha == 0
                alpha = randi([15,35],1); % Scaling factor 
            else
                alpha = randi([50,90],1); % Scaling factor 
            end 
            poly_degree = [];
    end

    % Elastic deformation
    try
        [img_elastic(:,:,j),~] = elastic_deformation(inputImage, [], SIGMA, alpha, geotrans_type{geotrans_idx}, ...
                                alpha_geotrans, poly_degree, showfig_points);
    catch ME
        warning(ME.identifier, 'Distortion points problem: %s', ME.message);
    end                               
end

end