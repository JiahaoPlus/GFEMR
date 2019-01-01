function [V] = GFEMR(X, Y, beta, lambda1, lambda2, anneal, sigma0, iter_num, N0, is_grad)

N = size(X,1); 
idx = randperm(N); idx = idx(1:min(N0,N)); ctrl_X=X(idx,:);
K=con_K(ctrl_X, ctrl_X, beta);
U = con_K(X, ctrl_X, beta);

x0 = zeros(N0*2, 1);%/N^2;
sigma = sigma0; 

%compute the graph laplacian matrix A 
r = 0.05;%0.05
X2= sum(X.^2,2);   %N*1
distance = repmat(X2,1,N)+repmat(X2',N,1)-2*X*X';
index = find(distance(:) < r);
W = zeros(N*N,1);
W(index) = exp(-distance(index)/r);
W = reshape(W,N,N);
Dia = sum(W, 2);
A = diag(Dia) - W; %N*N

%%
options = optimset( 'display','off', 'MaxIter', 5);%50
if is_grad
%     options = optimset(options, 'GradObj', 'on');
%     options = optimoptions('fminunc','Algorithm','quasi-newton');
    options = optimset('GradObj','on','Algorithm','trust-region');
end

param = fminunc(@(x)costfun_Manifold(x, X, Y, K, U, N0, lambda1, lambda2, sigma, is_grad, A), x0, options);

for ii = 1:iter_num     % iter_num=1
    sigma = sigma*anneal;
    param = fminunc(@(x)costfun_Manifold(x, X, Y, K, U, N0, lambda1, lambda2, sigma, is_grad, A), param, options);
end

C = param(1:end);
C = reshape(C, [N0 2]); 
V = X + U*C;
