using PlutoUI, Plots, Statistics, Optim, JuMP, Ipopt, ForwardDiff

begin
println(".oOo.oOo.oOo.oOo.oOo.oOo.oOo.")

fitness((a,b)) = 2+a^2
r = optimize(fitness,[0.0,0.0])

#--- Optim ---

n = 10
x = sort((rand( -10:100, n)))
y = 5/9 .* x  .- 17.7777777  .+  10.2 .* randn.()

function repeat_experiment(r)
    least_squares = []
    results = []
    for i in 1:r
        y = 5/9 .* x  .- 17.7777777  .+  1.0 .* randn.()
        # least square
        loss((b,m)) = sum( (b + m*x[i] - y[i])^2  for i=1:n ) 
        r = optimize(loss,[0.0,0.0])
        push!(results, r)
        push!(least_squares,minimum(r))
    end
    return least_squares, results
end

least_squares ,results = repeat_experiment(1_000)
end

intercepts = []
slopes = []
for i in 1:1000
    push!(intercepts,results[i].minimizer[1])
    push!(slopes, results[i].minimizer[2])
end

#histogram(intercepts)
#histogram(slopes)
println(mean(intercepts))
println(mean(slopes))


#--- JuMP ---

let
	
	n = length(x)
	model = Model(Ipopt.Optimizer)
	
	@variable(model, b)
	@variable(model, m)

    @objective(model, Min, sum( (b + m*x[i] - y[i])^2 for i in 1:n) )

	#set_silent(model)
	optimize!(model)
	
	(b=getvalue(b), m=getvalue(m))
end
