using PlutoUI, Plots, LinearAlgebra, SparseArrays

pascal(N) = [binomial(n, k) for n = 0:N, k=0:N]

l = LowerTriangular(pascal(10))
s = sparse(pascal(10))  
ss = sparse(isodd.(pascal(50) )  )
println(ss)



function evolve(p)
	p′ = similar(p)   # make a vector of the same length and type
	                  # to store the probability vector at the next time step
	
	for i in 2:length(p)-1   # iterate over the *bulk* of the system
		
		p′[i] = 0.5 * (p[i-1] + p[i+1])

	end
	
	# boundary conditions:
	p′[1] = 0
	p′[end] = 0
	
	return p′
end

function initial_condition(n)
	
	p₀ = zeros(n)
	p₀[n ÷ 2 + 1] = 1
	
	return p₀
end

function time_evolution(p0, N)
	ps = [p0]
	p = p0
	
	for i in 1:N
		p = evolve(p)
		push!(ps, copy(p))
	end
	
	return ps
end

grid_size = 101
p0 = initial_condition(grid_size)
ps = time_evolution(p0, 100)

tt=30

bar(ps[tt], ylim=(0, 1), leg=false, size=(500, 300), alpha=0.5)

M = reduce(hcat, ps)'

heatmap(M, yflip=true)

plotly()
surface(M)

gr()
ylabels = [-(grid_size÷2):grid_size÷2;]
begin
	plot(leg=false)
	
	for which in 1:15
		for i in 1:length(ps[which])
			plot!([which, which], [-grid_size÷2 + i, -grid_size÷2 + i], [0, ps[which][i] ], c=which, alpha=0.8, lw = 2)
		end
	end
	
	xlims!(1, 15)
	
	plot!()
end
