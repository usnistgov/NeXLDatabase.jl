
struct Instrument
    vendor::String
    model::String
    location::String
    description::String
end

struct WDSDetector
    vendor::String
    model::String
    crystal::String # LIF/PET/etc
    dspacing::Float64
    start::Float64 # lower travel limit
    stop::Float # upper travel limit
end

struct EDSDetector
    vendor::String
    model::String
    type::String
    window::String
end
