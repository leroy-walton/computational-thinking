using Plots, PlutoUI, DataFrames, CSV, GLM, Statistics, LinearAlgebra, Distributions
println("bleh")

n = 10
x = sort((rand( -10:100, n)))
y = 5/9 .* x  .- 17.7777777 #  same as y =  5/9 .* (x .- 32)

begin	
	plot(x,y, m=:c, mc=:red,legend=false)
	xlabel!("°F")
	annotate!(-4,16,text("°C",11))
	plot!( x, (x.-30)./2) #Dave's cool approximation
end

# DataFrame

data = DataFrame(°F=x,°C=y) # Label = data
begin
	data2 = DataFrame([x  y]) # convert Matrix to DataFrame
    rename!(data2,["°F","°C"]) # add column labels
end

Matrix(data2) # Convert back to a matrix (lose label information)

# CSV save and load

CSV.write("testCSVwrite.csv", data)
data_again = CSV.read("testCSVwrite.csv", DataFrame ) 
data_again[:,"°F" ] #or data_again[:,1]

# Add some random noise to the celsius readings

noise = 7 # slider 0 -> 1000


begin
	noisy_data = copy(data)  # Noisy DataFrame
	noisy_data[:, "°C" ] .+= noise * randn(n)
	yy = noisy_data[:, "°C" ]
	noisy_data
end




function linear_regression(x,y)   # a direct computation from the data
	n = length(x)
	x0  = x.-mean(x)
	y0 = y.-mean(y)
	
	mᵉ = sum( x0 .* y0 ) / sum(  x0.^2 ) # slope estimate
	bᵉ = mean(y) - mᵉ * mean(x) # intercept estimate
	
	s2ᵉ = sum(  (mᵉ.*x .+ bᵉ .- y).^2 ) /(n-2) # noise estimate
	bᵉ,mᵉ,s2ᵉ
end

b, m = [ one.(x) x]\ yy  # The mysterious linear algebra solution using "least squares"
mᵉ, bᵉ, σ²ᵉ =  linear_regression(x, yy)


	
scatter(x, yy,m=:c,mc=:red, label="noisy data", ylims=(-40,40))
for i=1 : length(data[:,2])
	plot!([x[i],x[i]], [m*x[i]+b,yy[i]], color=:gray, ls=:dash, label=false)
end
xlabel!("°F")
annotate!(-15,16,text("°C",11))
plot!(x, m.*x .+ b,  color=:blue, label="best fit line")
plot!(x,y,alpha=.5, color=:red, label="theory") # theoretical 
plot!(legend=:top)


#=
Step I:  The Model is y = m*x + b + σ*randn() . 
This means that out there in the real world are b, m, and σ.  You
don't know them.  

Step II: You do, however, have data points x and y which allow you
to compute an bᵉ,  mᵉ, and σᵉ.  A statistician would call these estimates
based on your data points. If you ran the experiment again, you would
get different data points.

The computer lets us run the experiment as many times as we want just to 
see what happens.

    In summary, there are three kinds of variables.  The model variables b, m,
     and σ which are unknown.  The predictor variable x which is considered 
     fixed and known.  The response variable y which is considered noisy.
=#

ols = lm(@formula(°C ~ °F), noisy_data)

println(ols)
noisy_data

b, m = [ one.(x) x]\ yy 


function linear_regression(x,y)   # a direct computation from the data
	n = length(x)
    # center to origin
	x0  = x.-mean(x)     
	y0 = y.-mean(y)

	mᵉ = sum( x0 .* y0 ) / sum(  x0.^2 ) # slope estimate
	bᵉ = mean(y) - mᵉ * mean(x) # intercept estimate
	
	s2ᵉ = sum(  (mᵉ.*x .+ bᵉ .- y).^2 ) /(n-2) # noise estimate
	bᵉ,mᵉ,s2ᵉ
end

b1,m1,s1 = linear_regression(x,yy)

println("Noise Estimate : {$s1}")

p = plot(x,y, label = "theory", color=:blue)
scatter!(p, x,yy , label="noisy")
plot!(p, x, m1*x .+ b1, label="fit", color=:red)
for i=1 : length(x)
    plot!([x[i],x[i]], [m1*x[i]+b1,yy[i]], color=:gray, ls=:dash, label=false)
end
xlabel!("°F")

# running many noisy models

howmany = 100_000

function simulate(σ,howmany)
	[linear_regression(x,y .+ σ * randn(length(x)))   for i=1:howmany]
	#[linear_regression(x,y .+ (σ * sqrt(12)) * (-.5 .+ rand(length(x))))   for i=1:howmany]
	#[linear_regression(x,y .+ (σ ) * ( rand([-1,1],length(x))))   for i=1:howmany]
end

σ = 1.2   # noise coef.
s = simulate(σ, howmany)

# plot distribution of intercept
begin	
	histogram( first.(s) , alpha=.6, bins=100, norm=true)
	vline!([-17.777777],color=:white)
	title!("intercept")
	xlims!(-17.7777-3,-17.7777+3)
	ylims!(0,1)
	plot!(legend=false)
	
end


mean(first.(s))  # Experimental mean of the intercept
std( first.(s))  # Experimental std of the intercept
# Statisticians know an exact formula for the theoretical std of the intercept
sb = σ * norm(x)  / norm(x.-mean(x)) / sqrt(n)


# Simulated slopes (100000 simulations)
begin
	histogram( getindex.(s,2), alpha=.6, bins=100, norm=true )
	title!("slope")
	vline!([5/9],color=:white)
	xlims!(5/9-.1, 5/9+.1)
	ylims!(0,60)
end

mean(getindex.(s,2)) # Sample mean of the slope 0.55555
std( getindex.(s,2)) # Sample std of the slope.  
σ  / norm(x.-mean(x)) # Statisticians know a formula for the theoretical std of the slope.

# Simulated σ (100000 simulations)
begin	
	histogram( last.(s) ./ (σ^2/(n-2)) , alpha=.6, bins=100, norm=true)
	vline!([1],color=:white)
	title!("residual")
	vline!([n-2],color=:white, lw=4)
	#xlims!(0,20)
	#ylims!(0,.13)
	plot!( x-> pdf(Chisq(n-2),x) , lw=4 , color=:red )
	plot!()
end

mean( last.(s)  )
σ^2

std(last.(s))
(σ^2/ sqrt((n-2)/2))

