function makeNoiseBackground_online()
% MAKENOISEBACKGROUND_ONLINE  Builds the static phase-scrambled background
% for the online overlay experiment (Exp2.html) and saves it as a PNG in
% imDir. Run it once; the HTML only loads the file.
%
% Same method as makeNoiseBackground_test (SSVEP version):
%   1. Load the objects (greyscale, padded square), with the white surround
%      replaced by grey srcBg, and resize each to the object box.
%   2. Average the AMPLITUDE spectra across objects.
%   3. Resample that spectrum onto the backdrop's frequency grid (cycles per
%      pixel) and combine it with random phases.
%   4. Match the luminance histogram to the objects' pooled pixels.
%
% Differences from the SSVEP version:
%   - Uses ALL 25 images (5 categories x 5 appearances). Online, the
%     appearance letters are counterbalanced across participants, so a
%     background built from every image is the same for everyone and is not
%     tied to any one condition.
%   - Objects are taken at objContrast, the contrast the online task draws
%     them at (Exp2.html applies it as layer opacity under multiply, which
%     is the same 1 - k*(1 - img) used here).
%   - Sizes are the CSS px values from Exp2.html (stimSize, overlaySize).
%     The backdrop is #overlayWrap, the box the multiply blend composites
%     against, so the noise is overlaySize square.

% ---- settings (keep in sync with Exp2.html) ------------------------------
imDir       = 'Objects_matched';           % imDir in Exp2.html
imExt       = '.png';                      % imExt
nCategories = 5;                           % nCategories
letters     = {'a', 'b', 'c', 'd', 'e'};   % all nObjects appearances
stimSize    = 280;                         % CSS px, object box
noiseContrast = 0.6;
objContrast = 0.6;                         % objContrast in Exp2.html
overlaySize = 380;                         % CSS px, #overlayWrap
renderScale = 2;     % build at 2x so it stays sharp on high-DPI screens;
                     % shown at overlaySize CSS px, so spatial frequency
                     % per CSS px still matches the objects
srcBg       = 0.5;   % grey surround for the noise source only; use the
                     % same value as P.noiseSourceBg in the SSVEP version
noiseSeed   = 1;     % fixed seed: identical background for everyone
outFile     = fullfile(imDir, ['noise_bg' imExt]);
% --------------------------------------------------------------------------

S = stimSize * renderScale;
B = overlaySize * renderScale;
nIm = nCategories * numel(letters);

% 1. objects at the object-box size
imgs = zeros(S, S, nIm);
n = 0;
for c = 1:nCategories
    for l = 1:numel(letters)
        n = n + 1;
        f = fullfile(imDir, sprintf('obj%d%s%s', c, letters{l}, imExt));
        imgs(:, :, n) = resizeSquare(loadGray(f, srcBg, objContrast), S);
    end
end

% 2. average amplitude spectrum (mean removed; mean luminance is set in step 4)
A = zeros(S);
for k = 1:nIm
    im = imgs(:, :, k);
    A  = A + abs(fft2(im - mean(im(:))));
end
A = fftshift(A / nIm);

% 3. resample onto the backdrop's frequency grid, then random phase
fS = ((0:S-1) - floor(S/2)) / S;          % cycles per pixel, fftshift order
fB = ((0:B-1) - floor(B/2)) / B;
[xS, yS] = meshgrid(fS);
[xB, yB] = meshgrid(fB);
AB = interp2(xS, yS, A, xB, yB, 'linear', 0);
rng(noiseSeed);
phase = angle(fft2(randn(B)));            % random phases with the symmetry of a real image
noise = real(ifft2(ifftshift(AB) .* exp(1i * phase)));

% 4. histogram match to the objects' pooled pixels
pooled = sort(imgs(:));
target = pooled(round(linspace(1, numel(pooled), B*B)));
[~, idx] = sort(noise(:));
bg = zeros(B);
bg(idx) = target;
m  = mean(bg(:));
bg = m + noiseContrast * (bg - m);

imwrite(uint8(round(bg * 255)), outFile);
fprintf('Saved %s (%d x %d px, shown at %d CSS px). Mean luminance %.3f (objects %.3f).\n', ...
        outFile, B, B, overlaySize, mean(bg(:)), mean(imgs(:)));

figure('Name', 'Noise background');
imagesc(bg, [0 1]); colormap(gray(256)); axis image off;
end

%--------------------------------------------------------------------------
function img = loadGray(f, bgLevel, k)
% greyscale with the browser's grayscale() weights, at contrast factor k
% (as in the task), surround set to bgLevel
[img, map, alpha] = imread(f);
if ~isempty(map), img = ind2rgb(img, map); else, img = toUnit(img); end
if size(img, 3) == 3
    img = 0.2126*img(:,:,1) + 0.7152*img(:,:,2) + 0.0722*img(:,:,3);
end
if ~isempty(alpha)
    alpha = toUnit(alpha);
    img = 1 - k * (1 - img);                      % contrast factor, as in the task
    img = alpha .* img + (1 - alpha) * bgLevel;   % transparent areas -> grey
else
    surround = img >= 0.99;                       % no transparency: pure white is the surround
    img = 1 - k * (1 - img);
    img(surround) = bgLevel;
end
% pad to square, centred (as background-size: contain in the HTML)
[h, w] = size(img); n = max(h, w);
sq = bgLevel * ones(n);
r0 = floor((n - h)/2); c0 = floor((n - w)/2);
sq(r0 + (1:h), c0 + (1:w)) = img;
img = sq;
end

function out = resizeSquare(img, S)
if exist('imresize', 'file')
    out = imresize(img, [S S]);           % antialiased (Image Processing Toolbox)
else
    n = size(img, 1);
    [x, y] = meshgrid(linspace(1, n, S));
    out = interp2(img, x, y, 'linear');
end
out = min(max(out, 0), 1);
end

function x = toUnit(x)
if isinteger(x), x = double(x) / double(intmax(class(x))); else, x = double(x); end
end