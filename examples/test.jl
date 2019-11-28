using Random
using HEAAN
using HEAAN: hexfloat, MyRNG, randomComplexArray


function compare_str(res::Float64, ref::Float64)
    s = "$(hexfloat(res)) $(hexfloat(ref)) "

    c = compare(res, ref)
    if c == 0
        "$s Exp mismatch!"
    else
        "$s $c bits match"
    end
end


function coinciding_bits(x::Float64, y::Float64)
    log_diff = floor(Int, -log2(abs(x - y)))
    log_diff >= 0 ? log_diff : 0
end


coinciding_bits(x::Array{Complex{Float64}}, y::Array{Complex{Float64}}) =
    vcat(coinciding_bits.(real.(x), real.(y)), coinciding_bits.(imag.(x), imag.(y)))


mean(x) = sum(x) / length(x)


std(x) = sqrt(sum((x .- mean(x)).^2) / (length(x) - 1))


function print_statistics(x::Array{Complex{Float64}}, y::Array{Complex{Float64}})
    for i in 1:length(x)
        println(real(x[i]), " ", real(y[i]))
        println(imag(x[i]), " ", imag(y[i]))
    end
    bits = coinciding_bits(x, y)
    println("Coinciding bits: min=$(minimum(bits)) max=$(maximum(bits)) mean=$(mean(bits)) std=$(std(bits))")
end


function test_encrypt()

    n = 2^6
    log_precision = 30
    log_cap = 100

    #rng = MersenneTwister(12345)
    rng = MyRNG(12345)
    params = Params(log_polynomial_length=8, log_lo_modulus=300)

    secret_key = SecretKey(rng, params)

    enc_key = EncryptionKey(rng, secret_key)

    mvec = randomComplexArray(rng, n) # randn(rng, n) + im * randn(rng, n)

    cipher = encrypt(rng, enc_key, mvec, log_precision, log_cap)

    dvec = decrypt(secret_key, cipher)

    print_statistics(mvec, dvec)
end


test_encrypt()
