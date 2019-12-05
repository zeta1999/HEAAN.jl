using Random
using HEAAN
using HEAAN: hexfloat, MyRNG, randomComplexArray, randomCircle, randomComplex


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


function test_add()

    n = 2^6
    log_precision = 30
    log_cap = 100

    rng = MyRNG(12345)
    params = Params(log_polynomial_length=8, log_lo_modulus=300)

    secret_key = SecretKey(rng, params)

    enc_key = EncryptionKey(rng, secret_key)

    mvec1 = randomComplexArray(rng, n) # randn(rng, n) + im * randn(rng, n)
    mvec2 = randomComplexArray(rng, n) # randn(rng, n) + im * randn(rng, n)

    cipher1 = encrypt(rng, enc_key, mvec1, log_precision, log_cap)
    cipher2 = encrypt(rng, enc_key, mvec2, log_precision, log_cap)

    cipher_res = add(cipher1, cipher2)

    dvec = decrypt(secret_key, cipher_res)

    print_statistics(mvec1 .+ mvec2, dvec)

end


function test_add_const()

    n = 2^6
    log_precision = 30
    log_cap = 100

    rng = MyRNG(12345)
    params = Params(log_polynomial_length=8, log_lo_modulus=300)

    secret_key = SecretKey(rng, params)

    enc_key = EncryptionKey(rng, secret_key)

    mvec = randomComplexArray(rng, n) # randn(rng, n) + im * randn(rng, n)
    mconst = randomComplex(rng) # randn(rng, n) + im * randn(rng, n)

    cipher = encrypt(rng, enc_key, mvec, log_precision, log_cap)

    cipher_res = add_const(cipher, mconst)

    dvec = decrypt(secret_key, cipher_res)

    print_statistics(
        #im * (im * (mvec + real(mconst)) - imag(mconst)),
        mvec .+ mconst,
        dvec)

end


function test_mul()

    n = 2^6
    log_precision = 30
    log_cap = 100

    rng = MyRNG(12345)
    params = Params(log_polynomial_length=8, log_lo_modulus=300)

    secret_key = SecretKey(rng, params)

    enc_key = EncryptionKey(rng, secret_key)
    mul_key = MultiplicationKey(rng, secret_key)

    mvec1 = randomComplexArray(rng, n) # randn(rng, n) + im * randn(rng, n)
    mvec2 = randomComplexArray(rng, n) # randn(rng, n) + im * randn(rng, n)

    cipher1 = encrypt(rng, enc_key, mvec1, log_precision, log_cap)
    cipher2 = encrypt(rng, enc_key, mvec2, log_precision, log_cap)

    cipher_res = mul(mul_key, cipher1, cipher2)

    dvec = decrypt(secret_key, cipher_res)

    print_statistics(mvec1 .* mvec2, dvec)

end


function test_mul_const_complex()

    n = 2^6
    log_precision = 30
    log_cap = 100

    rng = MyRNG(12345)
    params = Params(log_polynomial_length=8, log_lo_modulus=300)

    secret_key = SecretKey(rng, params)

    enc_key = EncryptionKey(rng, secret_key)

    mvec = randomComplexArray(rng, n) # randn(rng, n) + im * randn(rng, n)
    mconst = randomComplex(rng) # randn(rng, n) + im * randn(rng, n)

    cipher = encrypt(rng, enc_key, mvec, log_precision, log_cap)

    cipher_res = mul_by_const(cipher, mconst, log_precision)

    dvec = decrypt(secret_key, cipher_res)

    print_statistics(mvec .* mconst, dvec)

end


function test_mul_const_vec()

    n = 2^6
    log_precision = 30
    log_cap = 300

    rng = MyRNG(12345)
    params = Params(log_polynomial_length=8, log_lo_modulus=300)

    secret_key = SecretKey(rng, params)

    enc_key = EncryptionKey(rng, secret_key)

    mvec = randomComplexArray(rng, n) # randn(rng, n) + im * randn(rng, n)
    cnst = randomComplexArray(rng, n) # randn(rng, n) + im * randn(rng, n)

    cipher = encrypt(rng, enc_key, mvec, log_precision, log_cap)

    cipher_res = mul_by_const_vec(cipher, cnst, log_precision)

    dvec = decrypt(secret_key, cipher_res)

    print_statistics(mvec .* cnst, dvec)

end



function test_imul()

    n = 2^6
    log_precision = 30
    log_cap = 100

    rng = MyRNG(12345)
    params = Params(log_polynomial_length=8, log_lo_modulus=300)

    secret_key = SecretKey(rng, params)

    enc_key = EncryptionKey(rng, secret_key)

    mvec = randomComplexArray(rng, n) # randn(rng, n) + im * randn(rng, n)

    cipher = encrypt(rng, enc_key, mvec, log_precision, log_cap)

    cipher_res = imul(cipher)

    dvec = decrypt(secret_key, cipher_res)

    print_statistics(mvec .* im, dvec)

end


