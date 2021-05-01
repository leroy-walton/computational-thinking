using Plots, PlutoUI, HypertextLiteral, LightGraphs, GraphPlot, Printf, SpecialFunctions

f(x,t) =  exp(-x^2/t)/√(π*t)

t = 0.70

x = -3 : .01 : 3 
plot( x, f.(x,t), ylims=(0,1), legend=false)

begin
	surface(-2:.05:2, .2:.01:1, f, alpha=.4, c=:Reds, legend=false)
	for t = .2 : .1 :1
		plot!(-2:.05:2, fill(t,length(-2:.05:2)),  f.(-2:.05:2,t), c=:black)
	end
	xlabel!("x")
	ylabel!("t")
	plot!()
end


