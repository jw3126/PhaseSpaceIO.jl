export download_phase_space

function build_co60_url(name)
    url_co60_base = "https://www-nds.iaea.org/phsp/Co60"
    url_stem = url_co60_base * "/" * name
    url_stem * EXT_HEADER, url_stem * EXT_PHSP
end

const keys_co60 = ["ELDORADO_Co60_10x10_at80p5", "ELDORADO_Co60_5x5_at80p5"]
const IAEA_URL_DICT = Dict(key => build_co60_url(key) for key in keys_co60)

function download_phase_space(key; header_path=key * EXT_HEADER, phsp_path= key*EXT_PHSP)
    @argcheck !ispath(header_path)
    @argcheck !ispath(phsp_path)
    header_url, phsp_url = IAEA_URL_DICT[key]
    ret_header = download(header_url, header_path)
    ret_phsp = download(phsp_url, phsp_path)
    ret_header, ret_phsp
end

