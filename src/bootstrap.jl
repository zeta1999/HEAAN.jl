struct BootContext

    rpvec :: Array{RNSPolynomialTransformed, 1}
    rpvecInv :: Array{RNSPolynomialTransformed, 1}
    rp1 :: RNSPolynomialTransformed
    rp2 :: RNSPolynomialTransformed

    log_precision :: Int
    log_slots :: Int

    function BootContext(params::Params, log_slots::Int, log_precision::Int)

        e_plan = embedding_plan(params)
        r_plan = rns_plan(params)

        slots = 1 << log_slots
        dslots = slots << 1
        logk = log_slots >> 1

        k = 1 << logk
        gap = 2^(params.log_polynomial_length - 1) >> log_slots

        log_plen = params.log_polynomial_length
        plen = 2^log_plen

        rpvec = Array{RNSPolynomialTransformed}(undef, slots)
        rpvecInv = Array{RNSPolynomialTransformed}(undef, slots)

        # TODO: is log_precision + 1 enough?
        tp = BinModuloInt{BigInt, log_precision + 1}
        pvec = Array{tp}(undef, plen)
        pvec .= zero(tp)
        pvals = Array{Complex{Float64}}(undef, dslots)

        c = 0.25 / pi

        if log_slots < log_plen - 1
            dgap = gap >> 1
            for ki in 0:k:slots-1
                for pos in ki:ki+k-1
                    for i in 0:slots-pos-1
                        deg = ((2 * plen - e_plan.rotation_group[i + pos + 1]) * i * gap) % (2 * plen)
                        pvals[i+1] = e_plan.root_powers[deg + 1]
                        pvals[i + slots + 1] = pvals[i+1] * im
                    end
                    for i in slots-pos:slots-1
                        deg = ((2 * plen - e_plan.rotation_group[i + pos - slots + 1]) * i * gap) % (2 * plen)
                        pvals[i + 1] = e_plan.root_powers[deg + 1]
                        pvals[i + slots + 1] = pvals[i + 1] * im
                    end
                    pvals = circshift(pvals, ki)
                    pvals = unembed(e_plan, pvals)
                    for i in 0:dslots-1
                        jdx = plen ÷ 2 + i * dgap
                        idx = i * dgap
                        pvec[idx + 1] = float_to_integer(tp, real(pvals[i + 1]), log_precision)
                        pvec[jdx + 1] = float_to_integer(tp, imag(pvals[i + 1]), log_precision)
                    end
                    rpvec[pos + 1] = to_rns_transformed(
                        r_plan, Polynomial(pvec, true), params.log_lo_modulus + 2 * log_plen)
                    for i in 0:plen-1
                        pvec[i + 1] = zero(tp)
                    end
                end
            end

            for i in 0:slots-1
                pvals[i + 1] = 0.0
                pvals[i + slots + 1] = -c * im
            end
            pvals = unembed(e_plan, pvals)
            for i in 0:dslots-1
                idx = i * dgap
                jdx = plen ÷ 2 + i * dgap
                pvec[idx + 1] = float_to_integer(tp, real(pvals[i+1]), log_precision)
                pvec[jdx + 1] = float_to_integer(tp, imag(pvals[i+1]), log_precision)
            end
            rp1 = to_rns_transformed(
                r_plan, Polynomial(pvec, true), params.log_lo_modulus + 2 * log_plen)
            for i in 0:plen-1
                pvec[i+1] = zero(tp)
            end

            for i in 0:slots-1
                pvals[i + 1] = c
                pvals[i + slots + 1] = 0
            end

            pvals = unembed(e_plan, pvals)
            for i in 0:dslots-1
                idx = i * dgap
                jdx = plen ÷ 2 + i * dgap
                pvec[idx+1] = float_to_integer(tp, real(pvals[i+1]), log_precision)
                pvec[jdx+1] = float_to_integer(tp, imag(pvals[i+1]), log_precision)
            end
            rp2 = to_rns_transformed(
                r_plan, Polynomial(pvec, true), params.log_lo_modulus + 2 * log_plen)
            for i in 0:plen-1
                pvec[i+1] = zero(tp)
            end
        else
            # TODO: need to test this branch
            for ki in 0:k:slots-1
                for pos in ki:ki+k-1
                    for i in 0:slots-pos-1
                        deg = ((plen * 2 - e_plan.rotation_group[i + pos + 1]) * i * gap) % (plen * 2)
                        pvals[i+1] = e_plan.root_powers[deg+1]
                    end
                    for i in slots-pos:slots-1
                        deg = ((plen * 2 - e_plan.rotation_group[i + pos - slots + 1]) * i * gap) % (plen * 2)
                        pvals[i+1] = e_plan.root_powers[deg]
                    end
                    # TODO: check that this is equivalent to rightRotateAndEqual(pvals, slots, ki)
                    # TODO: in the original it was `slots`, but length of `pvals` is `dslots` - bug?
                    pvals = vcat(circshift(pvals[1:slots], ki), pvals[slots+1:end])
                    pvals = vcat(unembed(e_plan, pvals[1:slots]), pvals[slots+1:end])
                    for i in 0:slots-1
                        idx = i * gap
                        jdx = plen ÷ 2 + i * gap
                        pvec[idx+1] = float_to_integer(tp, real(pvals[i+1]), log_precision)
                        pvec[jdx+1] = float_to_integer(tp, imag(pvals[i+1]), log_precision)
                    end
                    rpvec[pos+1] = to_rns_transformed(
                        r_plan, Polynomial(pvec, true), params.log_lo_modulus + 2 * log_plen)
                    for i in 0:plen-1
                        pvec[i+1] = zero(tp)
                    end
                end
            end

            # These will be unused
            rp1 = RNSPolynomialTransformed(r_plan, Array{UInt64}(undef, plen, 1))
            rp2 = RNSPolynomialTransformed(r_plan, Array{UInt64}(undef, plen, 1))
        end

        for ki in 0:k:slots-1
            for pos in ki:ki+k-1
                for i in 0:slots-pos-1
                    deg = (e_plan.rotation_group[i+1] * (i + pos) * gap) % (plen * 2)
                    pvals[i+1] = e_plan.root_powers[deg+1]
                end
                for i in slots-pos:slots-1
                    deg = (e_plan.rotation_group[i+1] * (i + pos - slots) * gap) % (plen * 2)
                    pvals[i+1] = e_plan.root_powers[deg+1]
                end
                # TODO: check that this is equivalent to rightRotateAndEqual(pvals, slots, ki)
                # TODO: in the original it was `slots`, but length of `pvals` is `dslots` - bug?
                pvals = vcat(circshift(pvals[1:slots], ki), pvals[slots+1:end])
                pvals = vcat(unembed(e_plan, pvals[1:slots]), pvals[slots+1:end])
                for i in 0:slots-1
                    idx = i * gap
                    jdx = plen ÷ 2 + i * gap
                    pvec[idx+1] = float_to_integer(tp, real(pvals[i+1]), log_precision)
                    pvec[jdx+1] = float_to_integer(tp, imag(pvals[i+1]), log_precision)
                end
                rpvecInv[pos+1] = to_rns_transformed(
                    r_plan, Polynomial(pvec, true), params.log_lo_modulus + 2 * log_plen)
                for i in 0:plen-1
                    pvec[i+1] = zero(tp)
                end
            end
        end

        new(rpvec, rpvecInv, rp1, rp2, log_precision, log_slots)
    end

