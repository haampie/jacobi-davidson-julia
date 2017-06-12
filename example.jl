module Tst

import LinearMaps: LinearMap

using Plots

using JacobiDavidson:
  exact_solver,
  gmres_solver,
  jacobi_davidson,
  jacobi_davidson_hermetian,
  jacobi_davidson_nonhermetian,
  jacobi_davidson_harmonic,
  harmonic_ritz_test,
  LM, SM, Near

function alright_conditioned_matrix_with_separated_eigs(n::Int = 100)
  off_diag₁ = rand(n - 1)
  off_diag₂ = rand(n - 1)

  diags = (off_diag₁, linspace(3, 100, n), off_diag₂)
  spdiagm(diags, (-1, 0, 1))
end

function testing(;krylov = 10, expansions = 5)
  n = 300
  A = alright_conditioned_matrix_with_separated_eigs(n)
  B = LinearMap(A)

  exact = exact_solver()
  gmres = gmres_solver()
  target = Near(10.0 + 0.0im)

  @time jacobi_davidson(B, exact, krylov, expansions = expansions, target = target)
  @time jacobi_davidson(B, gmres, krylov, expansions = expansions, target = target)
end

function book_example()
  n = 1000

  A = spdiagm((fill(0.5, n - 1), linspace(1.0, n, n), fill(0.5, n - 1)), (-1, 0, 1))
  A[n, 1] = 0.5
  A[1, n] = 0.5

  v = fill(0.01 + 0.0im, n)
  v[end] = 1.0 + 0.0im

  ritz_his = jacobi_davidson_harmonic(
    A,
    # gmres_solver(iterations = 5),
    exact_solver(),
    pairs = 10,
    min_dimension = 10,
    max_dimension = 40,
    max_iter = 50,
    ɛ = 1e-8,
    target = Near(0.5),
    v0 = v
  )

  p = plot()
  for (k, thetas) = enumerate(ritz_his)
    @show norm(thetas)
    scatter!(real(thetas), k * ones(k))
  end
  p
end

function hermetian_example(; n = 200, min = 10, max = 30, )
  B = sprand(n, n, .2) + 100.0 * speye(n);
  B[1, 1] = 30.0
  A = Symmetric(B)

  exact = exact_solver()

  # @show eig(full(A))[1]

  @time D, X, res = jacobi_davidson_hermetian(
    LinearMap(A, isposdef = false),
    exact,
    min_dimension = min,
    max_dimension = max
  )

  X, D, res
end

function test_harmonic(; n = 100, τ = 2.0 + 0.01im)
  srand(4)

  A = spdiagm(
    (fill(-1.0, n - 1), 
    fill(2.0, n), 
    fill(-1.2, n - 1)), 
    (-1, 0, 1)
  )

  λs = real(eigvals(full(A)))

  Q, R, ritz_hist, conv_hist, residuals = harmonic_ritz_test(
    A,
    gmres_solver(iterations = 5),
    pairs = 10,
    min_dimension = 10,
    max_dimension = 15,
    max_iter = 300,
    ɛ = 1e-8,
    τ = τ
  )

  # Converged eigenvalues.
  @show diag(R)

  # Total number of iterations
  iterations = length(ritz_hist)

  @show iterations

  # Plot the target as a horizontal line
  p = plot([0.0, iterations + 1.0], [real(τ), real(τ)], linewidth=5, legend = :none, layout = (2, 1))

  # Plot the actual eigenvalues
  scatter!(fill(iterations + 1, n), λs, xlabel = "Iteration", ylims = (minimum(λs) - 2.0, maximum(λs) + 2.0), marker = (:diamond, :black), subplot = 1)
  
  # Plot the approximate eigenvalues per iteration
  for (k, (ritzvalues, eigenvalues)) = enumerate(zip(ritz_hist, conv_hist))
    scatter!(k * ones(length(ritzvalues)), real(ritzvalues), marker = (:+, :green), subplot = 1)
    scatter!(k * ones(length(eigenvalues)), real(eigenvalues), marker = (:hexagon, :yellow), subplot = 1)
  end

  plot!(residuals, xlabel = "Iteration", label = "Residual", xticks = 0.0 : 50.0 : 350.0, yaxis = :log10, subplot = 2)

  p
end
end