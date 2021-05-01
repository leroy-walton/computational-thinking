using Plots, PlotThemes

theme(:juno)

struct Coordinate
	x::Int64
	y::Int64
end

function make_tuple(c)
	(c.x, c.y)
end

function Base.:+(a::Coordinate, b::Coordinate)
	Coordinate(a.x+b.x,a.y+b.y)
end

possible_moves = [
	Coordinate( 1, 0), 
	Coordinate( 0, 1), 
 	Coordinate(-1, 0), 
 	Coordinate( 0,-1),
]

function trajectory(w::Coordinate, n::Int)
	random_moves = rand(possible_moves,n)
	pushfirst!(random_moves,w)
	trajectory = accumulate(+,random_moves)
	popfirst!(trajectory)
	trajectory
end

function plot_trajectory!(p::Plots.Plot, trajectory::Vector; kwargs...)
	plot!(p, make_tuple.(trajectory); 
		label=nothing, 
		linewidth=2, 
		linealpha=LinRange(1.0, 0.2, length(trajectory)), kwargs...)
end

let
    long_trajectory = trajectory(Coordinate(4,4), 1000)

    p = plot(ratio=1)
    plot_trajectory!(p, long_trajectory)
    p
end

let
	p = plot(ratio=1)
	
	trajectories = [ trajectory(Coordinate(4,4), 1000) for _ in 1:10 ]
	
	for traj in trajectories 
		plot_trajectory!(p,traj)
	end
	p
end

function collide_boundary(c::Coordinate, L::Number)
	cx = c.x
	cy = c.y
	
	if cx < -L
		cx = -L
	end
	if cy < -L
			cy = -L
	end
	if cx > L
		cx = L
	end
	if cy > L
		cy = L
	end
	Coordinate(cx,cy)
end

function trajectory(c::Coordinate, n::Int, L::Number)

	random_moves = rand(possible_moves,n)
	pushfirst!(random_moves,w)
	trajectory = accumulate( (c1,c2) -> collide(c1+c2) ,random_moves)
	popfirst!(trajectory)
	trajectory
	
end

@enum InfectionStatus S I R

mutable struct Agent
	position::Coordinate
	status::InfectionStatus
	num_infected::Int64
end

function initialize(N::Number, L::Number)
	agents=[]
	for _ in 1:N
		c = Coordinate(rand(-L:L), rand(-L:L) )
		a = Agent(c,S::InfectionStatus,0)
		push!(agents,a)
	end

	agents[rand(1:N)].status = I::InfectionStatus
	return agents
end

color(s::InfectionStatus) = if s == S
	RGB(0.8,0.8,0.0)
elseif s == I
	"red"
else
	"green"
end

position(a::Agent) = a.position
color(a::Agent) = color(a.status)

function visualize(agents::Vector, L)
	p = plot(ratio=1,xlims=(-L-1,L+1), ylims=(-L-1,L+1) )
	c = color.(agents)
	for a in agents
		scatter!(p,[a.position.x],[a.position.y];c=color(a),labels=false)
	end
	p
end

let
	N = 20
	L = 10
	visualize(initialize(N, L), L) # uncomment this line!
end

abstract type AbstractInfection end

struct CollisionInfectionRecovery <: AbstractInfection
	p_infection::Float64
	p_recovery::Float64
end

function interact!(agent::Agent, source::Agent, infection::CollisionInfectionRecovery)
	if agent.position == source.position
		if source.status == I && agent.status == S
		# Chance of infection
			if rand() < infection.p_infection
				agent.status = I
				source.num_infected += 1
			end
		end
		if agent.position == source.position
			if agent.status == I
			# Chance of recovery
				if rand() < infection.p_recovery
					agent.status = R
				end
			end
		end
	end
end

function step!(agents::Vector, L::Number, infection::AbstractInfection)

	a = rand(agents)
	a.position = collide_boundary(a.position+rand(possible_moves), L)
	#interact
    for other in agents
		if other !== a
			interact!(a,other,infection)
		end
	end
	agents
end

pandemic = CollisionInfectionRecovery( 0.3, 0.01 )
k_sweeps = 10000

let
    N = 50
    L = 40
    x = initialize(N, L)    
    Ss, Is, Rs = Int[], Int[], Int[]
    Tmax = 200
    
    @gif for t in 1:Tmax
        for i in 1:50N
            step!(x, L, pandemic)
        end

        #... track S, I, R in Ss Is and Rs
		push!(Ss, count( a->a.status==S, x  ) )
		push!(Is, count( a->a.status==I, x  ) )
		push!(Rs, count( a->a.status==R, x  ) )
        
        left = visualize(x, L)
    
        right = plot(xlim=(1,Tmax), ylim=(1,N), size=(600,300))
        plot!(right, 1:t, Ss, color=color(S), label="S")
        plot!(right, 1:t, Is, color=color(I), label="I")
        plot!(right, 1:t, Rs, color=color(R), label="R")
    
        plot(left, right)
    end
end