function test_circshift()

    n = 2^6
    r = 2^4
    log_precision = 30
    log_cap = 100

    rng = MyRNG(12345)
    params = Params(log_polynomial_length=8, log_lo_modulus=300)

    secret_key = SecretKey(rng, params)

    enc_key = EncryptionKey(rng, secret_key)
    rot_key = LeftRotationKey(rng, secret_key, r)

    mvec = randomComplexArray(rng, n) # randn(rng, n) + im * randn(rng, n)

    cipher = encrypt(rng, enc_key, mvec, log_precision, log_cap)

    cipher_res = circshift(rot_key, cipher, -r)

    dvec = decrypt(secret_key, cipher_res)

    print_statistics(circshift(mvec, -r), dvec)

end


function test_conj()

    n = 2^6
    log_precision = 30
    log_cap = 300

    rng = MyRNG(12345)
    params = Params(log_polynomial_length=8, log_lo_modulus=300)

    secret_key = SecretKey(rng, params)

    enc_key = EncryptionKey(rng, secret_key)
    conj_key = ConjugationKey(rng, secret_key)

    mvec = randomComplexArray(rng, n) # randn(rng, n) + im * randn(rng, n)

    cipher = encrypt(rng, enc_key, mvec, log_precision, log_cap)

    cipher_res = conj(conj_key, cipher)

    dvec = decrypt(secret_key, cipher_res)

    print_statistics(conj.(mvec), dvec)

end


function test_power_of_2()

    n = 2^6
    log_degree = 4
    degree = 2^log_degree
    log_precision = 30
    log_cap = 300

    rng = MyRNG(12345)
    params = Params(log_polynomial_length=8, log_lo_modulus=300)

    secret_key = SecretKey(rng, params)

    enc_key = EncryptionKey(rng, secret_key)
    mul_key = MultiplicationKey(rng, secret_key)

    mvec = [randomCircle(rng) for i in 1:n] # randn(rng, n) + im * randn(rng, n)

    # Temporary replacement for bit-to-bit compatibility with the reference implementation.
    #mpow = mvec .^ degree
    mpow = copy(mvec)
    for i in 1:degree-1
        mpow .*= mvec
    end

    cipher = encrypt(rng, enc_key, mvec, log_precision, log_cap)

    cipher_res = power_of_2(mul_key, cipher, log_precision, log_degree)

    dvec = decrypt(secret_key, cipher_res)

    print_statistics(mpow, dvec)

end


function test_power()

    n = 2^6
    degree = 13
    log_precision = 30
    log_cap = 300

    rng = MyRNG(12345)
    params = Params(log_polynomial_length=8, log_lo_modulus=300)

    secret_key = SecretKey(rng, params)

    enc_key = EncryptionKey(rng, secret_key)
    mul_key = MultiplicationKey(rng, secret_key)

    mvec = [randomCircle(rng) for i in 1:n] # randn(rng, n) + im * randn(rng, n)

    # Temporary replacement for bit-to-bit compatibility with the reference implementation.
    #mpow = mvec .^ degree
    mpow = copy(mvec)
    for i in 1:degree-1
        mpow .*= mvec
    end

    cipher = encrypt(rng, enc_key, mvec, log_precision, log_cap)

    cipher_res = power(mul_key, cipher, log_precision, degree)

    dvec = decrypt(secret_key, cipher_res)

    print_statistics(mpow, dvec)

end


function test_inverse()

    n = 2^6
    log_precision = 30
    log_cap = 300
    steps = 6

    rng = MyRNG(12345)
    params = Params(log_polynomial_length=8, log_lo_modulus=300)

    secret_key = SecretKey(rng, params)

    enc_key = EncryptionKey(rng, secret_key)
    mul_key = MultiplicationKey(rng, secret_key)

    # TODO: if one uses 1.0 instead of 0.1, the error becomes huge. Why?
    mvec = [randomCircle(rng, 0.1) for i in 1:n] # randn(rng, n) + im * randn(rng, n)
    minv = 1 ./ mvec

    cipher = encrypt(rng, enc_key, mvec, log_precision, log_cap)

    cipher_res = inv(mul_key, cipher, log_precision, steps)

    dvec = decrypt(secret_key, cipher_res)

    print_statistics(minv, dvec)

end


function test_log()

    n = 2^6
    log_precision = 30
    log_cap = 300
    degree = 7

    rng = MyRNG(12345)
    params = Params(log_polynomial_length=8, log_lo_modulus=300)

    secret_key = SecretKey(rng, params)

    enc_key = EncryptionKey(rng, secret_key)
    mul_key = MultiplicationKey(rng, secret_key)

    mvec = [randomComplex(rng, 0.1) for i in 1:n] # randn(rng, n) + im * randn(rng, n)
    mlog = log.(mvec .+ 1)

    cipher = encrypt(rng, enc_key, mvec, log_precision, log_cap)

    cipher_res = log_plus_one(mul_key, cipher, log_precision, degree)

    dvec = decrypt(secret_key, cipher_res)

    print_statistics(mlog, dvec)

end


