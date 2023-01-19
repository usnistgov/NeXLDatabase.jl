using HTTP
using JSON
"""
Cordra is a structure for interacting with a Cordra digital object management system.  See
https://www.cordra.org/ for details.  This implementation assumes that the user will
log in with a password and then uses a Cordra-provided token to expidite access. When you 
are done interacting with Cordra, use the `logout(...)` function to invalidate the token.
"""
struct Cordra
    username::String
    password::String
    url::String
    token::String

    function Cordra(url::AbstractString, user::AbstractString, pass::AbstractString)
        # Log in and get an "access_token" that we will use later
        params = Dict("grant_type"=>"password", "username"=>user, "password"=>pass)
        result = HTTP.request("POST", url*"/auth/token", [ "Content-Type" => "application/json"], JSON.json(params), require_ssl_verification = false)
        token = JSON.parse(String(result.body))["access_token"]
        new(user, pass, url, token)
    end
end

function logout(cordra::Cordra)
    HTTP.post(cordra, "/auth/revoke", Dict("token"=>cordra.token))
    @info "You have been logged out of $(cordra.url).  Future attempts at access using this instance will fail."
end

function HTTP.request(cordra::Cordra, action::AbstractString, command::AbstractString, params::AbstractDict{String,String}=Dict{String,String}())
    HTTP.request(action, cordra.url*command, [ "Content-Type" => "application/json", "Authorization"=> "Bearer "*cordra.token ], JSON.json(params), require_ssl_verification = false)
end

function HTTP.get(cordra::Cordra, command::AbstractString, params::AbstractDict{String,String}=Dict{String,String}())
    HTTP.request(cordra, "GET", command, params)
end

function HTTP.put(cordra::Cordra, command::AbstractString, params::AbstractDict{String,String}=Dict{String,String}())
    HTTP.request(cordra, "PUT", command, params)
end

function HTTP.post(cordra::Cordra, command::AbstractString, params::AbstractDict{String,String}=Dict{String,String}())
    HTTP.request(cordra, "POST", command, params)
end

function HTTP.delete(cordra::Cordra, command::AbstractString, params::AbstractDict{String,String}=Dict{String,String}())
    HTTP.request(cordra, "DELETE", command, params)
end

"""
search(cordra::Cordra, query::AbstractString)

Example:

    search(c, "/name:Ritchie")
"""
function search(cordra::Cordra, query::AbstractString)
    HTTP.post(cordra, "/search", Dict("query"=>query))
end


function getobject(cordra::Cordra, id::AbstractString)
    HTTP.get(cordra, "/objects/"*id)
end

function asJSON(resp::HTTP.Messages.Response)
    JSON.parse(String(resp.body))
end