end


struct BootstrapKey

    enc_key :: EncryptionKey
    mul_key :: MultiplicationKey
    conj_key :: ConjugationKey
    rot_keys :: Dict{Int, LeftRotationKey}
    log_slots :: Int
    bc :: BootContext

    function BootstrapKey(
            rng::AbstractRNG, secret_key::SecretKey,
            enc_key::EncryptionKey, mul_key::MultiplicationKey, conj_key::ConjugationKey,
            log_slots::Int, log_precision::Int)

        params = secret_key.params
        log_plen = params.log_polynomial_length

        # TODO: build a set of required shifts first, and then create the keys

        rot_keys = Dict{Int, LeftRotationKey}()

        for i in 0:log_plen-2
            idx = 1 << i
            if !haskey(rot_keys, idx)
                rot_keys[idx] = LeftRotationKey(rng, secret_key, idx)
            end
        end

        loglh = log_slots ÷ 2
        k = 1 << loglh
        m = 1 << (log_slots - loglh)

        for i in 1:k-1
            if !haskey(rot_keys, i)
                rot_keys[i] = LeftRotationKey(rng, secret_key, i)
            end
        end

        for i in 1:m-1
            idx = i * k
            if !haskey(rot_keys, idx)
                rot_keys[idx] = LeftRotationKey(rng, secret_key, idx)
            end
        end

        bc = BootContext(params, log_slots, log_precision)

        new(enc_key, mul_key, conj_key, rot_keys, log_slots, bc)
    end
