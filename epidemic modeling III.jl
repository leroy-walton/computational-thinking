using Plots

function finite_difference_slope(f::Function, a, h=1e-3)
	( f(a+h) - f(a) ) / h
end

function tangent_line(f, a, h)
	slope = finite_difference_slope(f,a,h)
	b = f(a)-slope*a
	t(x) = slope * x + b
	return t
end

function euler_integrate_step(fprime::Function, fa::Number, 
    a::Number, h::Number)
    h*fprime(a+h)+fa
end

function euler_integrate(fprime::Function, fa::Number, 
    T::AbstractRange)

    a0 = T[1]
    h = step(T)
    values = []
    faih = fa
    for i in 1:size(T)[1]
        faih = euler_integrate_step(fprime, faih, a0, h)
        push!(values,faih)
        a0=T[i]
    end
    return values
end

function euler_SIR_step(β, γ, sir_0::Vector, h::Number)
	s, i, r = sir_0
	
	a = β * s * i
	b = γ * i
	
	return [
		s - h * a,
		i + h * (a-b),
		r + h * b
	]
end

function euler_SIR(β, γ, sir_0::Vector, T::AbstractRange)
	# T is a range, you get the step size and number of steps like so:
	h = step(T)
	num_steps = length(T)
	values = []
	sir_i = sir_0
	for i in 1:num_steps
		sir_i = euler_SIR_step(β, γ, sir_i, h)
		push!(values,sir_i)
	end
	
	return values
end

function plot_sir!(p, T, results; label="", kwargs...)
	s = getindex.(results, [1])
	i = getindex.(results, [2])
	r = getindex.(results, [3])
	
	plot!(p, T, s; color=1, label=label*" S", lw=3, kwargs...)
	plot!(p, T, i; color=2, label=label*" I", lw=3, kwargs...)
	plot!(p, T, r; color=3, label=label*" R", lw=3, kwargs...)
	
	p
end

sir_T = 0 : 0.1 : 60.0
sir_results = euler_SIR(0.3, 0.15, 	[0.99, 0.01, 0.00], sir_T)

plot_sir!(plot(), sir_T, sir_results)

# ** Numerical gradient ** Partial Derivatives **





