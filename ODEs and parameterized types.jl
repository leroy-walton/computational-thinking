using DifferentialEquations
using Plots

#using MappedArrays

f(u, p, t) = -p * u

p= -1
u0 = 1.0
time_span = (0.0, 10.0)

problem = ODEProblem(f, u0, time_span, p)
solution = solve(problem)
plot(solution)

solution(3.0) 
exp(3.0)