end


function mul_by_rns(cipher::Ciphertext, p::RNSPolynomialTransformed, log_precision::Int)
    Ciphertext(
        cipher.params,
        mult(cipher.ax, p),
        mult(cipher.bx, p),
        cipher.log_cap,
        cipher.log_precision + log_precision,
        cipher.slots)
end


function coeff_to_slot(bk::BootstrapKey, bc::BootContext, cipher::Ciphertext)

    @assert 2^bc.log_slots == cipher.slots

    slots = cipher.slots
    log_slots = trailing_zeros(slots) # TODO: assuming slots is a power of 2
    logk = log_slots ÷ 2
    k = 1 << logk

    rotvec = Array{Ciphertext}(undef, k)
    rotvec[0+1] = cipher

    for j in 0:k-2
        rotvec[j+1+1] = circshift(bk.rot_keys[j+1], rotvec[0+1], -(j + 1))
    end

    tmpvec = Array{Ciphertext}(undef, k)

    for j in 0:k-1
        tmpvec[j+1] = mul_by_rns(rotvec[j+1], bc.rpvec[j+1], bc.log_precision)
    end

    for j in 1:k-1
        tmpvec[0+1] = add(tmpvec[0+1], tmpvec[j+1])
    end

    cipher = tmpvec[0+1]

    for ki in k:k:slots-1
        for j in 0:k-1
            tmpvec[j+1] = mul_by_rns(
                rotvec[j+1], bc.rpvec[j+ki+1], bc.log_precision)
        end
        for j in 1:k-1
            tmpvec[0+1] = add(tmpvec[0+1], tmpvec[j+1])
        end
        tmpvec[0+1] = circshift(bk.rot_keys[ki], tmpvec[0+1], -ki)
        cipher = add(cipher, tmpvec[0+1])
    end
    rescale_by(cipher, bc.log_precision)
end


function slot_to_coeff(bk::BootstrapKey, bc::BootContext, cipher::Ciphertext)

    @assert 2^bc.log_slots == cipher.slots

    slots = cipher.slots
    log_slots = trailing_zeros(slots) # TODO: assuming slots is a power of 2
    logk = log_slots ÷ 2
    k = 1 << logk

    rotvec = Array{Ciphertext}(undef, k)
    rotvec[0+1] = cipher

    for j in 0:k-1-1
        rotvec[j+1+1] = circshift(bk.rot_keys[j+1], rotvec[0+1], -(j + 1))
    end

    tmpvec = Array{Ciphertext}(undef, k)

    for j in 0:k-1
        tmpvec[j+1] = mul_by_rns(
            rotvec[j+1], bc.rpvecInv[j+1], bc.log_precision)
    end

    for j in 1:k-1
        tmpvec[0+1] = add(tmpvec[0+1], tmpvec[j+1])
    end
    cipher = tmpvec[0+1]

    for ki in k:k:slots-1
        for j in 0:k-1
            tmpvec[j+1] = mul_by_rns(
                rotvec[j+1], bc.rpvecInv[j+ki+1], bc.log_precision)
        end

        for j in 1:k-1
            tmpvec[0+1] = add(tmpvec[0+1], tmpvec[j+1])
        end

        tmpvec[0+1] = circshift(bk.rot_keys[ki], tmpvec[0+1], -ki)
        cipher = add(cipher, tmpvec[0+1])
    end
    rescale_by(cipher, bc.log_precision)
