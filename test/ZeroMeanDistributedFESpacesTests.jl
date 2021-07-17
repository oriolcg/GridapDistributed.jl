module ZeroMeanDistributedFESpacesTests

using Gridap
using GridapDistributed
using Gridap.FESpaces
using Test

subdomains = (2,2)
SequentialCommunicator(subdomains) do comm
  domain = (0,1,0,1)
  cells = (4,4)
  model = CartesianDiscreteModel(comm,subdomains,domain,cells)
  nsubdoms = prod(subdomains)
  vector_type = Vector{Float64}
  reffe = ReferenceFE(lagrangian,Float64,1)
  V = FESpace(vector_type,
              model=model,
              reffe=reffe,
              degree=1,
              constraint=:zeromean)
  fv=zero_free_values(V)
  fv .= rand(length(fv))
  vh=FEFunction(V,fv)

  # Error norms and print solution
  sums = DistributedData(model, vh) do part, (model, gids), vh
    trian = Triangulation(model)
    owned_trian = remove_ghost_cells(trian, part, gids)
    dΩ = Measure(owned_trian, 1)
    sum(∫(vh)dΩ)
  end
  mean = sum(gather(sums))
  tol = 1.0e-10
  if (i_am_master(comm)) println("$(abs(mean)) < $(tol)\n") end
  @test abs(mean) < tol
end

end # module
