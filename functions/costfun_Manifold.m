function [E, G] = costfun_Manifold(param, X, Y, K, U, N0, lambda1, lambda2, sigma, is_grad, A)

C = reshape(param, [N0 2]);

T = X+U*C;

F = exp(-sum((Y-T).^2,2)/sigma^2);
E = lambda1*trace(C'*K*C) + lambda2*trace(T'*A*T) - sum(F(:));


%%
G = [];
if is_grad
    tmp = bsxfun(@times, U, F)' * bsxfun(@minus, T, Y);
    G = 2*lambda1*K*C + 2*lambda2*U'*A*T + tmp*2/sigma^2;
    G = G(:);
end