end


function exp2pi(mk::MultiplicationKey, cipher::Ciphertext, log_precision::Int)
    Pi = Float64(pi)

    # Cipher: log_precision, log_cap = (p, q); log_precision = l

    cipher2 = square(mk, cipher) # (2p, q)
    cipher2 = rescale_by(cipher2, log_precision) # (2p - l, q - l)

    cipher4 = square(mk, cipher2) # (4p - 2l, q - l)
    cipher4 = rescale_by(cipher4, log_precision) # (4p - 3l, q - 2l)
    c = 1/(2 * Pi)
    cipher01 = add_const(cipher, c) # (p, q)

    c = 2*Pi
    cipher01 = mul_by_const(cipher01, c, log_precision) # (p + l, q)
    cipher01 = rescale_by(cipher01, log_precision) # (p, q - l)

    c = 3/(2*Pi)
    cipher23 = add_const(cipher, c) # (p, q)

    c = 4*Pi*Pi*Pi/3
    cipher23 = mul_by_const(cipher23, c, log_precision) # (p + l, q)
    cipher23 = rescale_by(cipher23, log_precision) # (p, q - l)

    cipher23 = mul(mk, cipher23, cipher2) # (p, q - l) * (2p - l, q - l) = (3p - l, q - l)
    cipher23 = rescale_by(cipher23, log_precision) # (3p - 2l, q - 2l)

    # TODO (see issue #1): how justified is mod_down_to() here? In the original these two
    # ciphertexts are just added without regard to different log_caps, and the log_cap of
    # cipher23 is used for the result (which is smaller than that of cipher01).
    # So we have an inconsistent Ciphertext in the output, but somehow it works out...
    # (3p - 2l, q - 2l) + (p, q)
    cipher23 = add(cipher23, mod_down_to(cipher01, cipher23.log_cap))

    c = 5/(2*Pi)
    cipher45 = add_const(cipher, c) # (p, q)

    c = 4*Pi*Pi*Pi*Pi*Pi/15
    cipher45 = mul_by_const(cipher45, c, log_precision)
    cipher45 = rescale_by(cipher45, log_precision) # cipher45.log_cap : log_cap - log_precision

    c = 7/(2*Pi)
    cipher = add_const(cipher, c) # cipher.log_cap : log_cap

    c = 8*Pi*Pi*Pi*Pi*Pi*Pi*Pi/315
    cipher = mul_by_const(cipher, c, log_precision)
    cipher = rescale_by(cipher, log_precision) # cipher.log_cap : log_cap - log_precision

    cipher = mul(mk, cipher, cipher2)
    cipher = rescale_by(cipher, log_precision) # cipher.log_cap : log_cap - 2log_precision

    cipher45 = mod_down_by(cipher45, log_precision) # cipher45.log_cap : log_cap - 2log_precision
    cipher = add(cipher, cipher45) # cipher.log_cap : log_cap - 2log_precision

    cipher = mul(mk, cipher, cipher4)
    cipher = rescale_by(cipher, log_precision) # cipher.log_cap : log_cap - 3log_precision

    cipher23 = mod_down_by(cipher23, log_precision)
    cipher = add(cipher, cipher23) # cipher.log_cap : log_cap - 3log_precision

    cipher
end