function test_exp()

    n = 2^6
    log_precision = 30
    log_cap = 300
    degree = 7

    rng = MyRNG(12345)
    params = Params(log_polynomial_length=8, log_lo_modulus=300)

    secret_key = SecretKey(rng, params)

    enc_key = EncryptionKey(rng, secret_key)
    mul_key = MultiplicationKey(rng, secret_key)

    mvec = [randomComplex(rng) for i in 1:n] # randn(rng, n) + im * randn(rng, n)
    mexp = exp.(mvec)

    cipher = encrypt(rng, enc_key, mvec, log_precision, log_cap)

    cipher_res = exp(mul_key, cipher, log_precision, degree)

    dvec = decrypt(secret_key, cipher_res)

    print_statistics(mexp, dvec)

end


function test_sigmoid()

    n = 2^6
    log_precision = 30
    log_cap = 300
    degree = 7

    rng = MyRNG(12345)
    params = Params(log_polynomial_length=8, log_lo_modulus=300)

    secret_key = SecretKey(rng, params)

    enc_key = EncryptionKey(rng, secret_key)
    mul_key = MultiplicationKey(rng, secret_key)

    mvec = [randomComplex(rng) for i in 1:n] # randn(rng, n) + im * randn(rng, n)
    msig = exp.(mvec) ./ (1 .+ exp.(mvec))

    cipher = encrypt(rng, enc_key, mvec, log_precision, log_cap)

    cipher_res = sigmoid(mul_key, cipher, log_precision, degree)

    dvec = decrypt(secret_key, cipher_res)

    print_statistics(msig, dvec)
end


function test_sigmoid_lazy()

    n = 2^6
    log_precision = 30
    log_cap = 300
    degree = 7

    rng = MyRNG(12345)
    params = Params(log_polynomial_length=8, log_lo_modulus=300)

    secret_key = SecretKey(rng, params)

    enc_key = EncryptionKey(rng, secret_key)
    mul_key = MultiplicationKey(rng, secret_key)

    mvec = [randomComplex(rng) for i in 1:n] # randn(rng, n) + im * randn(rng, n)
    msig = exp.(mvec) ./ (1 .+ exp.(mvec))

    cipher = encrypt(rng, enc_key, mvec, log_precision, log_cap)

    cipher_res = sigmoid(mul_key, cipher, log_precision, degree, lazy=true)

    dvec = decrypt(secret_key, cipher_res)

    print_statistics(msig, dvec)
end


function test_bootstrap()

    rng = MyRNG(12345)

    log_t = 4 # means that we use Taylor approximation in [-1/t,1/t] with double angle fomula
    log_n = 3
    n = 2^log_n
    log_precision = 20
    log_cap = 30

    params = Params(log_polynomial_length=8, log_lo_modulus=600)
    log_plen = params.log_polynomial_length

    secret_key = SecretKey(rng, params)
    enc_key = EncryptionKey(rng, secret_key)
    mul_key = MultiplicationKey(rng, secret_key)
    conj_key = ConjugationKey(rng, secret_key)

    bk = BootstrapKey(rng, secret_key, enc_key, mul_key, conj_key, log_n)
    bc = HEAAN.BootContext(params, log_n, log_cap + 4) # TODO: why + 4?

    mvec = randomComplexArray(rng, n)

    cipher = encrypt(rng, bk.enc_key, mvec, log_precision, log_cap)

    println("cipher log_cap before: ", cipher.log_cap)

    cipher = HEAAN.mod_down_to(cipher, log_cap) # TODO: is it really necessary? it's already log_cap

    # TODO: check that polynomial caps correspond to the given log_cap
    cipher = HEAAN.Ciphertext(
        params,
        HEAAN.mod_up_to(cipher.ax, params.log_lo_modulus),
        HEAAN.mod_up_to(cipher.bx, params.log_lo_modulus),
        params.log_lo_modulus,
        log_cap + 4,
        n)

    println("SubSum")
    for i in log_n:params.log_polynomial_length-2
        rot = circshift(bk.rot_keys[1 << i], cipher, -(1 << i))
        cipher = add(cipher, rot)
    end

    cipher = HEAAN.div_by_po2(cipher, log_plen - 1)

    println("CoeffToSlot")
    cipher = HEAAN.coeff_to_slot(bk, bc, cipher)

    println("EvalExp")
    cipher = HEAAN.eval_exp(bk, bc, cipher, log_t)

    println("SlotToCoeff")
    cipher = HEAAN.slot_to_coeff(bk, bc, cipher)

    cipher = HEAAN.Ciphertext(
        params,
        cipher.ax,
        cipher.bx,
        cipher.log_cap,
        log_precision,
        cipher.slots
        )

    println("cipher log_cap after: ", cipher.log_cap)

    dvec = decrypt(secret_key, cipher)

    print_statistics(mvec, dvec)
end


test_encrypt()
test_add()
test_add_const()
test_mul()
test_mul_const_complex()
test_mul_const_vec()
test_imul()
test_circshift()
test_conj()
test_power_of_2()
test_power()
test_inverse()
test_log()
test_exp()
test_sigmoid()
test_sigmoid_lazy()
test_bootstrap()
