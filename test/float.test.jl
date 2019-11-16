using Random
using DarkIntegers
using HEAAN


function shift_bigfloat(x::BigFloat, shift::Int)
    # TODO: in NTL it's `MakeRR(x.x, x.e + shift)`,
    # but Julia does not give access to the significand.
    # Kind of hacky, but will work for now.
    xc = copy(x)
    xc.exp += shift
    xc
end


function float_to_integer_reference(x::Float64, shift::Int)
    r = BigFloat(x)
    xp = shift_bigfloat(r, shift)
    round(BigInt, xp)
end


function integer_to_float_reference(x::BigInt, shift::Int)
    xp = BigFloat(x)
    xp = shift_bigfloat(xp, -shift)
    convert(Float64, xp)
end


@testgroup "Float <-> integer conversions" begin


@testcase "Integer to float" begin
    rng = MersenneTwister(123)

    for i in 1:10000
        x = randn(rng) * 100

        shift = 20

        ref = float_to_integer_reference(x, shift)
        res = HEAAN.float_to_integer(BigInt, x, shift)

        if ref != res
            @test_fail "Converting $x, got $res, expected $ref"
            return
        end
    end
end


@testcase "Float to integer" begin
    rng = MersenneTwister(123)

    for i in 1:10000
        x = rand(rng, (-one(BigInt)<<100):(one(BigInt)<<100))

        shift = 20

        ref = integer_to_float_reference(x, shift)
        res = HEAAN.integer_to_float(Float64, x, shift)

        if ref != res
            @test_fail "Converting $x, got $res, expected $ref"
            return
        end
    end
end


end