function eval_exp(bk::BootstrapKey, bc::BootContext, cipher::Ciphertext, log_t::Int, log_i::Int=4)
    slots = cipher.slots
    log_slots = trailing_zeros(slots) # TODO: assuming slots is a power of 2
    @assert bc.log_slots == log_slots

    mk = bk.mul_key
    ck = bk.conj_key

    log_plen = cipher.params.log_polynomial_length

    if log_slots < log_plen - 1
        tmp = conj(ck, cipher)
        cipher = sub(cipher, tmp)
        cipher = div_by_po2(cipher, log_t + 1) # bitDown: log_t + 1
        cipher = exp2pi(mk, cipher, bc.log_precision) # bitDown: log_t + 1 + 3(log_cap + log_i)
        for i in 0:log_i+log_t-1
            cipher = square(mk, cipher)
            cipher = rescale_by(cipher, bc.log_precision)
        end
        tmp = conj(ck, cipher)
        cipher = sub(cipher, tmp)
        tmp = mul_by_rns(cipher, bc.rp1, bc.log_precision)
        tmprot = circshift(bk.rot_keys[slots], tmp, -slots)
        tmp = add(tmp, tmprot)
        cipher = mul_by_rns(cipher, bc.rp2, bc.log_precision)
        tmprot = circshift(bk.rot_keys[slots], cipher, -slots)
        cipher = add(cipher, tmprot)
        cipher = add(cipher, tmp)
    else # TODO (see issue #1): check this branch
        tmp = conj(ck, cipher)
        c2 = sub(cipher, tmp)
        cipher = add(cipher, tmp)
        cipher = imul(cipher)
        cipher = div_by_po2(cipher, log_t + 1) # cipher bitDown: log_t + 1
        c2 = rescale_by(c2, log_t + 1) # c2 bitDown: log_t + 1
        cipher = exp2pi(mk, cipher, bc.log_precision) # cipher bitDown: log_t + 1 + 3(log_cap + log_i)
        c2 = exp2pi(mk, c2, bc.log_precision) # c2 bitDown: log_t + 1 + 3(log_cap + log_i)
        for i in 0:log_i+log_t-1
            c2 = square(mk, c2)
            cipher = square(mk, cipher)
            c2 = rescale_by(c2, bc.log_precision)
            cipher = rescale_by(cipher, bc.log_precision)
        end
        tmp = conj(ck, c2)
        c2 = sub(c2, tmp)
        tmp = conj(ck, cipher)
        cipher = sub(cipher, tmp)
        cipher = imul(cipher)
        cipher = sub(c2, cipher)
        c = 0.25/pi
        cipher = mul_by_const(cipher, c, bc.log_precision)
    end
    rescale_by(cipher, bc.log_precision + log_i)
end


#=
The theory behind this is explained in
"Improved Bootstrapping for Approximate Homomorphic Encryption", Cheon et al (2018),
Section 2.2.
=#
function bootstrap(bk::BootstrapKey, cipher::Ciphertext, log_t::Int=4)

    @assert 2^bk.log_slots == cipher.slots
    params = cipher.params

    log_plen = params.log_polynomial_length
    orig_log_precision = cipher.log_precision

    # TODO: check that bk.bc.log_precision >= cipher.log_precision?
    cipher = Ciphertext(
        params,
        mod_up_to(cipher.ax, params.log_lo_modulus),
        mod_up_to(cipher.bx, params.log_lo_modulus),
        params.log_lo_modulus,
        bk.bc.log_precision,
        cipher.slots)

    for i in bk.log_slots:log_plen-2
        rot = circshift(bk.rot_keys[1 << i], cipher, -(1 << i))
        cipher = add(cipher, rot)
    end

    cipher = div_by_po2(cipher, log_plen - 1)
    cipher = coeff_to_slot(bk, bk.bc, cipher)
    cipher = eval_exp(bk, bk.bc, cipher, log_t)
    cipher = slot_to_coeff(bk, bk.bc, cipher)

    Ciphertext(
        params,
        cipher.ax,
        cipher.bx,
        cipher.log_cap,
        orig_log_precision,
        cipher.slots)
end
