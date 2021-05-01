using Plots
using Statistics

function bernoulli(p::Number)
	return rand()<=p
end

function recovery_time(p)
	if p ≤ 0
		throw(ArgumentError("p must be positive: p = 0 cannot result in a recovery"))
	end
	t=1
	while !bernoulli(p)
		t+=1
	end
	return t
end

function do_experiment(p, N)
	return [ recovery_time(p) for _ in 1:N]
end

function frequencies(values)
	nbr_values = length(values)
	d = Dict()
	
	for key in values
		if haskey(d,key)
			d[key]+=1
		else 
			d[key]=1
		end
	end
	for (key,value) in d
		d[key]=d[key]/nbr_values
	end
	return d
end

large_experiment = do_experiment(0.25, 1_000) 
b = frequencies(large_experiment)
histogram(b)

sum(large_experiment)/length(large_experiment)

@enum InfectionStatus S I R

mutable struct Agent
	status::InfectionStatus
	num_infected::Int64
end
function Agent()
    Agent(S,0)
end

function set_status!(agent::Agent, new_status::InfectionStatus)
	agent.status = new_status
end

function set_num_infected!(agent::Agent, num_infected::Number)
	agent.num_infected = num_infected
end

function is_susceptible(agent::Agent)
	agent.status == S
end

function is_infected(agent::Agent)
	agent.status == I
end

function is_recovered(agent::Agent)
	agent.status == R
end

function generate_agents(N::Integer)
	agents = [Agent() for _ in 1:N ]
	w = rand(1:N)
	set_status!(agents[w],I)
	agents
end

abstract type AbstractInfection end

struct InfectionRecovery <: AbstractInfection
	p_infection
	p_recovery
end

function interact!(agent::Agent, source::Agent, infection::InfectionRecovery)
if is_susceptible(agent) && is_infected(source) && bernoulli(infection.p_infection)
     set_status!(agent,I)
     set_num_infected!(source,source.num_infected  + 1)
 elseif is_infected(agent) && bernoulli(infection.p_recovery)
     set_status!(agent,R)
 end
end

function interact!(agent::Agent, source::Agent, infection::Reinfection)
	if is_susceptible(agent) && is_infected(source) && bernoulli(infection.p_infection)
		 set_status!(agent,I)
		 set_num_infected!(source,source.num_infected  + 1)
	 elseif is_infected(agent) && bernoulli(infection.p_recovery)
		 set_status!(agent,S)
	 end
end

agent = Agent(I, 9)
source = Agent(S, 0)

println("source $agent , agent $source")
interact!(agent, source, InfectionRecovery(1.0, 1.0))

println("source $agent , agent $source")

function step!(agents::Vector{Agent}, infection::AbstractInfection)
	source = rand(agents)
	agent = rand(agents)
	interact!(agent, source, infection)
	agents
end

function sweep!(agents::Vector{Agent}, infection::AbstractInfection)
	for _ in 1:length(agents)
			step!(agents, infection)
	end
end

function simulation(N::Integer, T::Integer, infection::AbstractInfection)
	agents = generate_agents(N)
	avg_I = []
	avg_R = []
	avg_S = []
	for _ in 1:T
		sweep!(agents,infection)
		push!(avg_I, count(is_infected, agents) )
		push!(avg_R, count(is_recovered, agents) )
		push!(avg_S, count(is_susceptible, agents) )
	end
	
	return (S=avg_S, I=avg_I, R=avg_R)
end

#simulation(100, 1000, InfectionRecovery(0.905, 0.2))

#=
let

	N = 100
	T = 1000
	sim = simulation(N, T, InfectionRecovery(0.02, 0.002))
	
	result = plot(1:T, sim.S, ylim=(0, N), label="Susceptible")
	plot!(result, 1:T, sim.I, ylim=(0, N), label="Infectious")
	plot!(result, 1:T, sim.R, ylim=(0, N), label="Recovered")
end
=#

function repeat_simulations(N, T, infection, num_simulations)
	N = 100
	T = 1000
	
	map(1:num_simulations) do _
		simulation(N, T, infection)
	end
end

simulations = repeat_simulations(100, 1000, InfectionRecovery(0.02, 0.002), 20)
let
	p = plot()
	
	for sim in simulations
		plot!(p, 1:1000, sim.I, alpha=.5, label=nothing)
	end
	
	p
end

function sir_mean_plot(simulations::Vector{<:NamedTuple})
	# you might need T for this function, here's a trick to get it:
	T = length(first(simulations).S)
	nbr_sim = length(simulations)
	avg_I = []
	avg_R = []
	avg_S = []

	for i in 1:T
		avgr = 0
		avgs = 0
		avgi = 0
		for sim in simulations
			avgs += sim.S[i]
			avgr += sim.R[i]
			avgi += sim.I[i]
		end
		avgr /= nbr_sim
		avgs /= nbr_sim
		avgi /= nbr_sim

		push!(avg_R , avgr )
		push!(avg_S , avgs )
		push!(avg_I , avgi )
	end
	p = plot()

	plot!(p, 1:T, avg_S, label="S")
	plot!(p, 1:T, avg_I, label="I")
	plot!(p, 1:T, avg_R, label="R")
	
	return p
end

function sir_mean_error_plot(simulations::Vector{<:NamedTuple})

	p = sir_mean_plot(simulations)
	
	# you might need T for this function, here's a trick to get it:
	T = length(first(simulations).S)
	nbr_sim = length(simulations)
	std_I = []
	std_R = []
	std_S = []
	tmp_I = []
	for i in 1:T
		#tmp_I = []
		tmp_R = []
		tmp_S = []
		
		
		push!(tmp_I, Statistics.std([ sim.I[i] for sim in simulations ]))
		
	end
	return plot( 1:T, tmp_I)
end


sir_mean_error_plot(simulations)

